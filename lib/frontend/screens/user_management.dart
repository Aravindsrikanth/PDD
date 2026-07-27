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
    String? errorText;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add New Staff Member', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Column(
                      children: [
                        Text(errorText!, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        if (errorText!.contains("EXISTS"))
                          TextButton(
                            onPressed: () async {
                              final appState = Provider.of<AppState>(context, listen: false);
                              await appState.deleteStaff(idController.text);
                              setDialogState(() => errorText = "ID ${idController.text} DELETED. YOU CAN NOW CREATE IT.");
                              _loadStaff();
                            },
                            child: const Text('DELETE EXISTING ID NOW', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  ),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
                  items: ['Doctor', 'Nurse'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) => setDialogState(() => selectedRole = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: idController,
                  decoration: const InputDecoration(labelText: 'Staff ID', prefixIcon: Icon(Icons.badge_outlined), border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: const InputDecoration(labelText: 'Phone Number (10 Digits)', prefixIcon: Icon(Icons.phone_android), border: OutlineInputBorder(), counterText: ""),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passController,
                  decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline), border: OutlineInputBorder()),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () async {
                if (idController.text.isEmpty || phoneController.text.isEmpty || passController.text.isEmpty) {
                  setDialogState(() => errorText = "ALL FIELDS ARE REQUIRED");
                  return;
                }
                if (phoneController.text.length != 10) {
                  setDialogState(() => errorText = "PHONE NUMBER MUST BE 10 DIGITS");
                  return;
                }

                final appState = Provider.of<AppState>(context, listen: false);
                final success = await appState.register(selectedRole, idController.text, "N/A", phoneController.text, passController.text);
                
                if (success) {
                  if (mounted) {
                    Navigator.pop(context);
                    _loadStaff();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff account added successfully!'), backgroundColor: Colors.green));
                  }
                } else {
                  setDialogState(() => errorText = "STAFF ID ${idController.text} ALREADY EXISTS");
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
        actions: [IconButton(onPressed: _loadStaff, icon: const Icon(Icons.refresh))],
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
              final status = user['status'] ?? 'Approved';
              bool isMainAdmin = staffId == "admin";

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  leading: CircleAvatar(backgroundColor: Colors.blue[50], child: Icon(Icons.person, color: Colors.blue[900])),
                  title: Text('$staffId', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('$role • Status: $status', style: const TextStyle(fontSize: 12)),
                  trailing: isMainAdmin ? const Text('MASTER') : PopupMenuButton<String>(
                    onSelected: (val) async {
                       if (val == 'delete') {
                         await appState.deleteStaff(staffId);
                         _loadStaff();
                       }
                       if (val == 'block') {
                         await appState.blockUser(staffId);
                         _loadStaff();
                       }
                       if (val == 'approve') {
                         await appState.approveUser(staffId);
                         _loadStaff();
                       }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'approve', child: Text('Approve')),
                      const PopupMenuItem(value: 'block', child: Text('Block')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete Account', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ),
              );
            },
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStaffDialog,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('ADD NEW STAFF'),
        backgroundColor: const Color(0xFF0D47A1),
      ),
    );
  }
}
