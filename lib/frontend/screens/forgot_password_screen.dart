import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:icu_app/backend/state/app_state.dart';
import 'package:provider/provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _idController = TextEditingController();
  final _phoneController = TextEditingController();
  final _newPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recovery')),
      body: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Text('Reset Password', style: GoogleFonts.outfit(fontSize: 24)),
            TextField(controller: _idController, decoration: const InputDecoration(labelText: 'Staff ID')),
            TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone')),
            TextField(controller: _newPasswordController, decoration: const InputDecoration(labelText: 'New Password')),
            const SizedBox(height: 40),
            ElevatedButton(onPressed: () {}, child: const Text('RESET')),
          ],
        ),
      ),
    );
  }
}
