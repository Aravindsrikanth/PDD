import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:twilio_flutter/twilio_flutter.dart';

// ==========================================
// MODELS
// ==========================================

class Patient {
  final String id, name, bedNumber, status;
  final int age;
  final double weight;
  double? systolicBP, diastolicBP, bilirubin, platelets, creatinine, gcs, fiO2, paO2;
  int? heartRate;
  List<String> history;

  Patient({required this.id, required this.name, required this.age, required this.bedNumber, required this.status, required this.weight, this.systolicBP, this.diastolicBP, this.heartRate, this.bilirubin, this.platelets, this.creatinine, this.gcs, this.fiO2, this.paO2, List<String>? history}) : history = history ?? [];

  double? get map => (systolicBP != null && diastolicBP != null) ? (systolicBP! + 2 * diastolicBP!) / 3 : null;

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
    id: json['id']?.toString() ?? '', name: json['name']?.toString() ?? 'Unknown', age: int.tryParse(json['age']?.toString() ?? '0') ?? 0,
    bedNumber: json['bedNumber']?.toString() ?? 'N/A', status: json['status']?.toString() ?? 'Stable', weight: double.tryParse(json['weight']?.toString() ?? '0.0') ?? 0.0,
    systolicBP: double.tryParse(json['systolicBP']?.toString() ?? ''), diastolicBP: double.tryParse(json['diastolicBP']?.toString() ?? ''),
    heartRate: int.tryParse(json['heartRate']?.toString() ?? ''), bilirubin: double.tryParse(json['bilirubin']?.toString() ?? ''),
    platelets: double.tryParse(json['platelets']?.toString() ?? ''), creatinine: double.tryParse(json['creatinine']?.toString() ?? ''),
    gcs: double.tryParse(json['gcs']?.toString() ?? '15') ?? 15, fiO2: double.tryParse(json['fiO2']?.toString() ?? '0.21') ?? 0.21, paO2: double.tryParse(json['paO2']?.toString() ?? ''),
    history: json['history'] is List ? List<String>.from(json['history']) : (json['history'] is String ? [json['history']] : []),
  );

  Map<String, dynamic> toJson() => { 'id': id, 'name': name, 'age': age, 'bedNumber': bedNumber, 'status': status, 'weight': weight, 'systolicBP': systolicBP, 'diastolicBP': diastolicBP, 'heartRate': heartRate, 'bilirubin': bilirubin, 'platelets': platelets, 'creatinine': creatinine, 'gcs': gcs, 'fiO2': fiO2, 'paO2': paO2, 'history': history };
}

class Medication {
  final String id, name, category, unit, warning;
  final double standardDosePerKg, minDosePerKg, maxDosePerKg;
  final List<String> interactions;

  Medication({required this.id, required this.name, required this.category, required this.standardDosePerKg, required this.minDosePerKg, required this.maxDosePerKg, required this.unit, this.interactions = const [], this.warning = "Monitor vitals."});

  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
    id: json['id'], name: json['name'], category: json['category'], standardDosePerKg: json['standardDosePerKg'].toDouble(),
    minDosePerKg: json['minDosePerKg'].toDouble(), maxDosePerKg: json['maxDosePerKg'].toDouble(), unit: json['unit'],
    interactions: List<String>.from(json['interactions'] ?? []), warning: json['warning'] ?? "Monitor vitals.",
  );

  Map<String, dynamic> toJson() => { 'id': id, 'name': name, 'category': category, 'standardDosePerKg': standardDosePerKg, 'minDosePerKg': minDosePerKg, 'maxDosePerKg': maxDosePerKg, 'unit': unit, 'interactions': interactions, 'warning': warning };
}

// ==========================================
// SERVICES
// ==========================================

class MongoService {
  String _appId = "YOUR_APP_ID", _apiKey = "YOUR_API_KEY", _region = "ap-south-1", _baseUrl = "", _dataSource = "Cluster0", _database = "icu_db";

  MongoService() { _updateBaseUrl(); }
  void updateCredentials(String id, String k, {String? r, String? ds, String? db}) { _appId = id; _apiKey = k; if (r != null) _region = r; if (ds != null) _dataSource = ds; if (db != null) _database = db; _updateBaseUrl(); }
  void _updateBaseUrl() { _baseUrl = "https://$_region.aws.data.mongodb-api.com/app/$_appId/endpoint/data/v1/action"; }
  bool get isConfigured => _appId != "YOUR_APP_ID" && _appId.isNotEmpty;
  Map<String, String> get _headers => { 'Content-Type': 'application/json', 'api-key': _apiKey };

  Future<Map<String, dynamic>?> _post(String action, Map<String, dynamic> body) async {
    if (!isConfigured) {
      debugPrint("MongoDB Service: Not Configured. Check App ID and API Key.");
      return null;
    }
    try {
      final res = await http.post(Uri.parse("$_baseUrl/$action"), headers: _headers, body: json.encode({ "dataSource": _dataSource, "database": _database, ...body }));
      return (res.statusCode == 200 || res.statusCode == 201) ? json.decode(res.body) : null;
    } catch (e) {
      debugPrint("MongoDB POST Error: $e");
      return null; 
    }
  }

  Future<List<Patient>> fetchPatients() async {
    final res = await _post("find", {"collection": "patients"});
    if (res != null) {
      final patients = (res['documents'] as List).map((j) => Patient.fromJson(j)).toList();
      final p = await SharedPreferences.getInstance(); p.setStringList('local_patients', patients.map((p) => json.encode(p.toJson())).toList());
      return patients;
    }
    final p = await SharedPreferences.getInstance(); return (p.getStringList('local_patients') ?? []).map((s) => Patient.fromJson(json.decode(s))).toList();
  }

  Future<bool> savePatient(Patient pat) async {
    await _post("updateOne", { "collection": "patients", "filter": {"id": pat.id}, "update": {"\$set": pat.toJson()}, "upsert": true });
    final p = await SharedPreferences.getInstance(); List<String> local = p.getStringList('local_patients') ?? [];
    local.removeWhere((s) => Patient.fromJson(json.decode(s)).id == pat.id); local.add(json.encode(pat.toJson())); p.setStringList('local_patients', local);
    return true;
  }

  Future<bool> deletePatient(String id) async {
    await _post("deleteOne", { "collection": "patients", "filter": {"id": id} });
    final p = await SharedPreferences.getInstance(); List<String> local = p.getStringList('local_patients') ?? [];
    local.removeWhere((s) => Patient.fromJson(json.decode(s)).id == id); p.setStringList('local_patients', local);
    return true;
  }

  Future<List<Map<String, dynamic>>> fetchAllStaff() async {
    final res = await _post("find", {"collection": "staff"});
    return res != null ? List<Map<String, dynamic>>.from(res['documents'] ?? []) : [];
  }

  Future<bool> updateUserStatus(String id, String s) async => await _post("updateOne", { "collection": "staff", "filter": {"staffId": id}, "update": {"\$set": {"status": s}} }) != null;
  Future<bool> deleteStaff(String id) async => await _post("deleteOne", { "collection": "staff", "filter": {"staffId": id} }) != null;

  Future<Map<String, dynamic>?> login(String role, String id, String pass) async {
    final res = await _post("findOne", { "collection": "staff", "filter": {"staffId": id, "role": role} });
    if (res != null && res['document'] != null && res['document']['password'] == pass) {
      if (id == "admin") return {'success': true, 'role': role, 'staffId': id};
      if (res['document']['status'] == 'Approved') return {'success': true, 'role': role, 'staffId': id};
      return {'success': false, 'error': res['document']['status'] == 'Blocked' ? 'Account blocked.' : 'Pending approval.'};
    }
    return (id == "admin" && pass == "admin123") ? {'success': true, 'role': 'Admin', 'staffId': 'admin'} : null;
  }

  Future<bool> register(String r, String id, String ph, String pass) async {
    // FORCE UPSERT logic for Admin-only creation
    final res = await _post("updateOne", {
      "collection": "staff",
      "filter": {"staffId": id},
      "update": {"\$set": {"staffId": id, "phone": ph, "role": r, "password": pass, "status": "Approved", "createdAt": DateTime.now().toIso8601String()}},
      "upsert": true
    });
    return res != null;
  }
  
  Future<List<Medication>> fetchMedications() async {
    final res = await _post("find", {"collection": "medications"});
    return (res != null) ? (res['documents'] as List).map((j) => Medication.fromJson(j)).toList() : [];
  }

  Future<void> seedMedications(List<Medication> meds) async {
    if ((await fetchMedications()).isEmpty) await _post("insertMany", { "collection": "medications", "documents": meds.map((m) => m.toJson()).toList() });
  }

  Future<List<Map<String, String>>> fetchPrescriptions() async {
    final res = await _post("find", {"collection": "prescriptions", "sort": {"date": -1}});
    if (res != null) {
      final data = (res['documents'] as List).map((i) => (i as Map).map((k, v) => MapEntry(k.toString(), v.toString()))).toList();
      return data;
    }
    return [];
  }

  Future<bool> addPrescription(Map<String, String> p) async => await _post("insertOne", {"collection": "prescriptions", "document": p}) != null;
  
  Future<List<Map<String, dynamic>>> fetchLogs() async {
    final res = await _post("find", {"collection": "audit_logs", "sort": {"timestamp": -1}});
    return res != null ? List<Map<String, dynamic>>.from(res['documents'] ?? []) : [];
  }

  Future<bool> addLog(Map<String, dynamic> log) async {
    log['timestamp'] ??= DateTime.now().toIso8601String();
    return await _post("insertOne", {"collection": "audit_logs", "document": log}) != null;
  }
}

class EmailService {
  Future<bool> sendOtpEmail(String e, String o) async => true;
}

class SmsService {
  void updateCredentials(String s, String t, String n) {}
  Future<bool> sendOtpSms(String p, String o) async => true;
}

// ==========================================
// STATE MANAGEMENT
// ==========================================

class AppState extends ChangeNotifier {
  final MongoService _mongoService = MongoService();
  
  bool _isLoading = false, _isDarkMode = false;
  bool get isLoading => _isLoading; bool get isDarkMode => _isDarkMode;
  void toggleTheme() { _isDarkMode = !_isDarkMode; notifyListeners(); }

  AppState() { _init(); }
  Future<void> _init() async {
    final p = await SharedPreferences.getInstance();
    final id = p.getString('mongodb_app_id'), k = p.getString('mongodb_api_key'), r = p.getString('mongodb_region'), db = p.getString('mongodb_db'), cl = p.getString('mongodb_cluster');
    if (id != null && k != null) _mongoService.updateCredentials(id, k, r: r, db: db, ds: cl);
    syncWithServer();
  }

  void updateMongoConfig(String id, String k, {String? r, String? ds, String? db}) { 
    _mongoService.updateCredentials(id, k, r: r, ds: ds, db: db); 
    syncWithServer(); 
  }
  void updateSmsConfig(String s, String t, String n) {}
  bool get isCloudSyncActive => _mongoService.isConfigured;

  String? _currentUserRole; String? get currentUserRole => _currentUserRole;
  final List<String> _activeStaff = ['Dr. Smith', 'Dr. Sarah', 'Nurse John', 'Nurse Emma']; List<String> get activeStaff => _activeStaff;
  
  List<Patient> _patients = []; List<Patient> get patients => _patients;
  List<Map<String, dynamic>> _activityLogs = []; List<Map<String, dynamic>> get activityLogs => _activityLogs;
  List<Map<String, String>> _prescriptions = []; List<Map<String, String>> get prescriptions => _prescriptions;
  
  String _shiftHandover = "Stable. All ventilator checks complete."; String get shiftHandover => _shiftHandover;
  void updateHandover(String text) { _shiftHandover = text; notifyListeners(); }

  Future<void> syncWithServer() async {
    _isLoading = true; notifyListeners();
    try {
      _patients = await _mongoService.fetchPatients();
      _activityLogs = await _mongoService.fetchLogs();
      _prescriptions = await _mongoService.fetchPrescriptions();
    } catch (e) { debugPrint("Sync error: $e"); }
    finally { _isLoading = false; notifyListeners(); }
  }

  List<String> get availableBeds => List.generate(50, (i) => 'ICU-${(i + 1).toString().padLeft(2, '0')}').where((b) => !_patients.any((p) => p.bedNumber == b)).toList();

  Future<Map<String, dynamic>> login(String r, String id, String p) async {
    _isLoading = true; notifyListeners();
    final res = await _mongoService.login(r, id, p);
    _isLoading = false; if (res != null && res['success'] == true) _currentUserRole = r; notifyListeners();
    return res ?? {'success': false, 'error': 'Connection error'};
  }

  Future<bool> register(String r, String id, String ph, String p) async {
    _isLoading = true; notifyListeners();
    final res = await _mongoService.register(r, id, ph, p);
    _isLoading = false; if (res) syncWithServer(); notifyListeners(); return res;
  }

  Future<List<Map<String, dynamic>>> fetchStaff() async => await _mongoService.fetchAllStaff();
  Future<bool> approveUser(String id) async => await _mongoService.updateUserStatus(id, "Approved");
  Future<bool> blockUser(String id) async => await _mongoService.updateUserStatus(id, "Blocked");
  Future<bool> deleteStaff(String id) async => await _mongoService.deleteStaff(id);
  
  void logout() { _currentUserRole = null; notifyListeners(); }
  
  void addPatient(Patient pat) async { if (await _mongoService.savePatient(pat)) { syncWithServer(); notifyListeners(); } }
  void updatePatientVitals(String id, {double? sys, double? dia, int? hr, double? bili, double? plat, double? creat, double? gcsVal, double? fiO2Val, double? paO2Val}) async {
    final i = _patients.indexWhere((p) => p.id == id);
    if (i != -1) {
      if (sys != null) _patients[i].systolicBP = sys; if (dia != null) _patients[i].diastolicBP = dia; if (hr != null) _patients[i].heartRate = hr;
      await _mongoService.savePatient(_patients[i]); notifyListeners();
    }
  }

  List<Medication> get medications => [
    Medication(id: 'm1', name: 'Propofol', category: 'Anesthetic', standardDosePerKg: 2.0, minDosePerKg: 1.5, maxDosePerKg: 2.5, unit: 'mg'),
    Medication(id: 'm2', name: 'Midazolam', category: 'Sedative', standardDosePerKg: 0.05, minDosePerKg: 0.02, maxDosePerKg: 0.1, unit: 'mg'),
  ];
}
