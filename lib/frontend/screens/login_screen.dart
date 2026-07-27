import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:icu_app/backend/state/app_state.dart';

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
            decoration: const InputDecoration(
              labelText: 'System Role',
              border: UnderlineInputBorder(),
            ),
            items: ['Doctor', 'Nurse', 'Admin'].map((role) {
              return DropdownMenuItem(value: role, child: Text(role));
            }).toList(),
            onChanged: (val) => setState(() => _selectedRole = val!),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _idController,
            decoration: const InputDecoration(
              labelText: 'Staff ID',
              prefixIcon: Icon(Icons.badge_outlined, size: 20),
              border: UnderlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline, size: 20),
              border: UnderlineInputBorder(),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
              child: const Text("Forgot password?"),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: appState.isLoading ? null : () async {
                final result = await appState.login(_selectedRole, _idController.text, _passwordController.text);
                if (mounted) {
                  if (result['success'] == true) {
                    Navigator.pushReplacementNamed(context, '/dashboard');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result['error'] ?? 'Invalid credentials'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: appState.isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("SIGN IN TO SYSTEM", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 30),
          // --- REGISTRATION LINK REMOVED FROM HERE AS PER ADMIN-ONLY REQUEST ---
          Center(
            child: Text(
              "Access restricted to authorized personnel only.",
              style: TextStyle(color: Colors.grey[500], fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}
