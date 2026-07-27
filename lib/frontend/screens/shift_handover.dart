import 'package:flutter/material.dart';

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
