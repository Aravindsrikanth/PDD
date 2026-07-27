import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:icu_app/backend.dart';

// ==========================================
// WIDGETS
// ==========================================

class CustomCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  const CustomCard({super.key, required this.title, required this.subtitle, required this.icon, required this.onTap, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = iconColor ?? theme.colorScheme.primary;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, size: 32, color: primaryColor),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
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
          SizedBox(height: isMobile ? 16 : 30),
          Text("Clinical ICU Suite Pro", style: GoogleFonts.poppins(fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.bold, color: const Color(0xFF2D3436)), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text("Secure access to real-time critical care data, patient monitoring, and drug dose calculations.", style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF2D3436).withValues(alpha: 0.7)), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildRightPanel(BuildContext context, AppState appState, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 30 : 60),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("ICU SUITE", style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1))),
          Text("Professional Clinical Gateway", style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 40),
          DropdownButtonFormField<String>(
            initialValue: _selectedRole,
            decoration: const InputDecoration(labelText: 'System Role', border: UnderlineInputBorder()),
            items: ['Doctor', 'Nurse', 'Admin'].map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
            onChanged: (val) => setState(() => _selectedRole = val!),
          ),
          const SizedBox(height: 20),
          TextField(controller: _idController, decoration: const InputDecoration(labelText: 'Staff ID', prefixIcon: Icon(Icons.badge_outlined, size: 20), border: UnderlineInputBorder())),
          const SizedBox(height: 20),
          TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline, size: 20), border: UnderlineInputBorder())),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity, height: 55,
            child: ElevatedButton(
              onPressed: appState.isLoading ? null : () async {
                final success = await appState.login(_selectedRole, _idController.text, _passwordController.text);
                if (mounted && success) Navigator.pushReplacementNamed(context, '/dashboard');
              },
              child: appState.isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("SIGN IN TO SYSTEM", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 30),
          Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text("New Staff Member? "), GestureDetector(onTap: () => Navigator.pushNamed(context, '/register'), child: const Text("Register Here", style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold)))]))
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
          IconButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All systems normal.'))), icon: const Icon(Icons.notifications_active_outlined)),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(decoration: BoxDecoration(color: Color(0xFF0D47A1)), child: Icon(Icons.account_circle, color: Colors.white, size: 50)),
            _drawerItem(context, Icons.dashboard, 'Dashboard', '/dashboard'),
            _drawerItem(context, Icons.people, 'Patient Management', '/patient_management'),
            _drawerItem(context, Icons.calculate, 'Dose Calculator', '/dose_calculator'),
            _drawerItem(context, Icons.assessment_outlined, 'SOFA Score', '/scoring'),
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
    final isMobile = MediaQuery.of(context).size.width < 600;
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Clinical Overview', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: isMobile ? 2 : 4, crossAxisSpacing: 12, mainAxisSpacing: 12,
            children: [
              StatCard(title: 'Active Patients', value: appState.patients.length.toString(), icon: Icons.people, color: Colors.blue, onTap: () => Navigator.pushNamed(context, '/patient_management')),
              StatCard(title: 'Available Beds', value: appState.availableBeds.length.toString(), icon: Icons.bed, color: Colors.green),
              StatCard(title: 'Staff Active', value: appState.activeStaff.length.toString(), icon: Icons.medical_services, color: Colors.purple),
            ],
          ),
          const SizedBox(height: 32),
          const Text('Recent Patients', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: appState.patients.length > 5 ? 5 : appState.patients.length,
            itemBuilder: (context, i) {
              final p = appState.patients[i];
              return ListTile(leading: const CircleAvatar(child: Icon(Icons.person)), title: Text(p.name), subtitle: Text('Bed: ${p.bedNumber} • ${p.status}'));
            },
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title, value; final IconData icon; final Color color; final VoidCallback? onTap;
  const StatCard({super.key, required this.title, required this.value, required this.icon, required this.color, this.onTap});
  @override
  Widget build(BuildContext context) {
    return Card(child: InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.all(12.0), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 28), const SizedBox(height: 8), Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)), Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]))));
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

class PatientManagementScreen extends StatefulWidget { const PatientManagementScreen({super.key}); @override State<PatientManagementScreen> createState() => _PatientManagementScreenState(); }
class _PatientManagementScreenState extends State<PatientManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Patient Management')),
      body: ListView.builder(itemCount: appState.patients.length, itemBuilder: (context, i) {
        final p = appState.patients[i];
        return ListTile(title: Text(p.name), subtitle: Text('Bed: ${p.bedNumber} • Weight: ${p.weight}kg'), trailing: Text(p.status, style: TextStyle(color: p.status == 'Critical' ? Colors.red : Colors.green, fontWeight: FontWeight.bold)));
      }),
      floatingActionButton: FloatingActionButton(onPressed: () {}, child: const Icon(Icons.person_add)),
    );
  }
}

class DoseCalculatorScreen extends StatefulWidget { const DoseCalculatorScreen({super.key}); @override State<DoseCalculatorScreen> createState() => _DoseCalculatorScreenState(); }
class _DoseCalculatorScreenState extends State<DoseCalculatorScreen> {
  final _weightController = TextEditingController(); Medication? _selectedMed; double? _result;
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Dose Calculator')),
      body: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
        DropdownButtonFormField<Medication>(value: _selectedMed, decoration: const InputDecoration(labelText: 'Medication'), items: appState.medications.map((m) => DropdownMenuItem(value: m, child: Text(m.name))).toList(), onChanged: (v) => setState(() => _selectedMed = v)),
        const SizedBox(height: 20),
        TextField(controller: _weightController, decoration: const InputDecoration(labelText: 'Weight (kg)'), keyboardType: TextInputType.number),
        const SizedBox(height: 40),
        if (_selectedMed != null && _weightController.text.isNotEmpty) Text('Calculated Dose: ${(double.parse(_weightController.text) * _selectedMed!.standardDosePerKg).toStringAsFixed(2)} ${_selectedMed!.unit}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ])),
    );
  }
}

class ScoringScreen extends StatefulWidget { final Patient? initialPatient; const ScoringScreen({super.key, this.initialPatient}); @override State<ScoringScreen> createState() => _ScoringScreenState(); }
class _ScoringScreenState extends State<ScoringScreen> {
  @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('Clinical Scoring')), body: const Center(child: Text('SOFA Scoring Module Ready'))); }
}

class ForgotPasswordScreen extends StatelessWidget { const ForgotPasswordScreen({super.key}); @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('Recovery'))); } }
class DbConfigScreen extends StatelessWidget { const DbConfigScreen({super.key}); @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('Config'))); } }
class InteractionScreen extends StatelessWidget { const InteractionScreen({super.key}); @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('Interactions'))); } }
class PrescriptionScreen extends StatelessWidget { const PrescriptionScreen({super.key}); @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('Prescriptions'))); } }
class AuditLogScreen extends StatelessWidget { const AuditLogScreen({super.key}); @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('Logs'))); } }
class EmergencyScreen extends StatelessWidget { const EmergencyScreen({super.key}); @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('Emergency'))); } }
class AnalyticsScreen extends StatelessWidget { const AnalyticsScreen({super.key}); @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('Analytics'))); } }
class ReportGeneratorScreen extends StatelessWidget { const ReportGeneratorScreen({super.key}); @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('Reports'))); } }
class DrugDatabaseScreen extends StatelessWidget { const DrugDatabaseScreen({super.key}); @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('Drug DB'))); } }
