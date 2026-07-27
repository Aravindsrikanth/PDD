import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:icu_app/backend/state/app_state.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      body: ListView.builder(
        itemCount: appState.activeStaff.length,
        itemBuilder: (context, i) => ListTile(
          leading: const Icon(Icons.account_circle),
          title: Text(appState.activeStaff[i]),
          subtitle: const Text('Status: On Duty'),
          trailing: const Icon(Icons.edit_note, color: Colors.blue),
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: () {}, child: const Icon(Icons.person_add)),
    );
  }
}
