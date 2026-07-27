import 'package:flutter/material.dart';
import 'package:icu_app/backend/models/medication.dart';
import 'package:provider/provider.dart';
import 'package:icu_app/backend/state/app_state.dart';
import 'package:icu_app/backend/models/patient.dart';

class DoseCalculatorScreen extends StatefulWidget {
  const DoseCalculatorScreen({super.key});

  @override
  State<DoseCalculatorScreen> createState() => _DoseCalculatorScreenState();
}

class _DoseCalculatorScreenState extends State<DoseCalculatorScreen> {
  final _weightController = TextEditingController();
  final _manualDoseController = TextEditingController();
  Medication? _selectedMedication;
  Patient? _selectedPatient;
  double? _calculatedDose;
  String _safetyStatus = "";
  Color _safetyColor = Colors.grey;

  void _calculate() {
    double weight = double.tryParse(_weightController.text) ?? 0;
    double? manualDose = double.tryParse(_manualDoseController.text);
    final appState = Provider.of<AppState>(context, listen: false);

    if (weight > 0 && _selectedMedication != null) {
      setState(() {
        _calculatedDose = manualDose ?? (weight * _selectedMedication!.standardDosePerKg);
        
        // Safety Checking Logic
        double dosePerKg = _calculatedDose! / weight;
        if (dosePerKg < _selectedMedication!.minDosePerKg) {
          _safetyStatus = "SUB-THERAPEUTIC (SAFE BUT LOW)";
          _safetyColor = Colors.orange;
        } else if (dosePerKg > _selectedMedication!.maxDosePerKg) {
          _safetyStatus = "CRITICAL: DANGER (DOSE TOO HIGH)";
          _safetyColor = Colors.red;
        } else {
          _safetyStatus = "CLINICALLY SAFE RANGE";
          _safetyColor = Colors.green;
        }

        // Interaction Check with Active Meds
        if (_selectedPatient != null) {
          final activeMeds = appState.prescriptions
              .where((p) => p['patientId'] == _selectedPatient!.id && p['status'] == 'Active')
              .map((p) => p['medId'])
              .toList();
          
          _activeInteractions.clear();
          for (var medId in activeMeds) {
            if (_selectedMedication!.interactions.contains(medId)) {
              final otherMedName = appState.medications.firstWhere((m) => m.id == medId, orElse: () => Medication(id: 'unknown', name: 'Unknown', category: '', standardDosePerKg: 0, minDosePerKg: 0, maxDosePerKg: 0, unit: '')).name;
              _activeInteractions.add("⚠️ Interaction found with $otherMedName (currently active)");
            }
          }
        }
      });
    } else {
      setState(() {
        _calculatedDose = null;
        _safetyStatus = "";
        _activeInteractions.clear();
      });
    }
  }

  final List<String> _activeInteractions = [];

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final patients = appState.patients;
    final medications = appState.medications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinical Dose Audit'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Precision Dosing & Safety Check',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
            ),
            const SizedBox(height: 8),
            const Text('Verify dosages against safety standards before administration.', style: TextStyle(color: Colors.grey)),
            if (_activeInteractions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red[200]!)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _activeInteractions.map((i) => Text(i, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13))).toList(),
                ),
              ),
            ],
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<Patient>(
                      value: _selectedPatient,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Target Patient',
                        prefixIcon: Icon(Icons.person_search),
                      ),
                      items: patients.map((p) {
                        return DropdownMenuItem(
                          value: p, 
                          child: Text(
                            '${p.name} (${p.bedNumber})',
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                          )
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedPatient = val;
                          if (val != null) {
                            _weightController.text = val.weight.toString();
                          }
                          _calculate();
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Patient Weight (kg)',
                        prefixIcon: Icon(Icons.monitor_weight_outlined),
                      ),
                      onChanged: (_) {
                        setState(() => _selectedPatient = null);
                        _calculate();
                      },
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<Medication>(
                      value: _selectedMedication,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Select Medication',
                        prefixIcon: Icon(Icons.medication_outlined),
                      ),
                      items: medications.map((med) {
                        return DropdownMenuItem(
                          value: med, 
                          child: Text(
                            med.name,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                          )
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedMedication = val;
                          _calculate();
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _manualDoseController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Adjust Dose Manually (Optional)',
                        hintText: _selectedMedication != null ? 'Unit: ${_selectedMedication!.unit}' : '',
                        prefixIcon: const Icon(Icons.edit_note),
                      ),
                      onChanged: (_) => _calculate(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (_calculatedDose != null)
              _buildResultCard(),
          ],
        ),
      ),
    );
  }

  bool _checklist1 = false;
  bool _checklist2 = false;
  bool _checklist3 = false;

  void _showSafetyChecklist() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.fact_check, color: Colors.blue),
              SizedBox(width: 12),
              Text('Final Safety Check'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                title: const Text('Patient ID and Weight verified?'),
                value: _checklist1,
                onChanged: (v) => setState(() => _checklist1 = v!),
              ),
              CheckboxListTile(
                title: const Text('Drug name and concentration confirmed?'),
                value: _checklist2,
                onChanged: (v) => setState(() => _checklist2 = v!),
              ),
              CheckboxListTile(
                title: const Text('Dual sign-off obtained (if required)?'),
                value: _checklist3,
                onChanged: (v) => setState(() => _checklist3 = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: (_checklist1 && _checklist2 && _checklist3) ? () {
                Navigator.pop(context);
                _savePrescription();
              } : null,
              child: const Text('AUTHORIZE ADMINISTRATION'),
            ),
          ],
        ),
      ),
    );
  }

  void _savePrescription() {
    final prescription = {
      'date': DateTime.now().toIso8601String(),
      'patient': _selectedPatient!.name,
      'med': _selectedMedication!.name,
      'medId': _selectedMedication!.id,
      'patientId': _selectedPatient!.id,
      'dose': '${_calculatedDose!.toStringAsFixed(2)} ${_selectedMedication!.unit}',
      'status': _safetyColor == Colors.red ? 'DANGER' : 'Active',
    };
    Provider.of<AppState>(context, listen: false).addPrescription(prescription);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dose audit saved and authorized')),
    );
    // Reset checklists
    _checklist1 = _checklist2 = _checklist3 = false;
  }

  Widget _buildResultCard() {
    String titrationGuidance = "";
    if (_selectedMedication!.name == 'Norepinephrine' && _selectedPatient != null && _selectedPatient!.map != null) {
      if (_selectedPatient!.map! < 65) {
        titrationGuidance = "⚠️ MAP is low (${_selectedPatient!.map!.toStringAsFixed(1)}). Consider increasing dose to maintain MAP > 65.";
      } else {
        titrationGuidance = "✅ MAP is stable (${_selectedPatient!.map!.toStringAsFixed(1)}). Maintain current titration.";
      }
    }

    return Column(
      children: [
        // SAFETY STATUS HEADER
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _safetyColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Text(
            _safetyStatus,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
          ),
          child: Column(
            children: [
              const Text('CALCULATED TOTAL DOSE', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                '${_calculatedDose!.toStringAsFixed(2)} ${_selectedMedication!.unit}',
                style: TextStyle(fontSize: 44, fontWeight: FontWeight.bold, color: _safetyColor),
              ),
              const SizedBox(height: 8),
              Text(
                '(${(_calculatedDose! / double.parse(_weightController.text)).toStringAsFixed(3)} ${_selectedMedication!.unit}/kg)',
                style: const TextStyle(color: Colors.blueGrey, fontSize: 14),
              ),
              if (titrationGuidance.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(titrationGuidance, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
              ],
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              _safetyIndicator('Min Safe:', '${_selectedMedication!.minDosePerKg} ${_selectedMedication!.unit}/kg'),
              _safetyIndicator('Max Safe:', '${_selectedMedication!.maxDosePerKg} ${_selectedMedication!.unit}/kg'),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_selectedMedication!.warning, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (_selectedPatient != null)
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.verified_user),
              label: const Text('PERFORM SAFETY CHECK'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), foregroundColor: Colors.white),
              onPressed: _showSafetyChecklist,
            ),
          ),
      ],
    );
  }

  Widget _safetyIndicator(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value, 
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
