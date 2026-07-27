import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:icu_app/backend/state/app_state.dart';

class PrescriptionScreen extends StatelessWidget {
  const PrescriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final prescriptions = appState.prescriptions;

    return Scaffold(
      appBar: AppBar(title: const Text('Prescription History')),
      body: prescriptions.isEmpty
        ? const Center(child: Text('No prescription history found'))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: prescriptions.length,
            itemBuilder: (context, index) {
              final presc = prescriptions[index];
              final isActive = presc['status'] == 'Active';
              final isDanger = presc['status'] == 'DANGER';
              
              String dateDisplay = presc['date']!;
              try {
                DateTime dt = DateTime.parse(presc['date']!);
                dateDisplay = "${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
              } catch (_) {}

              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 12),
                color: isDanger ? Colors.red[50] : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(dateDisplay, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDanger ? Colors.red : (isActive ? Colors.green[50] : Colors.grey[100]),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              presc['status']!, 
                              style: TextStyle(
                                color: isDanger ? Colors.white : (isActive ? Colors.green : Colors.grey), 
                                fontSize: 10, 
                                fontWeight: FontWeight.bold
                              )
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          CircleAvatar(backgroundColor: isDanger ? Colors.red : Colors.blue, radius: 4),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(presc['patient']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text('${presc['med']} • ${presc['dose']}', style: TextStyle(color: isDanger ? Colors.red[900] : Colors.blue[800])),
                                if (isDanger) 
                                  const Text('⚠️ DOSE OUTSIDE SAFE CLINICAL LIMITS', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          IconButton(onPressed: () {}, icon: const Icon(Icons.print, size: 20)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/dose_calculator'),
        label: const Text('NEW CALCULATION'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
