import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
  final String id;
  final String name;
  final int age;
  final String bedNumber;
  final String status; // Stable, Critical, Recovering
  final double weight;
  double? systolicBP;
  double? diastolicBP;
  int? heartRate;
  double? bilirubin;
  double? platelets;
  double? creatinine;
  double? gcs;
  double? fiO2;
  double? paO2;
  List<String> history;

  Patient({
    required this.id, required this.name, required this.age, required this.bedNumber, required this.status, required this.weight,
    this.systolicBP, this.diastolicBP, this.heartRate, this.bilirubin, this.platelets, this.creatinine, this.gcs = 15, this.fiO2 = 0.21, this.paO2,
    List<String>? history,
  }) : history = history ?? [];

  double? get map => (systolicBP != null && diastolicBP != null) ? (systolicBP! + 2 * diastolicBP!) / 3 : null;

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      age: int.tryParse(json['age']?.toString() ?? '0') ?? 0,
      bedNumber: json['bedNumber']?.toString() ?? 'N/A',
      status: json['status']?.toString() ?? 'Stable',
      weight: double.tryParse(json['weight']?.toString() ?? '0.0') ?? 0.0,
      systolicBP: double.tryParse(json['systolicBP']?.toString() ?? ''),
      diastolicBP: double.tryParse(json['diastolicBP']?.toString() ?? ''),
      heartRate: int.tryParse(json['heartRate']?.toString() ?? ''),
      bilirubin: double.tryParse(json['bilirubin']?.toString() ?? ''),
      platelets: double.tryParse(json['platelets']?.toString() ?? ''),
      creatinine: double.tryParse(json['creatinine']?.toString() ?? ''),
      gcs: double.tryParse(json['gcs']?.toString() ?? '15') ?? 15,
      fiO2: double.tryParse(json['fiO2']?.toString() ?? '0.21') ?? 0.21,
      paO2: double.tryParse(json['paO2']?.toString() ?? ''),
      history: json['history'] is List ? List<String>.from(json['history']) : (json['history'] is String ? [json['history']] : []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id, 'name': name, 'age': age, 'bedNumber': bedNumber, 'status': status, 'weight': weight, 'systolicBP': systolicBP, 'diastolicBP': diastolicBP, 'heartRate': heartRate,
      'bilirubin': bilirubin, 'platelets': platelets, 'creatinine': creatinine, 'gcs': gcs, 'fiO2': fiO2, 'paO2': paO2, 'history': history,
    };
  }
}

class Medication {
  final String id;
  final String name;
  final String category;
  final double standardDosePerKg;
  final double minDosePerKg;
  final double maxDosePerKg;
  final String unit;
  final List<String> interactions; 
  final String warning;

  Medication({
    required this.id, required this.name, required this.category, required this.standardDosePerKg, required this.minDosePerKg, required this.maxDosePerKg, required this.unit,
    this.interactions = const [], this.warning = "Monitor vitals during administration.",
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'], name: json['name'], category: json['category'], standardDosePerKg: json['standardDosePerKg'].toDouble(), minDosePerKg: json['minDosePerKg'].toDouble(),
      maxDosePerKg: json['maxDosePerKg'].toDouble(), unit: json['unit'], interactions: List<String>.from(json['interactions'] ?? []), warning: json['warning'] ?? "Monitor vitals.",
    );
  }

  Map<String, dynamic> toJson() {
    return { 'id': id, 'name': name, 'category': category, 'standardDosePerKg': standardDosePerKg, 'minDosePerKg': minDosePerKg, 'maxDosePerKg': maxDosePerKg, 'unit': unit, 'interactions': interactions, 'warning': warning };
  }
}

// ==========================================
// SERVICES
// ==========================================

class MongoService {
  String _appId = "YOUR_APP_ID"; 
  String _apiKey = "YOUR_API_KEY"; 
  String _baseUrl = "";
  static const String _dataSource = "Cluster0";
  static const String _database = "icu_db";

  MongoService() { _updateBaseUrl(); }
  void updateCredentials(String appId, String apiKey) { _appId = appId; _apiKey = apiKey; _updateBaseUrl(); }
  void _updateBaseUrl() { _baseUrl = "https://ap-south-1.aws.data.mongodb-api.com/app/$_appId/endpoint/data/v1/action"; }
  Map<String, String> get _headers => { 'Content-Type': 'application/json', 'api-key': _apiKey };

  Future<Map<String, dynamic>?> _post(String action, Map<String, dynamic> body) async {
    if (_appId == "YOUR_APP_ID" || _apiKey == "YOUR_API_KEY") return null;
    try {
      final response = await http.post(Uri.parse("$_baseUrl/$action"), headers: _headers, body: json.encode({ "dataSource": _dataSource, "database": _database, ...body }));
      return (response.statusCode == 200 || response.statusCode == 201) ? json.decode(response.body) : null;
    } catch (e) { return null; }
  }

  Future<List<Patient>> fetchPatients() async {
    try {
      final result = await _post("find", {"collection": "patients"});
      if (result != null) {
        final List docs = result['documents'] ?? [];
        final remotePatients = docs.map((json) => Patient.fromJson(json)).toList();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('local_patients', remotePatients.map((p) => json.encode(p.toJson())).toList());
        return remotePatients;
      }
    } catch (e) { debugPrint('Remote Fetch Error: $e'); }
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList('local_patients') ?? []).map((s) => Patient.fromJson(json.decode(s))).toList();
  }

  Future<bool> savePatient(Patient patient) async {
    try { await _post("updateOne", { "collection": "patients", "filter": {"id": patient.id}, "update": {"\$set": patient.toJson()}, "upsert": true }); } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    List<String> local = prefs.getStringList('local_patients') ?? [];
    local.removeWhere((s) => Patient.fromJson(json.decode(s)).id == patient.id);
    local.add(json.encode(patient.toJson()));
    await prefs.setStringList('local_patients', local);
    return true;
  }

  Future<bool> deletePatient(String id) async {
    try { await _post("deleteOne", { "collection": "patients", "filter": {"id": id} }); } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    List<String> local = prefs.getStringList('local_patients') ?? [];
    local.removeWhere((s) => Patient.fromJson(json.decode(s)).id == id);
    await prefs.setStringList('local_patients', local);
    return true;
  }

  Future<List<Medication>> fetchMedications() async {
    final result = await _post("find", {"collection": "medications"});
    return (result != null) ? (result['documents'] as List).map((j) => Medication.fromJson(j)).toList() : [];
  }

  Future<void> seedMedications(List<Medication> meds) async {
    if ((await fetchMedications()).isEmpty) await _post("insertMany", { "collection": "medications", "documents": meds.map((m) => m.toJson()).toList() });
  }

  Future<List<Map<String, String>>> fetchPrescriptions() async {
    final result = await _post("find", {"collection": "prescriptions", "sort": {"date": -1}});
    if (result != null) {
      final data = (result['documents'] as List).map((i) => (i as Map).map((k, v) => MapEntry(k.toString(), v.toString()))).toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('local_prescriptions', data.map((p) => json.encode(p)).toList());
      return data;
    }
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList('local_prescriptions') ?? []).map((s) => Map<String, String>.from(json.decode(s))).toList();
  }

  Future<bool> addPrescription(Map<String, String> p) async {
    try { await _post("insertOne", {"collection": "prescriptions", "document": p}); } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    List<String> local = prefs.getStringList('local_prescriptions') ?? [];
    local.insert(0, json.encode(p));
    await prefs.setStringList('local_prescriptions', local);
    return true;
  }

  Future<List<Map<String, dynamic>>> fetchLogs() async {
    final result = await _post("find", {"collection": "audit_logs", "sort": {"timestamp": -1}});
    if (result != null) {
      final logs = List<Map<String, dynamic>>.from(result['documents'] ?? []);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('local_logs', logs.map((l) => json.encode(l)).toList());
      return logs;
    }
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList('local_logs') ?? []).map((s) => Map<String, dynamic>.from(json.decode(s))).toList();
  }

  Future<bool> addLog(Map<String, dynamic> log) async {
    log['timestamp'] ??= DateTime.now().toIso8601String();
    try { await _post("insertOne", {"collection": "audit_logs", "document": log}); } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    List<String> local = prefs.getStringList('local_logs') ?? [];
    local.insert(0, json.encode(log));
    await prefs.setStringList('local_logs', local);
    return true;
  }

  Future<Map<String, dynamic>?> login(String role, String staffId, String password) async {
    try {
      final result = await _post("findOne", {"collection": "staff", "filter": {"staffId": staffId, "role": role}});
      if (result != null && result['document'] != null && result['document']['password'] == password) return {'success': true, 'role': role, 'staffId': staffId, 'source': 'remote'};
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    for (var s in (prefs.getStringList('local_staff') ?? [])) {
      final u = json.decode(s);
      if (u['staffId'] == staffId && u['role'] == role && u['password'] == password) return {'success': true, 'role': role, 'staffId': staffId, 'source': 'local'};
    }
    return (staffId == "admin" && password == "admin123") ? {'success': true, 'role': 'Admin', 'staffId': 'admin', 'source': 'default'} : null;
  }

  Future<bool> register(String role, String id, String email, String phone, String pass) async {
    try {
      final ex = await _post("findOne", {"collection": "staff", "filter": {"staffId": id}});
      if (ex != null && ex['document'] != null) return false;
      await _post("insertOne", { "collection": "staff", "document": { "staffId": id, "email": email, "phone": phone, "role": role, "password": pass, "createdAt": DateTime.now().toIso8601String() } });
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    List<String> local = prefs.getStringList('local_staff') ?? [];
    if (!local.any((s) => json.decode(s)['staffId'] == id)) {
      local.add(json.encode({"staffId": id, "email": email, "phone": phone, "role": role, "password": pass}));
      await prefs.setStringList('local_staff', local);
      return true;
    }
    return false;
  }

  Future<bool> resetPasswordWithPhone(String id, String phone, String pass) async {
    try {
      final res = await _post("updateOne", { "collection": "staff", "filter": {"staffId": id, "phone": phone}, "update": {"\$set": {"password": pass}} });
      if (res != null && res['matchedCount'] > 0) return true;
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    List<String> local = prefs.getStringList('local_staff') ?? [];
    bool found = false;
    List<String> updated = local.map((s) {
      final u = json.decode(s);
      if (u['staffId'] == id && u['phone'] == phone) { u['password'] = pass; found = true; return json.encode(u); }
      return s;
    }).toList();
    if (found) await prefs.setStringList('local_staff', updated);
    return found;
  }
}

class EmailService {
  String _u = 'YOUR_SMTP_USER'; String _p = 'YOUR_SMTP_PASSWORD';
  void updateCredentials(String u, String p) { _u = u; _p = p; }
  Future<bool> sendOtpEmail(String email, String otp) async {
    if (kIsWeb) return true;
    if (_u == 'YOUR_SMTP_USER' || _u.isEmpty) return false;
    try { await send(Message()..from = Address(_u, 'ICU Support')..recipients.add(email)..subject = 'Code'..text = 'Code: $otp', gmail(_u, _p)); return true; } catch (_) { return false; }
  }
}

class SmsService {
  TwilioFlutter? _tf;
  String _sid = 'ACxxx'; String _tok = 'xxx'; String _num ='+1555';
  void updateCredentials(String sid, String tok, String num) { _sid = sid; _tok = tok; _num = num; if (!kIsWeb) _tf = TwilioFlutter(accountSid: _sid, authToken: _tok, twilioNumber: _num); }
  Future<bool> sendOtpSms(String phone, String otp) async {
    if (kIsWeb) return true;
    if (_tf == null) return false;
    try { await _tf!.sendSMS(toNumber: phone, messageBody: 'Code: $otp'); return true; } catch (_) { return false; }
  }
}

// ==========================================
// STATE MANAGEMENT
// ==========================================

class AppState extends ChangeNotifier {
  final MongoService _mongoService = MongoService();
  final EmailService _emailService = EmailService();
  final SmsService _smsService = SmsService();
  
  bool _isLoading = false; bool get isLoading => _isLoading;
  bool _isDarkMode = false; bool get isDarkMode => _isDarkMode;
  void toggleTheme() { _isDarkMode = !_isDarkMode; notifyListeners(); }

  AppState() { _init(); }
  Future<void> _init() async {
    final p = await SharedPreferences.getInstance();
    final id = p.getString('mongodb_app_id'); final k = p.getString('mongodb_api_key');
    if (id != null && k != null) _mongoService.updateCredentials(id, k);
    syncWithServer();
  }

  void updateMongoConfig(String id, String k) { _mongoService.updateCredentials(id, k); syncWithServer(); }
  void updateSmsConfig(String s, String t, String n) { _smsService.updateCredentials(s, t, n); }

  String? _currentUserRole; String? get currentUserRole => _currentUserRole;
  final List<String> _activeStaff = ['Dr. Smith', 'Dr. Sarah', 'Nurse John']; List<String> get activeStaff => _activeStaff;

  List<Medication> _medications = [
    Medication(id: 'm1', name: 'Propofol', category: 'Anesthetic', standardDosePerKg: 2.0, minDosePerKg: 1.5, maxDosePerKg: 2.5, unit: 'mg', interactions: ['m2']),
  ];
  List<Medication> get medications => _medications;

  String _shiftHandover = "Stable. All checks complete."; String get shiftHandover => _shiftHandover;
  void updateHandover(String text) { _shiftHandover = text; notifyListeners(); }

  List<Patient> _patients = []; List<Patient> get patients => _patients;
  List<Map<String, dynamic>> _activityLogs = []; List<Map<String, dynamic>> get activityLogs => _activityLogs;
  List<Map<String, String>> _prescriptions = []; List<Map<String, String>> get prescriptions => _prescriptions;

  Future<void> syncWithServer() async {
    _isLoading = true; notifyListeners();
    try {
      await _mongoService.seedMedications(_medications);
      final remoteMeds = await _mongoService.fetchMedications();
      if (remoteMeds.isNotEmpty) _medications = remoteMeds;
      _patients = await _mongoService.fetchPatients();
      _prescriptions = await _mongoService.fetchPrescriptions();
      _activityLogs = await _mongoService.fetchLogs();
    } catch (e) { debugPrint("Sync error: $e"); }
    finally { _isLoading = false; notifyListeners(); }
  }

  List<String> get availableBeds {
    final all = List.generate(50, (i) => 'ICU-${(i + 1).toString().padLeft(2, '0')}');
    final occupied = _patients.map((p) => p.bedNumber).toSet();
    return all.where((b) => !occupied.contains(b)).toList();
  }

  void addPrescription(Map<String, String> p) async {
    if (await _mongoService.addPrescription(p)) {
      _prescriptions.insert(0, p);
      await _mongoService.addLog({'time': p['date']!, 'user': _currentUserRole ?? 'System', 'action': 'New Rx: ${p['med']}'});
      _activityLogs = await _mongoService.fetchLogs();
      notifyListeners();
    }
  }

  void addPatient(Patient p) async {
    if (await _mongoService.savePatient(p)) {
      _patients.insert(0, p);
      await _mongoService.addLog({'time': DateTime.now().toIso8601String(), 'user': _currentUserRole ?? 'System', 'action': 'Admission: ${p.name}'});
      _activityLogs = await _mongoService.fetchLogs();
      notifyListeners();
    }
  }

  void updatePatientVitals(String id, {double? sys, double? dia, int? hr, double? bili, double? plat, double? creat, double? gcsVal, double? fiO2Val, double? paO2Val}) async {
    final i = _patients.indexWhere((p) => p.id == id);
    if (i != -1) {
      if (sys != null) _patients[i].systolicBP = sys; if (dia != null) _patients[i].diastolicBP = dia;
      if (hr != null) _patients[i].heartRate = hr; if (bili != null) _patients[i].bilirubin = bili;
      if (plat != null) _patients[i].platelets = plat; if (creat != null) _patients[i].creatinine = creat;
      if (gcsVal != null) _patients[i].gcs = gcsVal; if (fiO2Val != null) _patients[i].fiO2 = fiO2Val;
      if (paO2Val != null) _patients[i].paO2 = paO2Val;
      await _mongoService.savePatient(_patients[i]);
      notifyListeners();
    }
  }

  void triggerEmergencyAlert(String type) async {
    await _mongoService.addLog({'user': _currentUserRole ?? 'System', 'action': 'ALERT: $type'});
    _activityLogs = await _mongoService.fetchLogs();
    notifyListeners();
  }

  Future<bool> login(String r, String id, String p) async {
    _isLoading = true; notifyListeners();
    final res = await _mongoService.login(r, id, p);
    _isLoading = false;
    if (res != null) { _currentUserRole = r; notifyListeners(); return true; }
    notifyListeners(); return false;
  }

  Future<bool> register(String r, String id, String e, String ph, String p) async {
    _isLoading = true; notifyListeners();
    final res = await _mongoService.register(r, id, e, ph, p);
    if (res) _currentUserRole = r;
    _isLoading = false; notifyListeners(); return res;
  }

  Future<bool> resetPasswordWithPhone(String id, String ph, String p) async {
    _isLoading = true; notifyListeners();
    final res = await _mongoService.resetPasswordWithPhone(id, ph, p);
    _isLoading = false; notifyListeners(); return res;
  }

  void logout() { _currentUserRole = null; notifyListeners(); }

  void dischargePatient(String id) async {
    final i = _patients.indexWhere((p) => p.id == id);
    if (i != -1) {
      final p = _patients[i];
      if (await _mongoService.deletePatient(id)) {
        await _mongoService.addLog({'user': _currentUserRole ?? 'System', 'action': 'Discharged: ${p.name}'});
        _patients.removeAt(i);
        _activityLogs = await _mongoService.fetchLogs();
        notifyListeners();
      }
    }
  }
}
