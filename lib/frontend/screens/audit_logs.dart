import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:icu_app/backend/state/app_state.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final logs = appState.activityLogs
        .where((log) => 
            log['action'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
            log['user'].toString().toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Audit Logs'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search logs...',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
        ),
      ),
      body: logs.isEmpty 
        ? const Center(child: Text('No matching activity logs found'))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              String timeDisplay = log['time']?.toString() ?? log['timestamp']?.toString() ?? '';
              try {
                if (log['timestamp'] != null) {
                  DateTime dt = DateTime.parse(log['timestamp']);
                  timeDisplay = "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
                }
              } catch (_) {}

              return ListTile(
                leading: Text(timeDisplay, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                title: Text(log['user']?.toString() ?? 'System', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(log['action']?.toString() ?? ''),
                trailing: const Icon(Icons.info_outline, size: 16),
                isThreeLine: false,
              );
            },
          ),
    );
  }
}
