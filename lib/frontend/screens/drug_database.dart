import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:icu_app/backend/state/app_state.dart';

class DrugDatabaseScreen extends StatefulWidget {
  const DrugDatabaseScreen({super.key});

  @override
  State<DrugDatabaseScreen> createState() => _DrugDatabaseScreenState();
}

class _DrugDatabaseScreenState extends State<DrugDatabaseScreen> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final medications = Provider.of<AppState>(context).medications
        .where((m) => m.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                     m.category.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinical Drug Reference'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search drug name or category...',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: medications.length,
        itemBuilder: (context, index) {
          final med = medications[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue[50],
                child: const Icon(Icons.medication, color: Colors.blue),
              ),
              title: Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(med.category),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow('Standard Dose', '${med.standardDosePerKg} ${med.unit}/kg'),
                      _infoRow('Safety Range', '${med.minDosePerKg} - ${med.maxDosePerKg} ${med.unit}/kg'),
                      const SizedBox(height: 8),
                      const Text('Clinical Warning:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 12)),
                      Text(med.warning, style: const TextStyle(fontStyle: FontStyle.italic)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/dose_calculator'),
                        child: const Text('CALCULATE DOSE'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
