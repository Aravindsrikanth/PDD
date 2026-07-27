import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:icu_app/backend/models/medication.dart';
import 'package:icu_app/backend/state/app_state.dart';

class InteractionScreen extends StatefulWidget {
  const InteractionScreen({super.key});

  @override
  State<InteractionScreen> createState() => _InteractionScreenState();
}

class _InteractionScreenState extends State<InteractionScreen> {
  final List<Medication> _selectedMeds = [];

  List<String> _getInteractions(List<Medication> allMeds) {
    List<String> alerts = [];
    for (int i = 0; i < _selectedMeds.length; i++) {
      for (int j = i + 1; j < _selectedMeds.length; j++) {
        if (_selectedMeds[i].interactions.contains(_selectedMeds[j].id) ||
            _selectedMeds[j].interactions.contains(_selectedMeds[i].id)) {
          alerts.add('❌ CRITICAL: ${_selectedMeds[i].name} + ${_selectedMeds[j].name}');
        }
      }
    }
    return alerts;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final allMeds = appState.medications;
    final alerts = _getInteractions(allMeds);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Interaction Checker'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
            ),
            child: const Column(
              children: [
                Text(
                  'Safety Conflict Detection',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Select medications from the list to analyze potential interactions and adverse effects.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: allMeds.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final med = allMeds[index];
                final isSelected = _selectedMeds.any((m) => m.id == med.id);
                return CheckboxListTile(
                  title: Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text(med.category, style: TextStyle(color: Colors.blueGrey[400])),
                  secondary: CircleAvatar(
                    backgroundColor: Colors.blue[50],
                    child: const Icon(Icons.medication_liquid_sharp, size: 20, color: Colors.blue),
                  ),
                  value: isSelected,
                  activeColor: const Color(0xFF0D47A1),
                  onChanged: (val) {
                    setState(() {
                      if (val!) {
                        _selectedMeds.add(med);
                      } else {
                        _selectedMeds.removeWhere((m) => m.id == med.id);
                      }
                    });
                  },
                );
              },
            ),
          ),
          _buildAlertPanel(alerts),
        ],
      ),
    );
  }

  Widget _buildAlertPanel(List<String> alerts) {
    if (_selectedMeds.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: alerts.isNotEmpty ? Colors.red[50] : Colors.green[50],
        border: Border(top: BorderSide(color: (alerts.isNotEmpty ? Colors.red[200] : Colors.green[200])!)),
      ),
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  alerts.isNotEmpty ? Icons.warning_rounded : Icons.check_circle_rounded,
                  color: alerts.isNotEmpty ? Colors.red : Colors.green,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    alerts.isNotEmpty ? 'SAFETY WARNINGS' : 'SYSTEM CLEAR',
                    style: TextStyle(
                      color: alerts.isNotEmpty ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (alerts.isNotEmpty)
              ...alerts.map((alert) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(alert, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ))
            else if (_selectedMeds.length > 1)
              const Text('No known interactions for this combination.', style: TextStyle(color: Colors.green))
            else
              const Text('Select at least two drugs to check for interactions.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
