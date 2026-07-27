import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/patient.dart';
import '../models/medication.dart';
import '../services/mongodb_service.dart';
import '../services/email_service.dart';
import '../services/sms_service.dart';

class AppState extends ChangeNotifier {
  final MongoService _mongoService = MongoService();
  final EmailService _emailService = EmailService();
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
    final region = prefs.getString('mongodb_region');
    final dbName = prefs.getString('mongodb_db');
    final cluster = prefs.getString('mongodb_cluster');
    
    if (appId != null && apiKey != null) {
      _mongoService.updateCredentials(appId, apiKey, region: region, dataSource: cluster, database: dbName);
    }
    syncWithServer();
  }

  void updateMongoConfig(String appId, String apiKey, {String? region, String? dataSource, String? database}) {
    _mongoService.updateCredentials(appId, apiKey, region: region, dataSource: dataSource, database: database);
    syncWithServer();
  }

  void updateSmsConfig(String sid, String token, String number) {
    _smsService.updateCredentials(sid, token, number);
  }

  bool get isCloudSyncActive => _mongoService.isConfigured;

  String? _currentUserRole;
  String? get currentUserRole => _currentUserRole;

  final List<String> _activeStaff = ['Dr. Smith', 'Nurse John'];
  List<String> get activeStaff => _activeStaff;

  List<Medication> _medications = [
    Medication(id: 'm1', name: 'Propofol', category: 'Anesthetic', standardDosePerKg: 2.0, minDosePerKg: 1.5, maxDosePerKg: 2.5, unit: 'mg', interactions: ['m2']),
  ];
  List<Medication> get medications => _medications;

  String _shiftHandover = "Current ward status: Stable. All ventilator checks complete.";
  String get shiftHandover => _shiftHandover;
  
  void updateHandover(String text) {
    _shiftHandover = text;
    notifyListeners();
  }

  List<Patient> _patients = [];
  List<Patient> get patients => _patients;

  List<Map<String, dynamic>> _activityLogs = [];
  List<Map<String, dynamic>> get activityLogs => _activityLogs;

  List<Map<String, String>> _prescriptions = [];
  List<Map<String, String>> get prescriptions => _prescriptions;

  Future<void> syncWithServer() async {
    _isLoading = true;
    notifyListeners();
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
    final allPossibleBeds = List.generate(50, (i) => 'ICU-${(i + 1).toString().padLeft(2, '0')}');
    final occupiedBeds = _patients.map((p) => p.bedNumber).toSet();
    return allPossibleBeds.where((b) => !occupiedBeds.contains(b)).toList();
  }

  void addPrescription(Map<String, String> prescription) async {
    if (await _mongoService.addPrescription(prescription)) {
      _prescriptions.insert(0, prescription);
      await _mongoService.addLog({'time': prescription['date']!, 'user': _currentUserRole ?? 'System', 'action': 'New Rx: ${prescription['med']}'});
      _activityLogs = await _mongoService.fetchLogs();
      notifyListeners();
    }
  }

  void addPatient(Patient patient) async {
    if (await _mongoService.savePatient(patient)) {
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

  void updatePatientHistory(String patientId, String entry) async {
    final index = _patients.indexWhere((p) => p.id == patientId);
    if (index != -1) {
      _patients[index].history.add(entry);
      await _mongoService.savePatient(_patients[index]);
      notifyListeners();
    }
  }

  void triggerEmergencyAlert(String alertType) async {
    await _mongoService.addLog({'user': _currentUserRole ?? 'System', 'action': 'ALERT: $alertType'});
    _activityLogs = await _mongoService.fetchLogs();
    notifyListeners();
  }

  Future<Map<String, dynamic>> login(String role, String staffId, String password) async {
    _isLoading = true; notifyListeners();
    final response = await _mongoService.login(role, staffId, password);
    _isLoading = false; notifyListeners();
    if (response != null && response['success'] == true) {
      _currentUserRole = role; notifyListeners(); return response;
    }
    return response ?? {'success': false, 'error': 'Connection Error'};
  }

  Future<bool> register(String role, String staffId, String email, String phone, String password) async {
    _isLoading = true; notifyListeners();
    final success = await _mongoService.register(role, staffId, email, phone, password);
    _isLoading = false; notifyListeners(); return success;
  }

  Future<List<Map<String, dynamic>>> fetchStaff() async { return await _mongoService.fetchAllStaff(); }

  Future<bool> approveUser(String staffId) async {
    final s = await _mongoService.updateUserStatus(staffId, "Approved");
    if (s) { await _mongoService.addLog({'user': _currentUserRole ?? 'System', 'action': 'User Approved: $staffId'}); _activityLogs = await _mongoService.fetchLogs(); notifyListeners(); }
    return s;
  }

  Future<bool> blockUser(String staffId) async {
    final s = await _mongoService.updateUserStatus(staffId, "Blocked");
    if (s) { await _mongoService.addLog({'user': _currentUserRole ?? 'System', 'action': 'User Blocked: $staffId'}); _activityLogs = await _mongoService.fetchLogs(); notifyListeners(); }
    return s;
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
        _patients.removeAt(index);
        await _mongoService.addLog({'user': _currentUserRole ?? 'System', 'action': 'Discharged: ${p.name}'});
        _activityLogs = await _mongoService.fetchLogs(); notifyListeners();
      }
    }
  }
}
