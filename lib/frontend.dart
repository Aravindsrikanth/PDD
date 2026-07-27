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
    final isMobile = MediaQuery.of(context).size.width < 900;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: isMobile ? double.infinity : 1100,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: isMobile 
                ? Column(children: [_buildLeftPanel(true), _buildRightPanel(appState, true)])
                : Row(children: [Expanded(child: _buildLeftPanel(false)), Expanded(child: _buildRightPanel(appState, false))]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeftPanel(bool isMobile) {
    return Container(
      color: const Color(0xFFB7CBBF),
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.medical_services_outlined, size: isMobile ? 60 : 100, color: Colors.white),
          const SizedBox(height: 20),
          Text("Clinical ICU Suite Pro", style: GoogleFonts.poppins(fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.bold)),
          const Text("Secure clinical gateway.", textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildRightPanel(AppState appState, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("ICU SUITE", style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1))),
          const SizedBox(height: 30),
          DropdownButtonFormField<String>(
            initialValue: _selectedRole,
            items: ['Doctor', 'Nurse', 'Admin'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
            onChanged: (v) => setState(() => _selectedRole = v!),
          ),
          TextField(controller: _idController, decoration: const InputDecoration(labelText: 'Staff ID')),
          TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity, height: 55,
            child: ElevatedButton(
              onPressed: () async {
                final success = await appState.login(_selectedRole, _idController.text, _passwordController.text);
                if (mounted && success) {
                  Navigator.pushReplacementNamed(context, '/dashboard');
                }
              },
              child: appState.isLoading ? const CircularProgressIndicator() : const Text("SIGN IN"),
            ),
          ),
          TextButton(onPressed: () => Navigator.pushNamed(context, '/register'), child: const Text("Register Account")),
        ],
      ),
    );
  }
}

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});
  @override State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  String _selectedRole = 'Nurse';
  final _idController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Staff Registration')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              items: ['Doctor', 'Nurse', 'Admin'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) => setState(() => _selectedRole = v!),
            ),
            TextField(controller: _idController, decoration: const InputDecoration(labelText: 'Staff ID')),
            TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone')),
            TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () async {
                if (await appState.register(_selectedRole, _idController.text, "N/A", _phoneController.text, _passwordController.text)) Navigator.pushReplacementNamed(context, '/dashboard');
              },
              child: const Text('REGISTER'),
            ),
          ],
        ),
      ),
    );
  }
}

class MainShell extends StatelessWidget {
  const MainShell({super.key});
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      appBar: AppBar(title: Text('Dashboard - ${appState.currentUserRole}')),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(child: Icon(Icons.medical_services, size: 50)),
            ListTile(leading: const Icon(Icons.people), title: const Text('Patients'), onTap: () => Navigator.pushNamed(context, '/patient_management')),
            ListTile(leading: const Icon(Icons.calculate), title: const Text('Dose Calc'), onTap: () => Navigator.pushNamed(context, '/dose_calculator')),
            ListTile(leading: const Icon(Icons.logout), title: const Text('Logout'), onTap: () { appState.logout(); Navigator.pushReplacementNamed(context, '/login'); }),
          ],
        ),
      ),
      body: const PatientManagementScreen(),
    );
  }
}

class PatientManagementScreen extends StatefulWidget {
  const PatientManagementScreen({super.key});
  @override State<PatientManagementScreen> createState() => _PatientManagementScreenState();
}

class _PatientManagementScreenState extends State<PatientManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return ListView.builder(
      itemCount: appState.patients.length,
      itemBuilder: (context, i) {
        final p = appState.patients[i];
        return ListTile(title: Text(p.name), subtitle: Text('Bed: ${p.bedNumber}'), trailing: Text(p.status));
      },
    );
  }
}

class DoseCalculatorScreen extends StatefulWidget {
  const DoseCalculatorScreen({super.key});
  @override State<DoseCalculatorScreen> createState() => _DoseCalculatorScreenState();
}

class _DoseCalculatorScreenState extends State<DoseCalculatorScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Dose Calculator')), body: const Center(child: Text('Dose Calculator Module')));
  }
}

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
