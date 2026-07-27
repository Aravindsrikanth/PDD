import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:icu_app/backend/state/app_state.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final prescriptions = appState.prescriptions;
    
    // Simple logic to count drug usage
    Map<String, int> drugCounts = {};
    for (var p in prescriptions) {
      String med = p['med'] ?? 'Unknown';
      drugCounts[med] = (drugCounts[med] ?? 0) + 1;
    }

    final sortedDrugs = drugCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: const Text('Medication Analytics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Unit Usage Statistics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Overview of most prescribed medications in this ICU session.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            
            // Usage Cards
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.4,
              ),
              itemCount: sortedDrugs.take(4).length,
              itemBuilder: (context, index) {
                final entry = sortedDrugs[index];
                return _buildStatBox(entry.key, entry.value.toString(), Colors.blue);
              },
            ),
            
            const SizedBox(height: 40),
            const Text('Frequency Chart', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // Custom Bar Chart Representation
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: Column(
                children: sortedDrugs.map((entry) {
                  double percentage = prescriptions.isEmpty ? 0 : entry.value / prescriptions.length;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text('${(percentage * 100).toStringAsFixed(0)}%'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: percentage,
                          backgroundColor: Colors.grey[100],
                          color: Colors.blue[800],
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.blueGrey, fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
