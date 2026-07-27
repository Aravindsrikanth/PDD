import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:icu_app/backend/state/app_state.dart';

class DbConfigScreen extends StatefulWidget {
  const DbConfigScreen({super.key});

  @override
  State<DbConfigScreen> createState() => _DbConfigScreenState();
}

class _DbConfigScreenState extends State<DbConfigScreen> {
  final _appIdController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _regionController = TextEditingController();
  final _dbNameController = TextEditingController();
  final _clusterController = TextEditingController();

  final _twilioSidController = TextEditingController();
  final _twilioTokenController = TextEditingController();
  final _twilioNumController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStoredConfig();
  }

  Future<void> _loadStoredConfig() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _appIdController.text = prefs.getString('mongodb_app_id') ?? '';
      _apiKeyController.text = prefs.getString('mongodb_api_key') ?? '';
      _regionController.text = prefs.getString('mongodb_region') ?? 'ap-south-1';
      _dbNameController.text = prefs.getString('mongodb_db') ?? 'icu_db';
      _clusterController.text = prefs.getString('mongodb_cluster') ?? 'Cluster0';

      _twilioSidController.text = prefs.getString('twilio_sid') ?? '';
      _twilioTokenController.text = prefs.getString('twilio_token') ?? '';
      _twilioNumController.text = prefs.getString('twilio_num') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backend Configuration'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '1. Database (MongoDB Atlas)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _appIdController,
              decoration: const InputDecoration(labelText: 'Atlas App ID', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(labelText: 'Atlas API Key', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _regionController,
                    decoration: const InputDecoration(labelText: 'Region (e.g. us-east-1)', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _clusterController,
                    decoration: const InputDecoration(labelText: 'Cluster Name', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dbNameController,
              decoration: const InputDecoration(labelText: 'Database Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 32),
            const Text(
              '2. SMS Service (Twilio)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE91E63)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your Twilio credentials to send real SMS OTPs.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _twilioSidController,
              decoration: const InputDecoration(labelText: 'Twilio Account SID', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _twilioTokenController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Twilio Auth Token', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _twilioNumController,
              decoration: const InputDecoration(labelText: 'Twilio Phone Number', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), foregroundColor: Colors.white),
                onPressed: () async {
                  final appId = _appIdController.text;
                  final apiKey = _apiKeyController.text;
                  final region = _regionController.text;
                  final dbName = _dbNameController.text;
                  final cluster = _clusterController.text;
                  
                  final sid = _twilioSidController.text;
                  final token = _twilioTokenController.text;
                  final num = _twilioNumController.text;

                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('mongodb_app_id', appId);
                  await prefs.setString('mongodb_api_key', apiKey);
                  await prefs.setString('mongodb_region', region);
                  await prefs.setString('mongodb_db', dbName);
                  await prefs.setString('mongodb_cluster', cluster);
                  
                  await prefs.setString('twilio_sid', sid);
                  await prefs.setString('twilio_token', token);
                  await prefs.setString('twilio_num', num);
                  
                  if (!mounted) return;
                  
                  final appState = Provider.of<AppState>(context, listen: false);
                  appState.updateMongoConfig(appId, apiKey, region: region, dataSource: cluster, database: dbName);
                  appState.updateSmsConfig(sid, token, num);
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Configuration saved! SMS & Database ready.'))
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('SAVE ALL SETTINGS', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
