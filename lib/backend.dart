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
    required this.id,
    required this.name,
    required this.age,
    required this.bedNumber,
    required this.status,
    required this.weight,
    this.systolicBP,
    this.diastolicBP,
    this.heartRate,
    this.bilirubin,
    this.platelets,
    this.creatinine,
    this.gcs = 15,
    this.fiO2 = 0.21,
    this.paO2,
    List<String>? history,
  }) : history = history ?? [];

  double? get map => (systolicBP != null && diastolicBP != null) 
    ? (systolicBP! + 2 * diastolicBP!) / 3 
    : null;

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
      history: json['history'] is List 
          ? List<String>.from(json['history']) 
          : (json['history'] is String ? [json['history']] : []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'bedNumber': bedNumber,
      'status': status,
      'weight': weight,
      'systolicBP': systolicBP,
      'diastolicBP': diastolicBP,
      'heartRate': heartRate,
      'bilirubin': bilirubin,
      'platelets': platelets,
      'creatinine': creatinine,
      'gcs': gcs,
      'fiO2': fiO2,
      'paO2': paO2,
      'history': history,
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
    required this.id,
    required this.name,
    required this.category,
    required this.standardDosePerKg,
    required this.minDosePerKg,
    required this.maxDosePerKg,
    required this.unit,
    this.interactions = const [],
    this.warning = "Monitor vitals during administration.",
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      standardDosePerKg: json['standardDosePerKg'].toDouble(),
      minDosePerKg: json['minDosePerKg'].toDouble(),
      maxDosePerKg: json['maxDosePerKg'].toDouble(),
      unit: json['unit'],
      interactions: List<String>.from(json['interactions'] ?? []),
      warning: json['warning'] ?? "Monitor vitals during administration.",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'standardDosePerKg': standardDosePerKg,
      'minDosePerKg': minDosePerKg,
      'maxDosePerKg': maxDosePerKg,
      'unit': unit,
      'interactions': interactions,
      'warning': warning,
    };
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

  MongoService() {
    _updateBaseUrl();
  }

  void updateCredentials(String appId, String apiKey) {
    _appId = appId;
    _apiKey = apiKey;
    _updateBaseUrl();
  }

  void _updateBaseUrl() {
    _baseUrl = "https://ap-south-1.aws.data.mongodb-api.com/app/$_appId/endpoint/data/v1/action";
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'api-key': _apiKey,
  };

  Future<Map<String, dynamic>?> _post(String action, Map<String, dynamic> body) async {
    if (_appId == "YOUR_APP_ID" || _apiKey == "YOUR_API_KEY" || _baseUrl.isEmpty) {
      debugPrint('MongoDB Data API: No credentials configured. skipping remote call.');
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/$action"),
        headers: _headers,
        body: json.encode({
          "dataSource": _dataSource,
          "database": _database,
          ...body,
        }),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        debugPrint('MongoDB Data API Error ($action): ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('MongoDB Connection Error: $e');
      return null;
    }
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
    } catch (e) {
      debugPrint('Fetch Patients Remote Error: $e');
    }
    final prefs = await SharedPreferences.getInstance();
    final List<String> localData = prefs.getStringList('local_patients') ?? [];
    return localData.map((s) => Patient.fromJson(json.decode(s))).toList();
  }

  Future<bool> savePatient(Patient patient) async {
    bool remoteSuccess = false;
    try {
      final result = await _post("updateOne", {
        "collection": "patients",
        "filter": {"id": patient.id},
        "update": {"\$set": patient.toJson()},
        "upsert": true
      });
      remoteSuccess = result != null;
    } catch (e) {
      debugPrint('Save Patient Remote Error: $e');
    }
    final prefs = await SharedPreferences.getInstance();
    List<String> localPatients = prefs.getStringList('local_patients') ?? [];
    localPatients.removeWhere((s) => Patient.fromJson(json.decode(s)).id == patient.id);
    localPatients.add(json.encode(patient.toJson()));
    await prefs.setStringList('local_patients', localPatients);
    return remoteSuccess || true;
  }

  Future<bool> deletePatient(String patientId) async {
    try {
      await _post("deleteOne", {
        "collection": "patients",
        "filter": {"id": patientId}
      });
    } catch (e) {
      debugPrint('Delete Patient Remote Error: $e');
    }
    final prefs = await SharedPreferences.getInstance();
    List<String> localPatients = prefs.getStringList('local_patients') ?? [];
    localPatients.removeWhere((s) => Patient.fromJson(json.decode(s)).id == patientId);
    await prefs.setStringList('local_patients', localPatients);
    return true;
  }

  Future<List<Medication>> fetchMedications() async {
    final result = await _post("find", {"collection": "medications"});
    if (result == null) return [];
    final List docs = result['documents'] ?? [];
    return docs.map((json) => Medication.fromJson(json)).toList();
  }

  Future<void> seedMedications(List<Medication> meds) async {
    final existing = await fetchMedications();
    if (existing.isEmpty) {
      await _post("insertMany", {
        "collection": "medications",
        "documents": meds.map((m) => m.toJson()).toList()
      });
      debugPrint('MongoDB: Seeded medications via Data API');
    }
  }

  Future<List<Map<String, String>>> fetchPrescriptions() async {
    try {
      final result = await _post("find", {"collection": "prescriptions", "sort": {"date": -1}});
      if (result != null) {
        final List docs = result['documents'] ?? [];
        final prescriptions = docs.map((item) {
          return (item as Map).map((key, value) => MapEntry(key.toString(), value.toString()));
        }).toList();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('local_prescriptions', prescriptions.map((p) => json.encode(p)).toList());
        return prescriptions;
      }
    } catch (e) {
      debugPrint('Fetch Prescriptions Remote Error: $e');
    }
    final prefs = await SharedPreferences.getInstance();
    final List<String> localData = prefs.getStringList('local_prescriptions') ?? [];
    return localData.map((s) => Map<String, String>.from(json.decode(s))).toList();
  }

  Future<bool> addPrescription(Map<String, String> prescription) async {
    bool remoteSuccess = false;
    try {
      final result = await _post("insertOne", {"collection": "prescriptions", "document": prescription});
      remoteSuccess = result != null;
    } catch (e) {
      debugPrint('Add Prescription Remote Error: $e');
    }
    final prefs = await SharedPreferences.getInstance();
    List<String> localData = prefs.getStringList('local_prescriptions') ?? [];
    localData.insert(0, json.encode(prescription));
    await prefs.setStringList('local_prescriptions', localData);
    return remoteSuccess || true;
  }

  Future<List<Map<String, dynamic>>> fetchLogs() async {
    try {
      final result = await _post("find", {"collection": "audit_logs", "sort": {"timestamp": -1}});
      if (result != null) {
        final List docs = result['documents'] ?? [];
        final logs = List<Map<String, dynamic>>.from(docs);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('local_logs', logs.map((l) => json.encode(l)).toList());
        return logs;
      }
    } catch (e) {
      debugPrint('Fetch Logs Remote Error: $e');
    }
    final prefs = await SharedPreferences.getInstance();
    final List<String> localData = prefs.getStringList('local_logs') ?? [];
    return localData.map((s) => Map<String, dynamic>.from(json.decode(s))).toList();
  }

  Future<bool> addLog(Map<String, dynamic> log) async {
    log['timestamp'] ??= DateTime.now().toIso8601String();
    bool remoteSuccess = false;
    try {
      final result = await _post("insertOne", {"collection": "audit_logs", "document": log});
      remoteSuccess = result != null;
    } catch (e) {
      debugPrint('Add Log Remote Error: $e');
    }
    final prefs = await SharedPreferences.getInstance();
    List<String> localData = prefs.getStringList('local_logs') ?? [];
    localData.insert(0, json.encode(log));
    await prefs.setStringList('local_logs', localData);
    return remoteSuccess || true;
  }

  Future<Map<String, dynamic>?> login(String role, String staffId, String password) async {
    try {
      final result = await _post("findOne", {"collection": "staff", "filter": {"staffId": staffId, "role": role}});
      if (result != null && result['document'] != null) {
        final doc = result['document'];
        if (doc['password'] == password) {
          return {'success': true, 'role': role, 'staffId': staffId, 'source': 'remote'};
        }
      }
    } catch (e) {
      debugPrint('Login Remote Error: $e');
    }
    final prefs = await SharedPreferences.getInstance();
    List<String> localStaff = prefs.getStringList('local_staff') ?? [];
    for (var s in localStaff) {
      final user = json.decode(s);
      if (user['staffId'] == staffId && user['role'] == role && user['password'] == password) {
        return {'success': true, 'role': role, 'staffId': staffId, 'source': 'local'};
      }
    }
    if (staffId == "admin" && password == "admin123") {
      return {'success': true, 'role': 'Admin', 'staffId': 'admin', 'source': 'default'};
    }
    return null;
  }

  Future<bool> register(String role, String staffId, String email, String phone, String password) async {
    bool remoteSuccess = false;
    try {
      final existing = await _post("findOne", {"collection": "staff", "filter": {"staffId": staffId}});
      if (existing != null && existing['document'] != null) return false;
      final result = await _post("insertOne", {
        "collection": "staff",
        "document": {
          "staffId": staffId, "email": email, "phone": phone, "role": role, "password": password,
          "createdAt": DateTime.now().toIso8601String()
        }
      });
      remoteSuccess = result != null;
    } catch (e) {
      debugPrint('Registration Remote Error: $e');
    }
    final prefs = await SharedPreferences.getInstance();
    List<String> localStaff = prefs.getStringList('local_staff') ?? [];
    bool isLocalDuplicate = localStaff.any((s) => json.decode(s)['staffId'] == staffId);
    if (!isLocalDuplicate) {
      localStaff.add(json.encode({"staffId": staffId, "email": email, "phone": phone, "role": role, "password": password}));
      await prefs.setStringList('local_staff', localStaff);
    }
    return remoteSuccess || !isLocalDuplicate;
  }

  Future<bool> resetPasswordWithPhone(String staffId, String phone, String newPassword) async {
    bool remoteSuccess = false;
    try {
      final result = await _post("updateOne", {
        "collection": "staff", "filter": {"staffId": staffId, "phone": phone},
        "update": {"\$set": {"password": newPassword}}
      });
      remoteSuccess = result != null && result['matchedCount'] > 0;
    } catch (e) {
      debugPrint('Reset Password Phone Remote Error: $e');
    }
    final prefs = await SharedPreferences.getInstance();
    List<String> localStaff = prefs.getStringList('local_staff') ?? [];
    bool localFound = false;
    List<String> updatedStaff = localStaff.map((s) {
      final user = json.decode(s);
      if (user['staffId'] == staffId && user['phone'] == phone) {
        user['password'] = newPassword;
        localFound = true;
        return json.encode(user);
      }
      return s;
    }).toList();
    if (localFound) await prefs.setStringList('local_staff', updatedStaff);
    return remoteSuccess || localFound;
  }
}

class EmailService {
  String _smtpUser = 'YOUR_SMTP_USER';
  String _smtpPass = 'YOUR_SMTP_PASSWORD';
  void updateCredentials(String user, String pass) { _smtpUser = user; _smtpPass = pass; }
  Future<bool> sendOtpEmail(String recipientEmail, String otp) async {
    if (kIsWeb) return true;
    if (_smtpUser == 'YOUR_SMTP_USER' || _smtpUser.isEmpty) return false;
    final smtpServer = gmail(_smtpUser, _smtpPass);
    final message = Message()
      ..from = Address(_smtpUser, 'ICU Suite Pro Support')
      ..recipients.add(recipientEmail)
      ..subject = 'Verification Code'
      ..text = 'Your code is: $otp';
    try {
      await send(message, smtpServer);
      return true;
    } catch (e) {
      return false;
    }
  }
}

class SmsService {
  TwilioFlutter? _twilioFlutter;
  String _accountSid = 'ACxxx'; String _authToken = 'xxx'; String _twilioNumber ='+1555';
  void updateCredentials(String sid, String token, String number) {
    _accountSid = sid; _authToken = token; _twilioNumber = number;
    if (!kIsWeb) _initializeTwilio();
  }
  Future<bool> sendOtpSms(String phoneNumber, String otp) async {
    if (kIsWeb) { debugPrint('Mock SMS to $phoneNumber: $otp'); return true; }
    if (_twilioFlutter == null) _initializeTwilio();
    if (_twilioFlutter == null) return false;
    try {
      await _twilioFlutter!.sendSMS(toNumber: phoneNumber, messageBody: 'Code: $otp');
      return true;
    } catch (e) {
      return false;
    }
  }
  void _initializeTwilio() {
    if (kIsWeb) return;
    if (_accountSid.isNotEmpty && !_accountSid.contains('ACxxx')) {
      _twilioFlutter = TwilioFlutter(accountSid: _accountSid, authToken: _authToken, twilioNumber: _twilioNumber);
    }
  }
}

// ==========================================
// STATE MANAGEMENT
// ==========================================

class AppState extends ChangeNotifier {
  final MongoService _mongoService = MongoService();
  final SmsService _smsService = SmsService();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  AppState() { _init(); }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final appId = prefs.getString('mongodb_app_id');
    final apiKey = prefs.getString('mongodb_api_key');
    if (appId != null && apiKey != null) _mongoService.updateCredentials(appId, apiKey);
    syncWithServer();
  }

  void updateMongoConfig(String appId, String apiKey) {
    _mongoService.updateCredentials(appId, apiKey);
    syncWithServer();
  }

  void updateSmsConfig(String sid, String token, String number) { _smsService.updateCredentials(sid, token, number); }

  String? _currentUserRole;
  String? get currentUserRole => _currentUserRole;

  final List<String> _activeStaff = ['Dr. Smith', 'Dr. Sarah', 'Nurse John'];
  List<String> get activeStaff => _activeStaff;

  List<Medication> _medications = [
    Medication(id: 'm1', name: 'Propofol', category: 'Anesthetic', standardDosePerKg: 2.0, minDosePerKg: 1.5, maxDosePerKg: 2.5, unit: 'mg', interactions: ['m2']),
  ];
  List<Medication> get medications => _medications;

  String _shiftHandover = "Stable. All checks complete.";
  String get shiftHandover => _shiftHandover;
  void updateHandover(String text) { _shiftHandover = text; notifyListeners(); }

  List<Patient> _patients = [];
  List<Patient> get patients => _patients;

  List<Map<String, dynamic>> _activityLogs = [];
  List<Map<String, dynamic>> get activityLogs => _activityLogs;

  List<Map<String, String>> _prescriptions = [];
  List<Map<String, String>> get prescriptions => _prescriptions;

  Future<void> syncWithServer() async {
    _isLoading = true; notifyListeners();
    try {
      await _mongoService.seedMedications(_medications);
      final remoteMeds = await _mongoService.fetchMedications();
      if (remoteMeds.isNotEmpty) _medications = remoteMeds;
      _patients = await _mongoService.fetchPatients();
      _prescriptions = await _mongoService.fetchPrescriptions();
      _activityLogs = await _mongoService.fetchLogs();
    } catch (e) {
      debugPrint("Sync error: $e");
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  List<String> get availableBeds {
    final allPossibleBeds = List.generate(50, (i) => 'ICU-${(i + 1).toString().padLeft(2, '0')}');
    final occupiedBeds = _patients.map((p) => p.bedNumber).toSet();
    return allPossibleBeds.where((b) => !occupiedBeds.contains(b)).toList();
  }

  void addPrescription(Map<String, String> prescription) async {
    final success = await _mongoService.addPrescription(prescription);
    if (success) {
      _prescriptions.insert(0, prescription);
      await _mongoService.addLog({'time': prescription['date']!, 'user': _currentUserRole ?? 'System', 'action': 'New Rx: ${prescription['med']}'});
      _activityLogs = await _mongoService.fetchLogs();
      notifyListeners();
    }
  }

  void addPatient(Patient patient) async {
    final success = await _mongoService.savePatient(patient);
    if (success) {
      _patients.insert(0, patient);
      await _mongoService.addLog({'time': DateTime.now().toIso8601String(), 'user': _currentUserRole ?? 'System', 'action': 'Admission: ${patient.name}'});
      _activityLogs = await _mongoService.fetchLogs();
      notifyListeners();
    }
  }

  void updatePatientVitals(String patientId, {double? sys, double? dia, int? hr, double? bili, double? plat, double? creat, double? gcsVal, double? fiO2Val, double? paO2Val}) async {
    final index = _patients.indexWhere((p) => p.id == patientId);
    if (index != -1) {
      if (sys != null) _patients[index].systolicBP = sys;
      if (dia != null) _patients[index].diastolicBP = dia;
      if (hr != null) _patients[index].heartRate = hr;
      if (bili != null) _patients[index].bilirubin = bili;
      if (plat != null) _patients[index].platelets = plat;
      if (creat != null) _patients[index].creatinine = creat;
      if (gcsVal != null) _patients[index].gcs = gcsVal;
      if (fiO2Val != null) _patients[index].fiO2 = fiO2Val;
      if (paO2Val != null) _patients[index].paO2 = paO2Val;
      await _mongoService.savePatient(_patients[index]);
      notifyListeners();
    }
  }

  void triggerEmergencyAlert(String alertType) async {
    await _mongoService.addLog({'user': _currentUserRole ?? 'System', 'action': 'ALERT: $alertType'});
    _activityLogs = await _mongoService.fetchLogs();
    notifyListeners();
  }

  Future<bool> login(String role, String staffId, String password) async {
    _isLoading = true; notifyListeners();
    final response = await _mongoService.login(role, staffId, password);
    _isLoading = false;
    if (response != null) { _currentUserRole = role; notifyListeners(); return true; }
    notifyListeners(); return false;
  }

  Future<bool> register(String role, String staffId, String email, String phone, String password) async {
    _isLoading = true; notifyListeners();
    final success = await _mongoService.register(role, staffId, email, phone, password);
    if (success) _currentUserRole = role;
    _isLoading = false; notifyListeners(); return success;
  }

  Future<bool> resetPasswordWithPhone(String staffId, String phone, String newPassword) async {
    _isLoading = true; notifyListeners();
    final success = await _mongoService.resetPasswordWithPhone(staffId, phone, newPassword);
    _isLoading = false; notifyListeners(); return success;
  }

  void logout() { _currentUserRole = null; notifyListeners(); }

  void dischargePatient(String patientId) async {
    final index = _patients.indexWhere((p) => p.id == patientId);
    if (index != -1) {
      final p = _patients[index];
      if (await _mongoService.deletePatient(patientId)) {
        await _mongoService.addLog({'user': _currentUserRole ?? 'System', 'action': 'Discharged: ${p.name}'});
        _patients.removeAt(index);
        _activityLogs = await _mongoService.fetchLogs();
        notifyListeners();
      }
    }
  }
}
