import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:icu_app/backend/state/app_state.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isBroadcasting = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('EMERGENCY BROADCAST'),
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _controller,
                child: Icon(Icons.warning_amber_rounded, size: 150, color: Colors.red[900]),
              ),
              const SizedBox(height: 40),
              const Text(
                'CRITICAL ALERT SYSTEM',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Use this module to broadcast immediate alerts to all staff members on duty.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 60),
              if (!_isBroadcasting)
                _buildAlertButton('CODE BLUE - CARDIAC', Colors.red)
              else
                _buildActiveStatus(),
              const SizedBox(height: 20),
              if (!_isBroadcasting)
                _buildAlertButton('RAPID RESPONSE TEAM', Colors.orange),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertButton(String label, Color color) {
    return SizedBox(
      width: double.infinity,
      height: 70,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: () {
          setState(() => _isBroadcasting = true);
          Provider.of<AppState>(context, listen: false).triggerEmergencyAlert(label);
        },
        child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildActiveStatus() {
    return Column(
      children: [
        const Text('BROADCASTING ACTIVE...', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 20)),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => setState(() => _isBroadcasting = false),
          child: const Text('CANCEL ALERT'),
        ),
      ],
    );
  }
}
