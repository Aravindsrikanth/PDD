import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:icu_app/backend/models/patient.dart';
import 'package:icu_app/backend/state/app_state.dart';

class PatientManagementScreen extends StatefulWidget {
  const PatientManagementScreen({super.key});
  @override State<PatientManagementScreen> createState() => _PatientManagementScreenState();
}

class _PatientManagementScreenState extends State<PatientManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Patient Management')),
      body: ListView.builder(itemCount: appState.patients.length, itemBuilder: (context, i) {
        final p = appState.patients[i];
        return ListTile(title: Text(p.name), subtitle: Text('Bed: ${p.bedNumber} • Weight: ${p.weight}kg'), trailing: Text(p.status));
      }),
    );
  }
}
