import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:icu_app/backend/models/patient.dart';
import 'package:icu_app/backend/state/app_state.dart';
import 'scoring.dart';

class PatientManagementScreen extends StatefulWidget {
  const PatientManagementScreen({super.key});

  @override
  State<PatientManagementScreen> createState() => _PatientManagementScreenState();
}

class _PatientManagementScreenState extends State<PatientManagementScreen> {
  String _searchQuery = "";
  bool _isGridView = true;

  void _showAddPatientDialog() {
    final nameController = TextEditingController();
    final ageController = TextEditingController();
    final weightController = TextEditingController();
    String? selectedBed;
    String status = 'Stable';

    showDialog(
      context: context,
      builder: (context) {
        final appState = Provider.of<AppState>(context);
        return AlertDialog(
          title: const Text('New ICU Admission'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Patient Name')),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: ageController, decoration: const InputDecoration(labelText: 'Age'), keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: weightController, decoration: const InputDecoration(labelText: 'Weight (kg)'), keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedBed,
                  decoration: const InputDecoration(labelText: 'Assign Bed'),
                  items: appState.availableBeds.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                  onChanged: (v) => selectedBed = v,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: ['Stable', 'Critical', 'Recovering'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => status = v!,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && selectedBed != null) {
                  final newPatient = Patient(
                    id: DateTime.now().toString(),
                    name: nameController.text,
                    age: int.tryParse(ageController.text) ?? 0,
                    bedNumber: selectedBed!,
                    status: status,
                    weight: double.tryParse(weightController.text) ?? 0.0,
                    history: ['Admitted ${DateTime.now().toString().split(' ')[0]}'],
                  );
                  Provider.of<AppState>(context, listen: false).addPatient(newPatient);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Patient ${newPatient.name} admitted successfully')),
                  );
                }
              },
              child: const Text('ADMIT PATIENT'),
            ),
          ],
        );
      },
    );
  }

  void _showUpdateVitalsDialog(Patient p) {
    final sysController = TextEditingController(text: p.systolicBP?.toString());
    final diaController = TextEditingController(text: p.diastolicBP?.toString());
    final hrController = TextEditingController(text: p.heartRate?.toString());
    final biliController = TextEditingController(text: p.bilirubin?.toString());
    final platController = TextEditingController(text: p.platelets?.toString());
    final creatController = TextEditingController(text: p.creatinine?.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clinical Data Update: ${p.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Vitals', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: sysController, decoration: const InputDecoration(labelText: 'Sys BP'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: diaController, decoration: const InputDecoration(labelText: 'Dia BP'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: hrController, decoration: const InputDecoration(labelText: 'HR'), keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Lab Results', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              const SizedBox(height: 8),
              TextField(controller: biliController, decoration: const InputDecoration(labelText: 'Bilirubin (mg/dL)'), keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              TextField(controller: platController, decoration: const InputDecoration(labelText: 'Platelets (x10^3/uL)'), keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              TextField(controller: creatController, decoration: const InputDecoration(labelText: 'Creatinine (mg/dL)'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              Provider.of<AppState>(context, listen: false).updatePatientVitals(
                p.id, 
                sys: double.tryParse(sysController.text), 
                dia: double.tryParse(diaController.text), 
                hr: int.tryParse(hrController.text),
                bili: double.tryParse(biliController.text),
                plat: double.tryParse(platController.text),
                creat: double.tryParse(creatController.text),
              );
              Navigator.pop(context);
            }, 
            child: const Text('SAVE CLINICAL DATA')
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final filteredPatients = appState.patients
        .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                     p.bedNumber.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Management'),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_quilt : Icons.grid_view_rounded),
            onPressed: () => setState(() => _isGridView = !_isGridView),
            tooltip: _isGridView ? 'Switch to Bed Map' : 'Switch to Grid View',
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or bed number...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
        ),
      ),
      body: _isGridView ? _buildGridView(filteredPatients) : _buildBedMap(appState),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPatientDialog,
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildGridView(List<Patient> patients) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: patients.length,
      itemBuilder: (context, index) {
        final p = patients[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue[50],
              child: Text(p.name.isNotEmpty ? p.name[0] : 'U', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
            ),
            title: Text(p.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Bed: ${p.bedNumber} • Age: ${p.age} • Weight: ${p.weight}kg'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(p.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    p.status.toUpperCase(),
                    style: TextStyle(color: _getStatusColor(p.status), fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showPatientDetails(p),
          ),
        );
      },
    );
  }

  Widget _buildBedMap(AppState appState) {
    // Generate a unified list of beds (occupied and available)
    final allBeds = [
      ...appState.patients.map((p) => {'id': p.bedNumber, 'patient': p}),
      ...appState.availableBeds.map((b) => {'id': b, 'patient': null}),
    ]..sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ICU Ward Layout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.2,
              ),
              itemCount: allBeds.length,
              itemBuilder: (context, index) {
                final bed = allBeds[index];
                final patient = bed['patient'] as Patient?;
                final isOccupied = patient != null;

                return GestureDetector(
                  onTap: isOccupied ? () => _showPatientDetails(patient) : _showAddPatientDialog,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isOccupied ? Colors.white : Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isOccupied ? _getStatusColor(patient.status).withValues(alpha: 0.5) : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isOccupied ? Icons.person_pin : Icons.bed_outlined,
                          color: isOccupied ? _getStatusColor(patient.status) : Colors.grey[400],
                          size: 32,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          bed['id'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                        ),
                        if (isOccupied)
                          Text(
                            patient.name,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          )
                        else
                          const Text('Available', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          _buildMapLegend(),
        ],
      ),
    );
  }

  Widget _buildMapLegend() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _legendItem(Colors.red, 'Critical'),
          _legendItem(Colors.green, 'Stable'),
          _legendItem(Colors.grey, 'Empty'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'critical': return Colors.red;
      case 'stable': return Colors.green;
      case 'recovering': return Colors.blue;
      default: return Colors.grey;
    }
  }

  void _showPatientDetails(Patient p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(p.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  _detailRow(Icons.bed, 'Bed Assignment', p.bedNumber),
                  _detailRow(Icons.monitor_weight, 'Weight', '${p.weight} kg'),
                  _detailRow(Icons.favorite, 'Heart Rate', '${p.heartRate ?? "--"} BPM'),
                  _detailRow(Icons.speed, 'Blood Pressure', '${p.systolicBP ?? "--"}/${p.diastolicBP ?? "--"} mmHg'),
                  if (p.map != null) _detailRow(Icons.analytics, 'Calculated MAP', '${p.map!.toStringAsFixed(1)} mmHg'),
                  const Divider(),
                  const Text('Lab Values & Scoring', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 12),
                  _detailRow(Icons.biotech, 'Bilirubin', '${p.bilirubin ?? "--"} mg/dL'),
                  _detailRow(Icons.bloodtype, 'Platelets', '${p.platelets ?? "--"} x10³/µL'),
                  _detailRow(Icons.science, 'Creatinine', '${p.creatinine ?? "--"} mg/dL'),
                  _detailRow(Icons.psychology, 'GCS Score', '${p.gcs ?? "15"}'),
                  const SizedBox(height: 24),
                  const Text('Clinical History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...p.history.reversed.map((h) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.history, size: 16, color: Colors.grey),
                        const SizedBox(width: 10),
                        Expanded(child: Text(h, style: const TextStyle(color: Colors.blueGrey))),
                      ],
                    ),
                  )),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showUpdateVitalsDialog(p), 
                          icon: const Icon(Icons.add_chart, size: 16), 
                          label: const Text('VITALS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold), softWrap: false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            minimumSize: const Size(0, 36),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context, 
                              MaterialPageRoute(builder: (context) => ScoringScreen(initialPatient: p))
                            );
                          }, 
                          icon: const Icon(Icons.assessment_outlined, size: 16), 
                          label: const Text('SCORE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold), softWrap: false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            minimumSize: const Size(0, 36),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/dose_calculator');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D47A1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            minimumSize: const Size(0, 36),
                          ),
                          child: const Text('DOSE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold), softWrap: false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Confirm Discharge'),
                            content: Text('Are you sure you want to discharge ${p.name}?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
                              TextButton(
                                onPressed: () {
                                  Provider.of<AppState>(context, listen: false).dischargePatient(p.id);
                                  Navigator.pop(context); // close dialog
                                  Navigator.pop(context); // close bottom sheet
                                }, 
                                child: const Text('DISCHARGE', style: TextStyle(color: Colors.red))
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.exit_to_app, color: Colors.red),
                      label: const Text('DISCHARGE PATIENT', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Text('$label:', style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value, 
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
