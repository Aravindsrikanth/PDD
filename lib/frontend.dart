import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:icu_app/backend.dart';

// ==========================================
// WIDGETS
// ==========================================

class StatCard extends StatelessWidget {
  final String title, value; final IconData icon; final Color color; final VoidCallback? onTap;
  const StatCard({super.key, required this.title, required this.value, required this.icon, required this.color, this.onTap});
  @override
  Widget build(BuildContext context) {
    return Card(child: InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.all(12.0), child: Row(children: [
      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold), maxLines: 2),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
      ])),
    ]))));
  }
}

// ==========================================
// SCREENS
// ==========================================

class MedicalLoginScreen extends StatefulWidget {
  const MedicalLoginScreen({super.key});
  @override State<MedicalLoginScreen> createState() => _MedicalLoginScreenState();
}

class _MedicalLoginScreenState extends State<MedicalLoginScreen> {
  final _idController = TextEditingController(), _passwordController = TextEditingController(); String _selectedRole = 'Doctor';
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context); final size = MediaQuery.of(context).size; final bool isMobile = size.width < 900;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Container(
        width: isMobile ? size.width * 0.95 : 1100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: ClipRRect(borderRadius: BorderRadius.circular(24), child: isMobile ? Column(children: [_buildLeft(true), _buildRight(context, appState, true)]) : Row(children: [Expanded(child: _buildLeft(false)), Expanded(child: _buildRight(context, appState, false))])),
      ))),
    );
  }
  Widget _buildLeft(bool isMobile) => Container(width: double.infinity, color: const Color(0xFFB7CBBF), padding: EdgeInsets.all(isMobile ? 24 : 40), child: Column(children: [Icon(Icons.medical_services_outlined, size: isMobile ? 60 : 100, color: Colors.white), const SizedBox(height: 20), Text("Clinical ICU Suite Pro", style: GoogleFonts.poppins(fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.bold)), const Text("Secure clinical gateway.", textAlign: TextAlign.center)]));
  Widget _buildRight(BuildContext context, AppState appState, bool isMobile) => Padding(padding: EdgeInsets.all(isMobile ? 30 : 60), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text("ICU SUITE", style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1))),
    DropdownButtonFormField<String>(initialValue: _selectedRole, decoration: const InputDecoration(labelText: 'System Role'), items: ['Doctor', 'Nurse', 'Admin'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(), onChanged: (v) => setState(() => _selectedRole = v!)),
    TextField(controller: _idController, decoration: const InputDecoration(labelText: 'Staff ID', prefixIcon: Icon(Icons.badge_outlined))),
    TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline))),
    const SizedBox(height: 30),
    SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: appState.isLoading ? null : () async {
      final res = await appState.login(_selectedRole, _idController.text, _passwordController.text);
      if (mounted && res['success'] == true) Navigator.pushReplacementNamed(context, '/dashboard');
      else if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['error'] ?? 'Login failed'), backgroundColor: Colors.red));
    }, child: appState.isLoading ? const CircularProgressIndicator() : const Text("SIGN IN TO SYSTEM"))),
  ]));
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context); final role = appState.currentUserRole;
    return Scaffold(
      appBar: AppBar(title: Text('ICU Dashboard - $role'), actions: [IconButton(onPressed: () => appState.toggleTheme(), icon: Icon(appState.isDarkMode ? Icons.light_mode : Icons.dark_mode)), const VerticalDivider(width: 20, indent: 15, endIndent: 15), CircleAvatar(child: Text(role?[0] ?? 'U')), const SizedBox(width: 20)]),
      drawer: Drawer(child: ListView(padding: EdgeInsets.zero, children: [
        DrawerHeader(decoration: const BoxDecoration(color: Color(0xFF0D47A1)), child: Column(children: [const Icon(Icons.account_circle, color: Colors.white, size: 50), Text('Staff: $role', style: const TextStyle(color: Colors.white)), const Text('ID: Authorized Session', style: TextStyle(color: Colors.white70))])),
        
        ListTile(leading: const Icon(Icons.dashboard), title: const Text('Dashboard'), onTap: () => Navigator.pop(context)),
        
        // --- DOCTOR EXCLUSIVE ---
        if (role == 'Doctor') ...[
          ListTile(leading: const Icon(Icons.assessment_outlined), title: const Text('SOFA Scoring'), onTap: () => Navigator.pushNamed(context, '/scoring')),
          ListTile(leading: const Icon(Icons.calculate), title: const Text('Dose Calculator'), onTap: () => Navigator.pushNamed(context, '/dose_calculator')),
          ListTile(leading: const Icon(Icons.menu_book_outlined), title: const Text('Clinical Protocols'), onTap: () => Navigator.pushNamed(context, '/protocols')),
        ],

        // --- NURSE EXCLUSIVE ---
        if (role == 'Nurse') ...[
          ListTile(leading: const Icon(Icons.people), title: const Text('Patient Management'), onTap: () => Navigator.pushNamed(context, '/patient_management')),
          ListTile(leading: const Icon(Icons.assignment_turned_in), title: const Text('Shift Handover'), onTap: () => Navigator.pushNamed(context, '/handover')),
          ListTile(leading: const Icon(Icons.medical_information_outlined), title: const Text('Drug Database'), onTap: () => Navigator.pushNamed(context, '/drug_database')),
        ],

        // --- ADMIN EXCLUSIVE ---
        if (role == 'Admin') ...[
          ListTile(leading: const Icon(Icons.manage_accounts), title: const Text('User Management'), onTap: () => Navigator.pushNamed(context, '/user_management')),
          ListTile(leading: const Icon(Icons.bar_chart), title: const Text('Analytics'), onTap: () => Navigator.pushNamed(context, '/analytics')),
          ListTile(leading: const Icon(Icons.history), title: const Text('Activity Logs'), onTap: () => Navigator.pushNamed(context, '/audit_logs')),
          ListTile(leading: const Icon(Icons.settings_applications), title: const Text('System Config'), onTap: () => Navigator.pushNamed(context, '/config')),
        ],

        const Divider(),
        ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text('Logout', style: TextStyle(color: Colors.red)), onTap: () { appState.logout(); Navigator.pushReplacementNamed(context, '/login'); }),
      ])),
      body: const DashboardContent(),
    );
  }
}

class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context); final role = appState.currentUserRole; final bool isMobile = MediaQuery.of(context).size.width < 600;
    return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Welcome, $role', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
      const SizedBox(height: 24),
      
      if (role == 'Doctor') _buildDoctorGrid(appState, isMobile),
      if (role == 'Nurse') _buildNurseGrid(appState, isMobile),
      if (role == 'Admin') _buildAdminGrid(appState, isMobile),

      const SizedBox(height: 32),
      Text(role == 'Admin' ? 'Recent System Activity' : 'Priority Patients', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ...appState.patients.take(5).map((p) => ListTile(leading: CircleAvatar(child: Text(p.name[0])), title: Text(p.name), subtitle: Text('Bed: ${p.bedNumber} • ${p.status}'))),
    ]));
  }

  Widget _buildDoctorGrid(AppState appState, bool isMobile) => GridView.count(shrinkWrap: true, crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, children: [
    StatCard(title: 'Critical Alerts', value: '1', icon: Icons.warning_amber, color: Colors.red, onTap: () {}),
    StatCard(title: 'Active Rounds', value: appState.patients.length.toString(), icon: Icons.assignment_ind, color: Colors.blue),
  ]);

  Widget _buildNurseGrid(AppState appState, bool isMobile) => GridView.count(shrinkWrap: true, crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, children: [
    StatCard(title: 'My Beds', value: appState.patients.length.toString(), icon: Icons.monitor_heart, color: Colors.teal),
    StatCard(title: 'Available Beds', value: appState.availableBeds.length.toString(), icon: Icons.bed, color: Colors.green),
  ]);

  Widget _buildAdminGrid(AppState appState, bool isMobile) => GridView.count(shrinkWrap: true, crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, children: [
    StatCard(title: 'Staff On Duty', value: appState.activeStaff.length.toString(), icon: Icons.people, color: Colors.purple),
    StatCard(title: 'Sync Status', value: appState.isCloudSyncActive ? 'ONLINE' : 'OFFLINE', icon: Icons.cloud_done, color: Colors.green),
  ]);
}

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});
  @override State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<Map<String, dynamic>> _staff = []; bool _loading = true;
  @override void initState() { super.initState(); _load(); }
  void _load() async { final s = await Provider.of<AppState>(context, listen: false).fetchStaff(); if (mounted) setState(() { _staff = s; _loading = false; }); }
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView.builder(itemCount: _staff.length, itemBuilder: (c, i) => ListTile(title: Text(_staff[i]['staffId']), subtitle: Text(_staff[i]['role']), trailing: PopupMenuButton<String>(onSelected: (v) async { if (v == 'del') await appState.deleteStaff(_staff[i]['staffId']); _load(); }, itemBuilder: (c) => [const PopupMenuItem(value: 'del', child: Text('Delete Account'))]))),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _showAdd(appState), icon: const Icon(Icons.add), label: const Text('ADD STAFF')),
    );
  }
  void _showAdd(AppState appState) {
    final id = TextEditingController(), ph = TextEditingController(), pw = TextEditingController(); String role = 'Doctor'; bool dLoad = false;
    showDialog(context: context, builder: (c) => StatefulBuilder(builder: (context, setD) => AlertDialog(title: const Text('Add New Staff'), content: Column(mainAxisSize: MainAxisSize.min, children: [
      DropdownButtonFormField<String>(value: role, items: ['Doctor', 'Nurse'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(), onChanged: (v) => role = v!),
      TextField(controller: id, decoration: const InputDecoration(labelText: 'Staff ID')),
      TextField(controller: ph, decoration: const InputDecoration(labelText: 'Phone')),
      TextField(controller: pw, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
    ]), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')), ElevatedButton(onPressed: dLoad ? null : () async {
      setD(() => dLoad = true); final s = await appState.register(role, id.text, ph.text, pw.text);
      if (mounted) { if (s) { Navigator.pop(c); _load(); } else { setD(() => dLoad = false); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error creating staff.'))); } }
    }, child: dLoad ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create'))])));
  }
}

// Stub screens to satisfy routes
class RegistrationScreen extends StatelessWidget { const RegistrationScreen({super.key}); @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('Registration'))); } }
class ForgotPasswordScreen extends StatelessWidget { const ForgotPasswordScreen({super.key}); @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('Recovery'))); } }
class DbConfigScreen extends StatelessWidget { const DbConfigScreen({super.key}); @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('Config'))); } }
class PatientManagementScreen extends StatelessWidget { const PatientManagementScreen({super.key}); @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('Patients'))); } }
class DoseCalculatorScreen extends StatelessWidget { const DoseCalculatorScreen({super.key}); @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('Dose Audit'))); } }
class InteractionScreen extends StatelessWidget { const InteractionScreen({super.key}); @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('Interactions'))); } }
class PrescriptionScreen extends StatelessWidget { const PrescriptionScreen({super.key}); @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('Prescriptions'))); } }
class AuditLogScreen extends StatelessWidget { const AuditLogScreen({super.key}); @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('Logs'))); } }
class EmergencyScreen extends StatelessWidget { const EmergencyScreen({super.key}); @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('Emergency'))); } }
class AnalyticsScreen extends StatelessWidget { const AnalyticsScreen({super.key}); @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('Analytics'))); } }
class ReportGeneratorScreen extends StatelessWidget { const ReportGeneratorScreen({super.key}); @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('Reports'))); } }
class ScoringScreen extends StatelessWidget { const ScoringScreen({super.key}); @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('Scoring'))); } }
class DrugDatabaseScreen extends StatelessWidget { const DrugDatabaseScreen({super.key}); @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('Drug DB'))); } }
class ClinicalProtocolsScreen extends StatelessWidget { const ClinicalProtocolsScreen({super.key}); @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('Protocols'))); } }
class ShiftHandoverScreen extends StatelessWidget { const ShiftHandoverScreen({super.key}); @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('Handover'))); } }
