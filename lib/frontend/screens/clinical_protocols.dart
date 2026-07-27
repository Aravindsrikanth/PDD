import 'package:flutter/material.dart';

class ClinicalProtocolsScreen extends StatelessWidget {
  const ClinicalProtocolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clinical Protocols')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _protocolItem('Sepsis Management 2026', 'Updated guidelines for initial fluid resuscitation.'),
          _protocolItem('Ventilator Weaning', 'Step-by-step criteria for extubation readiness.'),
          _protocolItem('Advanced Airway Protocol', 'Difficult intubation checklist and drugs.'),
        ],
      ),
    );
  }

  Widget _protocolItem(String title, String desc) => Card(
    child: ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), 
      subtitle: Text(desc), 
      trailing: const Icon(Icons.picture_as_pdf, color: Colors.red)
    )
  );
}
