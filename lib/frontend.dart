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
// NEW ROLE-SPECIFIC SCREENS
// ==========================================

class ClinicalProtocolsScreen extends StatelessWidget {
  const ClinicalProtocolsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clinical Protocols')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _protocolItem('Sepsis Management 2026', 'Updated guidelines for initial fluid resuscitation.'),
          _protocolItem('Ventilator Weaning', 'Step-by-step criteria for extubation readiness.'),
          _protocolItem('Advanced Airway Protocol', 'Difficult intubation checklist and drugs.'),
        ],
      ),
    );
  }
  Widget _protocolItem(String title, String desc) => Card(child: ListTile(title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(desc), trailing: const Icon(Icons.picture_as_pdf, color: Colors.red)));
}

class ShiftHandoverScreen extends StatelessWidget {
  const ShiftHandoverScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shift Handover')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('Patient Status Transfer', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(child: ListView(children: const [
              ListTile(leading: Icon(Icons.person), title: Text('Patient Aravind'), subtitle: Text('Stable. Off pressors at 08:00.')),
              ListTile(leading: Icon(Icons.person), title: Text('Patient Ashok'), subtitle: Text('Critical. FI02 increased to 60%.')),
            ])),
            ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.send), label: const Text('GENERATE HANDOVER REPORT')),
          ],
        ),
      ),
    );
  }
}

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

// ==========================================
// EXISTING SCREENS (Restored)
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
        mainAxisSize: MainAxisSize.min,
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
