import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:icu_app/backend.dart';

// ==========================================
// WIDGETS
// ==========================================

class StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const StatCard({super.key, required this.title, required this.value, required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold), maxLines: 2),
                    Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'Doctor';

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final size = MediaQuery.of(context).size;
    final bool isMobile = size.width < 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Container(
            width: isMobile ? size.width * 0.95 : 1100,
            height: isMobile ? null : 700,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 30, offset: const Offset(0, 15))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: isMobile 
                ? Column(children: [_buildLeftPanel(true), _buildRightPanel(context, appState, true)])
                : Row(children: [Expanded(child: _buildLeftPanel(false)), Expanded(child: _buildRightPanel(context, appState, false))]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeftPanel(bool isMobile) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFB7CBBF),
      padding: EdgeInsets.symmetric(vertical: isMobile ? 24 : 40, horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medical_services_outlined, size: isMobile ? 60 : 100, color: Colors.white),
          const SizedBox(height: 20),
          Text("Clinical ICU Suite Pro", style: GoogleFonts.poppins(fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          const Text("Secure access to real-time critical care data, patient monitoring, and drug dose calculations.", textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildRightPanel(BuildContext context, AppState appState, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 30 : 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("ICU SUITE", style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1))),
          const Text("Professional Clinical Gateway"),
          const SizedBox(height: 40),
          DropdownButtonFormField<String>(
            initialValue: _selectedRole,
            decoration: const InputDecoration(labelText: 'System Role', border: UnderlineInputBorder()),
            items: ['Doctor', 'Nurse', 'Admin'].map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
            onChanged: (val) => setState(() => _selectedRole = val!),
          ),
          const SizedBox(height: 20),
          TextField(controller: _idController, decoration: const InputDecoration(labelText: 'Staff ID', prefixIcon: Icon(Icons.badge_outlined), border: UnderlineInputBorder())),
          const SizedBox(height: 20),
          TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline), border: UnderlineInputBorder())),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity, height: 55,
            child: ElevatedButton(
              onPressed: appState.isLoading ? null : () async {
                final success = await appState.login(_selectedRole, _idController.text, _passwordController.text);
                if (mounted && success) Navigator.pushReplacementNamed(context, '/dashboard');
              },
              child: appState.isLoading ? const CircularProgressIndicator() : const Text("SIGN IN TO SYSTEM"),
            ),
          ),
          TextButton(onPressed: () => Navigator.pushNamed(context, '/register'), child: const Text("Register Account")),
        ],
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  @override
  Widget build(BuildContext context) {
    final role = Provider.of<AppState>(context).currentUserRole;
    return Scaffold(
      appBar: AppBar(
        title: Text('ICU Dashboard - $role'),
        actions: [
          IconButton(onPressed: () => Provider.of<AppState>(context, listen: false).toggleTheme(), icon: Icon(Provider.of<AppState>(context).isDarkMode ? Icons.light_mode : Icons.dark_mode)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_active_outlined)),
          const VerticalDivider(width: 20, indent: 15, endIndent: 15),
          CircleAvatar(backgroundColor: Colors.blue[100], child: Text(role?[0] ?? 'U')),
          const SizedBox(width: 20),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF0D47A1)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.account_circle, color: Colors.white, size: 50),
                  const SizedBox(height: 10),
                  Text('Staff: $role', style: const TextStyle(color: Colors.white, fontSize: 18)),
                  const Text('ID: 88492-A', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            _drawerItem(context, Icons.dashboard, 'Dashboard', '/dashboard'),
            _drawerItem(context, Icons.people, 'Patient Management', '/patient_management'),
            _drawerItem(context, Icons.calculate, 'Dose Calculator', '/dose_calculator'),
            _drawerItem(context, Icons.assessment_outlined, 'Clinical Scoring (SOFA)', '/scoring'),
            _drawerItem(context, Icons.security, 'Interaction Checker', '/interaction_checker'),
            _drawerItem(context, Icons.menu_book, 'Drug Reference', '/drug_database'),
            _drawerItem(context, Icons.receipt_long, 'Prescriptions', '/prescriptions'),
            _drawerItem(context, Icons.bar_chart, 'Medication Analytics', '/analytics'),
            const Divider(),
            _drawerItem(context, Icons.history, 'Activity Logs', '/audit_logs'),
            _drawerItem(context, Icons.logout, 'Logout', '/login', isLogout: true),
          ],
        ),
      ),
      body: const DashboardContent(),
    );
  }

  Widget _drawerItem(BuildContext context, IconData icon, String title, String route, {bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon, color: isLogout ? Colors.red : null),
      title: Text(title, style: TextStyle(color: isLogout ? Colors.red : null)),
      onTap: () { if (isLogout) { Provider.of<AppState>(context, listen: false).logout(); Navigator.pushReplacementNamed(context, '/login'); } else { Navigator.pop(context); Navigator.pushNamed(context, route); } },
    );
  }
}

class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final criticalPatients = appState.patients.where((p) => p.status == 'Critical').toList();

    return RefreshIndicator(
      onRefresh: () => appState.syncWithServer(),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Clinical Overview', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
                Row(children: [
                  TextButton.icon(onPressed: () => appState.syncWithServer(), icon: const Icon(Icons.sync, size: 18), label: const Text('SYNC SERVER')),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.warning_amber, size: 18), label: const Text('EMERGENCY'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white)),
                ]),
              ],
            ),
            const SizedBox(height: 24),
            if (criticalPatients.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red[100]!)),
                child: Row(children: [
                  const Icon(Icons.warning, color: Colors.red),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('CRITICAL PATIENTS: ${criticalPatients.length}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    Text('Beds: ${criticalPatients.map((p) => p.bedNumber).join(", ")} require immediate attention.', style: TextStyle(color: Colors.red[900], fontSize: 12)),
                  ])),
                  TextButton(onPressed: () => Navigator.pushNamed(context, '/patient_management'), child: const Text('VIEW ALL')),
                ]),
              ),
            GridView.count(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: isMobile ? 2 : 4, crossAxisSpacing: 12, mainAxisSpacing: 12,
              children: [
                StatCard(title: 'Active Patients', value: appState.patients.length.toString(), icon: Icons.people, color: Colors.blue, onTap: () => Navigator.pushNamed(context, '/patient_management')),
                StatCard(title: 'Available Beds', value: '∞', icon: Icons.bed, color: Colors.green),
                StatCard(title: 'Critical Alerts', value: criticalPatients.length.toString(), icon: Icons.notification_important, color: Colors.orange),
                StatCard(title: 'Staff Active', value: appState.activeStaff.length.toString(), icon: Icons.medical_services, color: Colors.purple),
              ],
            ),
            const SizedBox(height: 32),
            _buildShiftHandover(context, appState),
            const SizedBox(height: 32),
            _buildPatientList(appState.patients),
            const SizedBox(height: 32),
            _buildRecentActivity(appState.activityLogs),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftHandover(BuildContext context, AppState appState) {
    return Card(
      color: const Color(0xFF0D47A1),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(children: [Icon(Icons.assignment, color: Colors.white, size: 20), SizedBox(width: 10), Text('SHIFT HANDOVER NOTES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))]),
                IconButton(icon: const Icon(Icons.edit, color: Colors.white70, size: 18), onPressed: () {}),
              ],
            ),
            const SizedBox(height: 8),
            Text(appState.shiftHandover, style: const TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 16),
            const Text('Last updated: Just now by Dr. Smith', style: TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientList(List<Patient> patients) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Current Patients in ICU', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...patients.take(4).map((p) => Column(children: [
              ListTile(
                leading: CircleAvatar(backgroundColor: Colors.blue[50], child: const Icon(Icons.person, size: 20)),
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Bed ${p.bedNumber} • Age: ${p.age}'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: p.status == 'Critical' ? Colors.red[50] : Colors.green[50], borderRadius: BorderRadius.circular(20)),
                  child: Text(p.status, style: TextStyle(color: p.status == 'Critical' ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
              const Divider(),
            ])).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(List<Map<String, dynamic>> logs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent Activities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...logs.take(5).map((log) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(log['action']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(log['timestamp']?.toString() ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ])),
              ]),
            )).toList(),
          ],
        ),
      ),
    );
  }
}

class RegistrationScreen extends StatefulWidget { const RegistrationScreen({super.key}); @override State<RegistrationScreen> createState() => _RegistrationScreenState(); }
class _RegistrationScreenState extends State<RegistrationScreen> {
  String _selectedRole = 'Nurse'; final _idController = TextEditingController(); final _phoneController = TextEditingController(); final _passwordController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Staff Registration')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(40), child: Column(children: [
        DropdownButtonFormField<String>(initialValue: _selectedRole, decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()), items: ['Doctor', 'Nurse', 'Admin'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(), onChanged: (v) => setState(() => _selectedRole = v!)),
        const SizedBox(height: 20),
        TextField(controller: _idController, decoration: const InputDecoration(labelText: 'Staff ID', border: OutlineInputBorder())),
        const SizedBox(height: 20),
        TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder())),
        const SizedBox(height: 20),
        TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
        const SizedBox(height: 40),
        ElevatedButton(onPressed: () async { if (await appState.register(_selectedRole, _idController.text, "N/A", _phoneController.text, _passwordController.text)) Navigator.pushReplacementNamed(context, '/dashboard'); }, child: appState.isLoading ? const CircularProgressIndicator() : const Text('REGISTER'))
      ])),
    );
  }
}

class PatientManagementScreen extends StatelessWidget { const PatientManagementScreen({super.key}); @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('Patient Management'))); } }
class DoseCalculatorScreen extends StatelessWidget { const DoseCalculatorScreen({super.key}); @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('Dose Calculator'))); } }
class ForgotPasswordScreen extends StatelessWidget { const ForgotPasswordScreen({super.key}); @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('Recovery'))); } }
class DbConfigScreen extends StatelessWidget { const DbConfigScreen({super.key}); @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('Config'))); } }
class InteractionScreen extends StatelessWidget { const InteractionScreen({super.key}); @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('Interactions'))); } }
class PrescriptionScreen extends StatelessWidget { const PrescriptionScreen({super.key}); @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('Prescriptions'))); } }
class AuditLogScreen extends StatelessWidget { const AuditLogScreen({super.key}); @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('Logs'))); } }
class EmergencyScreen extends StatelessWidget { const EmergencyScreen({super.key}); @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('Emergency'))); } }
class AnalyticsScreen extends StatelessWidget { const AnalyticsScreen({super.key}); @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('Analytics'))); } }
class ReportGeneratorScreen extends StatelessWidget { const ReportGeneratorScreen({super.key}); @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('Reports'))); } }
class ScoringScreen extends StatefulWidget { final Patient? initialPatient; const ScoringScreen({super.key, this.initialPatient}); @override State<ScoringScreen> createState() => _ScoringScreenState(); }
class _ScoringScreenState extends State<ScoringScreen> { @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('Scoring'))); } }
class DrugDatabaseScreen extends StatelessWidget { const DrugDatabaseScreen({super.key}); @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('Drug DB'))); } }
