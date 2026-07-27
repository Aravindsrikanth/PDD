import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:icu_app/backend/state/app_state.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});
  @override State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<Map<String, dynamic>> _allStaff = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final staff = await appState.fetchStaff();
    if (mounted) {
      setState(() {
        _allStaff = staff;
        _isLoading = false;
      });
    }
  }

  void _showAddStaffDialog() {
    final idController = TextEditingController();
    final phoneController = TextEditingController();
    final passController = TextEditingController();
    String selectedRole = 'Nurse';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Staff Member'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: ['Doctor', 'Nurse'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) => setDialogState(() => selectedRole = v!),
                ),
                TextField(controller: idController, decoration: const InputDecoration(labelText: 'Staff ID')),
                TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone Number')),
                TextField(controller: passController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                final appState = Provider.of<AppState>(context, listen: false);
                final success = await appState.register(selectedRole, idController.text, "N/A", phoneController.text, passController.text);
                if (success) {
                  // Admin created accounts are auto-approved
                  await appState.approveUser(idController.text);
                  if (mounted) {
                    Navigator.pop(context);
                    _loadStaff();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff account created successfully.')));
                  }
                }
              },
              child: const Text('CREATE ACCOUNT'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff & Access Control'),
        actions: [
          IconButton(onPressed: _loadStaff, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _allStaff.length,
            itemBuilder: (context, i) {
              final user = _allStaff[i];
              final staffId = user['staffId'] ?? 'N/A';
              final role = user['role'] ?? 'N/A';
              final status = user['status'] ?? 'Pending';
              bool isMainAdmin = staffId == "admin";

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(status).withOpacity(0.1),
                    child: Icon(Icons.person, color: _getStatusColor(status)),
                  ),
                  title: Text('$staffId ($role)'),
                  subtitle: Text('Status: $status'),
                  trailing: isMainAdmin ? const Text('MASTER') : PopupMenuButton<String>(
                    onSelected: (val) async {
                       if (val == 'approve') await appState.approveUser(staffId);
                       if (val == 'block') await appState.blockUser(staffId);
                       _loadStaff();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'approve', child: Text('Approve Account')),
                      const PopupMenuItem(value: 'block', child: Text('Block Account')),
                    ],
                  ),
                ),
              );
            },
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStaffDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('ADD STAFF'),
        backgroundColor: const Color(0xFF0D47A1),
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'Approved') return Colors.green;
    if (status == 'Blocked') return Colors.red;
    return Colors.orange;
  }
}
