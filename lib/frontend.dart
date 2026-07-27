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
        width: isMobile ? double.infinity : 1100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
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
        DrawerHeader(decoration: const BoxDecoration(color: Color(0xFF0D47A1)), child: Column(children: [const Icon(Icons.account_circle, color: Colors.white, size: 50), Text('Staff: $role', style: const TextStyle(color: Colors.white)), const Text('ID: 88492-A', style: TextStyle(color: Colors.white70))])),
        ListTile(leading: const Icon(Icons.dashboard), title: const Text('Dashboard'), onTap: () => Navigator.pop(context)),
        ListTile(leading: const Icon(Icons.people), title: const Text('Patient Management'), onTap: () => Navigator.pushNamed(context, '/patient_management')),
        ListTile(leading: const Icon(Icons.calculate), title: const Text('Dose Calculator'), onTap: () => Navigator.pushNamed(context, '/dose_calculator')),
        ListTile(leading: const Icon(Icons.assessment_outlined), title: const Text('Clinical Scoring (SOFA)'), onTap: () => Navigator.pushNamed(context, '/scoring')),
        ListTile(leading: const Icon(Icons.security), title: const Text('Interaction Checker'), onTap: () => Navigator.pushNamed(context, '/interaction_checker')),
        ListTile(leading: const Icon(Icons.menu_book), title: const Text('Drug Reference'), onTap: () => Navigator.pushNamed(context, '/drug_database')),
        ListTile(leading: const Icon(Icons.receipt_long), title: const Text('Prescriptions'), onTap: () => Navigator.pushNamed(context, '/prescriptions')),
        ListTile(leading: const Icon(Icons.bar_chart), title: const Text('Medication Analytics'), onTap: () => Navigator.pushNamed(context, '/analytics')),
        const Divider(),
        ListTile(leading: const Icon(Icons.history), title: const Text('Activity Logs'), onTap: () => Navigator.pushNamed(context, '/audit_logs')),
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
    final appState = Provider.of<AppState>(context); final bool isMobile = MediaQuery.of(context).size.width < 600;
    final criticalPatients = appState.patients.where((p) => p.status == 'Critical').toList();
    return RefreshIndicator(onRefresh: () => appState.syncWithServer(), child: SingleChildScrollView(padding: EdgeInsets.all(isMobile ? 16 : 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Clinical Overview', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
        Row(children: [
          TextButton.icon(onPressed: () => appState.syncWithServer(), icon: const Icon(Icons.sync, size: 18), label: const Text('SYNC SERVER')),
          const SizedBox(width: 12),
          ElevatedButton.icon(onPressed: () => Navigator.pushNamed(context, '/emergency'), icon: const Icon(Icons.warning_amber, size: 18), label: const Text('EMERGENCY'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white)),
        ]),
      ]),
      const SizedBox(height: 24),
      if (criticalPatients.isNotEmpty) Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red[100]!)), child: Row(children: [
        const Icon(Icons.warning, color: Colors.red), const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('CRITICAL PATIENTS: ${criticalPatients.length}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          Text('Beds: ${criticalPatients.map((p) => p.bedNumber).join(", ")} require attention.', style: TextStyle(color: Colors.red[900], fontSize: 12)),
        ])),
        TextButton(onPressed: () => Navigator.pushNamed(context, '/patient_management'), child: const Text('VIEW ALL')),
      ])),
      GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: isMobile ? 2 : 4, crossAxisSpacing: 12, mainAxisSpacing: 12, children: [
        StatCard(title: 'Active Patients', value: appState.patients.length.toString(), icon: Icons.people, color: Colors.blue, onTap: () => Navigator.pushNamed(context, '/patient_management')),
        StatCard(title: 'Available Beds', value: '∞', icon: Icons.bed, color: Colors.green),
        StatCard(title: 'Critical Alerts', value: criticalPatients.length.toString(), icon: Icons.notification_important, color: Colors.orange),
        StatCard(title: 'Staff Active', value: appState.activeStaff.length.toString(), icon: Icons.medical_services, color: Colors.purple),
      ]),
      const SizedBox(height: 32),
      _buildHandover(appState),
      const SizedBox(height: 32),
      _buildPatientList(context, appState.patients),
      const SizedBox(height: 32),
      _buildRecentActivity(appState.activityLogs),
    ])));
  }
  Widget _buildHandover(AppState appState) => Card(color: const Color(0xFF0D47A1), child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Row(children: [Icon(Icons.assignment, color: Colors.white, size: 20), SizedBox(width: 10), Text('SHIFT HANDOVER NOTES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))]),
    const SizedBox(height: 8), Text(appState.shiftHandover, style: const TextStyle(color: Colors.white, fontSize: 16)),
    const SizedBox(height: 16), const Text('Last updated: Just now by Dr. Smith', style: TextStyle(color: Colors.white54, fontSize: 11)),
  ])));
  Widget _buildPatientList(BuildContext context, List<Patient> patients) => Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Current Patients in ICU', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    const SizedBox(height: 16),
    ...patients.take(4).map((p) => Column(children: [
      ListTile(
        leading: CircleAvatar(backgroundColor: Colors.blue[50], child: const Icon(Icons.person, size: 20)),
        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Bed ${p.bedNumber} • Age: ${p.age}'),
        trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: p.status == 'Critical' ? Colors.red[50] : Colors.green[50], borderRadius: BorderRadius.circular(20)), child: Text(p.status, style: TextStyle(color: p.status == 'Critical' ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 12))),
      ),
      const Divider(),
    ])).toList(),
  ])));
  Widget _buildRecentActivity(List<Map<String, dynamic>> logs) => Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Recent Activities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    const SizedBox(height: 16),
    ...logs.take(5).map((log) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(log['action']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w500)), Text(log['timestamp']?.toString() ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12))])),
    ]))).toList(),
  ])));
}

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
        return ListTile(leading: const CircleAvatar(child: Icon(Icons.person)), title: Text(p.name), subtitle: Text('Bed: ${p.bedNumber} • Weight: ${p.weight}kg'), trailing: Text(p.status, style: TextStyle(color: p.status == 'Critical' ? Colors.red : Colors.green, fontWeight: FontWeight.bold)));
      }),
      floatingActionButton: FloatingActionButton(onPressed: () {}, child: const Icon(Icons.person_add)),
    );
  }
}

class DoseCalculatorScreen extends StatefulWidget {
  const DoseCalculatorScreen({super.key});
  @override State<DoseCalculatorScreen> createState() => _DoseCalculatorScreenState();
}

class _DoseCalculatorScreenState extends State<DoseCalculatorScreen> {
  final _weightController = TextEditingController(); Medication? _selectedMed;
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Dose Calculator')),
      body: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
        DropdownButtonFormField<Medication>(value: _selectedMed, decoration: const InputDecoration(labelText: 'Medication'), items: appState.medications.map((m) => DropdownMenuItem(value: m, child: Text(m.name))).toList(), onChanged: (v) => setState(() => _selectedMed = v)),
        TextField(controller: _weightController, decoration: const InputDecoration(labelText: 'Weight (kg)'), keyboardType: TextInputType.number),
        const SizedBox(height: 40),
        if (_selectedMed != null && _weightController.text.isNotEmpty) Text('Dose: ${(double.parse(_weightController.text) * _selectedMed!.standardDosePerKg).toStringAsFixed(2)} ${_selectedMed!.unit}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ])),
    );
  }
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
      appBar: AppBar(title: const Text('User Management'), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView.builder(itemCount: _staff.length, itemBuilder: (c, i) => ListTile(title: Text(_staff[i]['staffId']), subtitle: Text(_staff[i]['role']), trailing: PopupMenuButton<String>(onSelected: (v) async { if (v == 'del') await appState.deleteStaff(_staff[i]['staffId']); _load(); }, itemBuilder: (c) => [const PopupMenuItem(value: 'del', child: Text('Delete Account'))]))),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _showAdd(appState), icon: const Icon(Icons.add), label: const Text('ADD STAFF')),
    );
  }
  void _showAdd(AppState appState) {
    final id = TextEditingController(), ph = TextEditingController(), pw = TextEditingController(); String role = 'Doctor'; bool dLoad = false;
    showDialog(context: context, builder: (c) => StatefulBuilder(builder: (context, setD) => AlertDialog(title: const Text('Add New Staff'), content: Column(mainAxisSize: MainAxisSize.min, children: [
      DropdownButtonFormField<String>(value: role, items: ['Doctor', 'Nurse'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(), onChanged: (v) => setD(() => role = v!)),
      TextField(controller: id, decoration: const InputDecoration(labelText: 'Staff ID')),
      TextField(controller: ph, decoration: const InputDecoration(labelText: 'Phone')),
      TextField(controller: pw, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
    ]), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')), ElevatedButton(onPressed: dLoad ? null : () async {
      setD(() => dLoad = true); final s = await appState.register(role, id.text, ph.text, pw.text);
      if (mounted) { if (s) { Navigator.pop(c); _load(); } else { setD(() => dLoad = false); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration error.'))); } }
    }, child: dLoad ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create'))])));
  }
}

class RegistrationScreen extends StatelessWidget { const RegistrationScreen({super.key}); @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('Registration'))); } }
class ForgotPasswordScreen extends StatelessWidget { const ForgotPasswordScreen({super.key}); @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('Recovery'))); } }
class DbConfigScreen extends StatelessWidget { const DbConfigScreen({super.key}); @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('Config'))); } }
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
