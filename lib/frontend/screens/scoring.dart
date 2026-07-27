import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:icu_app/backend/state/app_state.dart';
import 'package:icu_app/backend/models/patient.dart';

class ScoringScreen extends StatefulWidget {
  final Patient? initialPatient;
  const ScoringScreen({super.key, this.initialPatient});

  @override
  State<ScoringScreen> createState() => _ScoringScreenState();
}

class _ScoringScreenState extends State<ScoringScreen> {
  Patient? _selectedPatient;
  
  int _respScore = 0;
  int _cardioScore = 0;
  int _liverScore = 0;
  int _coagScore = 0;
  int _renalScore = 0;
  int _cnsScore = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialPatient != null) {
      _selectedPatient = widget.initialPatient;
      _autoCalculateSOFA();
    }
  }

  void _autoCalculateSOFA() {
    if (_selectedPatient == null) return;
    
    // Respiratory (PaO2/FiO2)
    if (_selectedPatient!.paO2 != null && _selectedPatient!.fiO2 != null && _selectedPatient!.fiO2! > 0) {
      double pfRatio = _selectedPatient!.paO2! / _selectedPatient!.fiO2!;
      if (pfRatio < 100) _respScore = 4;
      else if (pfRatio < 200) _respScore = 3;
      else if (pfRatio < 300) _respScore = 2;
      else if (pfRatio < 400) {
        _respScore = 1;
      }
      else {
        _respScore = 0;
      }
    }

    // Coagulation (Platelets)
    if (_selectedPatient!.platelets != null) {
      double p = _selectedPatient!.platelets!;
      if (p < 20) _coagScore = 4;
      else if (p < 50) _coagScore = 3;
      else if (p < 100) _coagScore = 2;
      else if (p < 150) _coagScore = 1;
      else _coagScore = 0;
    }

    // Liver (Bilirubin)
    if (_selectedPatient!.bilirubin != null) {
      double b = _selectedPatient!.bilirubin!;
      if (b > 12.0) _liverScore = 4;
      else if (b >= 6.0) _liverScore = 3;
      else if (b >= 2.0) _liverScore = 2;
      else if (b >= 1.2) _liverScore = 1;
      else _liverScore = 0;
    }

    // Cardio (MAP)
    if (_selectedPatient!.map != null) {
      if (_selectedPatient!.map! < 70) _cardioScore = 1;
      else _cardioScore = 0;
    }

    // CNS (GCS)
    if (_selectedPatient!.gcs != null) {
      double g = _selectedPatient!.gcs!;
      if (g < 6) _cnsScore = 4;
      else if (g <= 9) _cnsScore = 3;
      else if (g <= 12) _cnsScore = 2;
      else if (g <= 14) _cnsScore = 1;
      else _cnsScore = 0;
    }

    // Renal (Creatinine)
    if (_selectedPatient!.creatinine != null) {
      double c = _selectedPatient!.creatinine!;
      if (c > 5.0) _renalScore = 4;
      else if (c >= 3.5) _renalScore = 3;
      else if (c >= 2.0) _renalScore = 2;
      else if (c >= 1.2) _renalScore = 1;
      else _renalScore = 0;
    }
  }

  int get _totalScore => _respScore + _cardioScore + _liverScore + _coagScore + _renalScore + _cnsScore;

  @override
  Widget build(BuildContext context) {
    final patients = Provider.of<AppState>(context).patients;

    return Scaffold(
      appBar: AppBar(title: const Text('SOFA Scoring System')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sequential Organ Failure Assessment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Automated SOFA calculation based on patient clinical data.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            
            DropdownButtonFormField<Patient>(
              initialValue: _selectedPatient,
              decoration: const InputDecoration(labelText: 'Load Patient Data'),
              items: patients.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
              onChanged: (v) {
                setState(() {
                  _selectedPatient = v;
                  _autoCalculateSOFA();
                });
              },
            ),

            const SizedBox(height: 32),
            _buildScoreSection('Respiratory (PaO2/FiO2)', _respScore, (val) => setState(() => _respScore = val)),
            _buildScoreSection('Cardiovascular (MAP/Vasopressors)', _cardioScore, (val) => setState(() => _cardioScore = val)),
            _buildScoreSection('Liver (Bilirubin)', _liverScore, (val) => setState(() => _liverScore = val)),
            _buildScoreSection('Coagulation (Platelets)', _coagScore, (val) => setState(() => _coagScore = val)),
            _buildScoreSection('Renal (Creatinine/Output)', _renalScore, (val) => setState(() => _renalScore = val)),
            _buildScoreSection('CNS (GCS Score)', _cnsScore, (val) => setState(() => _cnsScore = val)),
            const SizedBox(height: 40),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _getScoreColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _getScoreColor()),
              ),
              child: Column(
                children: [
                  const Text('TOTAL SOFA SCORE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  Text('$_totalScore', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: _getScoreColor())),
                  const SizedBox(height: 12),
                  Text(_getRiskAssessment(), style: TextStyle(color: _getScoreColor(), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_selectedPatient != null)
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('SAVE SCORE TO PATIENT HISTORY'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      final historyEntry = "SOFA Score: $_totalScore at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} (Risk: ${_getRiskAssessment()})";
                      Provider.of<AppState>(context, listen: false).updatePatientHistory(_selectedPatient!.id, historyEntry);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Score saved to history')));
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreSection(String title, int currentVal, Function(int) onSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (index) {
              bool isSelected = currentVal == index;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: InkWell(
                    onTap: () => onSelected(index),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0D47A1) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          index.toString(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor() {
    if (_totalScore < 5) return Colors.green;
    if (_totalScore < 10) return Colors.orange;
    return Colors.red;
  }

  String _getRiskAssessment() {
    if (_totalScore < 5) return "LOW MORTALITY RISK (<10%)";
    if (_totalScore < 10) return "MODERATE RISK (~20-30%)";
    return "HIGH MORTALITY RISK (>50%)";
  }
}
