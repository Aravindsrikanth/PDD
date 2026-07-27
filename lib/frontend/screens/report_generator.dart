import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:icu_app/backend/state/app_state.dart';
import 'package:icu_app/backend/models/patient.dart';

class ReportGeneratorScreen extends StatefulWidget {
  const ReportGeneratorScreen({super.key});

  @override
  State<ReportGeneratorScreen> createState() => _ReportGeneratorScreenState();
}

class _ReportGeneratorScreenState extends State<ReportGeneratorScreen> {
  Patient? _selectedPatient;
  bool _isGenerating = false;

  void _simulateGeneration() async {
    if (_selectedPatient == null) return;
    
    setState(() => _isGenerating = true);
    
    // Simulate complex PDF compilation logic
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;
    setState(() => _isGenerating = false);
    
    // Log to MongoDB
    if (_selectedPatient != null) {
      Provider.of<AppState>(context, listen: false).updatePatientHistory(
        _selectedPatient!.id, 
        "Clinical PDF Report Generated at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}"
      );
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Clinical Report Generated', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            Text('Full medical history and dosing audit for ${_selectedPatient!.name} has been compiled into a secure PDF document.', textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OPEN DOCUMENT')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('DONE')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patients = Provider.of<AppState>(context).patients;

    return Scaffold(
      appBar: AppBar(title: const Text('Report Generator')),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.description_outlined, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            const Text('Clinical PDF Reporting', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Generate comprehensive medical audit reports for faculty review or patient discharge.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 48),
            
            DropdownButtonFormField<Patient>(
              value: _selectedPatient,
              decoration: const InputDecoration(
                labelText: 'Target Patient',
                prefixIcon: Icon(Icons.person_pin),
              ),
              items: patients.map((p) => DropdownMenuItem(value: p, child: Text('${p.name} (${p.bedNumber})'))).toList(),
              onChanged: (v) => setState(() => _selectedPatient = v),
            ),
            
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                icon: _isGenerating 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.picture_as_pdf),
                label: Text(_isGenerating ? 'COMPILING DATA...' : 'GENERATE CLINICAL REPORT'),
                onPressed: _selectedPatient == null || _isGenerating ? null : _simulateGeneration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
