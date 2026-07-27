import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:icu_app/backend/state/app_state.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _idController = TextEditingController();
  final _phoneController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Password Recovery'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reset Your Password',
                    style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Enter your registered details to set a new password instantly.',
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 40),
                
                TextField(
                  controller: _idController,
                  decoration: const InputDecoration(
                    labelText: 'Staff ID', 
                    prefixIcon: Icon(Icons.badge), 
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Registered Phone Number', 
                    prefixIcon: Icon(Icons.phone), 
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 20),
                TextField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password', 
                    prefixIcon: Icon(Icons.lock_reset), 
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password', 
                    prefixIcon: Icon(Icons.lock_reset), 
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 40),
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
                      if (_idController.text.isEmpty || _phoneController.text.isEmpty || _newPasswordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill in all fields'))
                        );
                        return;
                      }

                      if (_newPasswordController.text != _confirmPasswordController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Passwords do not match'))
                        );
                        return;
                      }

                      final success = await appState.resetPasswordWithPhone(
                        _idController.text, 
                        _phoneController.text, 
                        _newPasswordController.text
                      );
                      
                      if (mounted) {
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password updated successfully! Please login.'))
                          );
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Update failed. Staff ID and Phone Number do not match our records.'))
                          );
                        }
                      }
                    },
                    child: appState.isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text('RESET PASSWORD', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
