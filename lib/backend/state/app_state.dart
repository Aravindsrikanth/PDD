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

  AppState() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final appId = prefs.getString('mongodb_app_id');
    final apiKey = prefs.getString('mongodb_api_key');
    final region = prefs.getString('mongodb_region');
    final dbName = prefs.getString('mongodb_db');
    final cluster = prefs.getString('mongodb_cluster');
    
    final emailUser = prefs.getString('smtp_user');
    final emailPass = prefs.getString('smtp_pass');
    final twilioSid = prefs.getString('twilio_sid');
    final twilioToken = prefs.getString('twilio_token');
    final twilioNum = prefs.getString('twilio_num');
    
    if (appId != null && apiKey != null) {
      _mongoService.updateCredentials(
        appId, 
        apiKey, 
        region: region, 
        database: dbName, 
        dataSource: cluster
      );
    }

    if (emailUser != null && emailPass != null) {
      _emailService.updateCredentials(emailUser, emailPass);
    }

    if (twilioSid != null && twilioToken != null && twilioNum != null) {
      _smsService.updateCredentials(twilioSid, twilioToken, twilioNum);
    }
    
    syncWithServer();
  }

  void updateMongoConfig(String appId, String apiKey, {String? region, String? dataSource, String? database}) {
    _mongoService.updateCredentials(appId, apiKey, region: region, dataSource: dataSource, database: database);
    syncWithServer();
  }

  bool get isCloudSyncActive => _mongoService.isConfigured;

  void updateEmailConfig(String user, String pass) {
    _emailService.updateCredentials(user, pass);
  }

  void updateSmsConfig(String sid, String token, String number) {
    _smsService.updateCredentials(sid, token, number);
  }

  String? _currentUserRole;
  String? get currentUserRole => _currentUserRole;

  final List<String> _activeStaff = ['Dr. Smith', 'Dr. Sarah', 'Nurse John', 'Nurse Emma', 'Dr. Mike', 'Dr. Anna', 'Nurse Chris', 'Nurse Lisa'];
  List<String> get activeStaff => _activeStaff;

  List<Medication> _medications = [
    Medication(id: 'm1', name: 'Propofol', category: 'Anesthetic', standardDosePerKg: 2.0, minDosePerKg: 1.5, maxDosePerKg: 2.5, unit: 'mg', warning: 'Monitor for Propofol Infusion Syndrome.', interactions: ['m2', 'm3', 'm4']),
    Medication(id: 'm2', name: 'Midazolam', category: 'Sedative', standardDosePerKg: 0.05, minDosePerKg: 0.02, maxDosePerKg: 0.1, unit: 'mg', warning: 'High risk of respiratory depression.', interactions: ['m1', 'm3']),
    Medication(id: 'm3', name: 'Fentanyl', category: 'Analgesic', standardDosePerKg: 1.0, minDosePerKg: 0.5, maxDosePerKg: 2.0, unit: 'mcg', warning: 'Monitor respiratory rate closely.', interactions: ['m1', 'm2']),
    Medication(id: 'm4', name: 'Norepinephrine', category: 'Vasopressor', standardDosePerKg: 0.1, minDosePerKg: 0.01, maxDosePerKg: 0.5, unit: 'mcg/kg/min', warning: 'Monitor MAP and peripheral perfusion.', interactions: ['m1']),
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
      if (remoteMeds.isNotEmpty) {
        _medications = remoteMeds;
      }

      final remotePatients = await _mongoService.fetchPatients();
      _patients = remotePatients;

      final remotePrescriptions = await _mongoService.fetchPrescriptions();
      _prescriptions = remotePrescriptions;

      final remoteLogs = await _mongoService.fetchLogs();
      _activityLogs = remoteLogs;

      debugPrint('SYNC: MongoDB synchronization complete.');
    } catch (e) {
      debugPrint("Sync error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
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
      
      await _mongoService.addLog({
        'time': prescription['date']!,
        'user': _currentUserRole ?? 'System',
        'action': 'New Prescription: ${prescription['med']} for ${prescription['patient']}',
      });

      _activityLogs = await _mongoService.fetchLogs();
      
      final pIndex = _patients.indexWhere((p) => p.id == prescription['patientId']);
      if (pIndex != -1) {
        _patients[pIndex].history.add('New Prescription: ${prescription['med']} (${prescription['dose']}) at ${prescription['date']}');
        await _mongoService.savePatient(_patients[pIndex]);
      }
      notifyListeners();
    }
  }

  void addPatient(Patient patient) async {
    final success = await _mongoService.savePatient(patient);
    if (success) {
      _patients.insert(0, patient);
      await _mongoService.addLog({
        'time': DateTime.now().toIso8601String(),
        'user': _currentUserRole ?? 'System',
        'action': 'Admission: ${patient.name} admitted to ${patient.bedNumber}',
      });
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
      
      _patients[index].history.add('Clinical data updated at ${DateTime.now().toIso8601String()}');
      
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
    await _mongoService.addLog({
      'user': _currentUserRole ?? 'System',
      'action': 'CRITICAL ALERT: $alertType triggered',
      'timestamp': DateTime.now().toIso8601String(),
    });
    _activityLogs = await _mongoService.fetchLogs();
    notifyListeners();
  }

  Future<bool> login(String role, String staffId, String password) async {
    _isLoading = true;
    notifyListeners();

    final response = await _mongoService.login(role, staffId, password);
    
    _isLoading = false;
    if (response != null) {
      _currentUserRole = role;
      notifyListeners();
      return true;
    }
    
    notifyListeners();
    return false;
  }

  Future<bool> register(String role, String staffId, String email, String phone, String password) async {
    _isLoading = true;
    notifyListeners();

    final success = await _mongoService.register(role, staffId, email, phone, password);
    
    if (success) {
      _currentUserRole = role;
    }
    
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> resetPasswordWithPhone(String staffId, String phone, String newPassword) async {
    _isLoading = true;
    notifyListeners();

    final success = await _mongoService.resetPasswordWithPhone(staffId, phone, newPassword);
    
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> sendOtpSms(String phone, String otp) async {
    return await _smsService.sendOtpSms(phone, otp);
  }

  Future<bool> resetPassword(String staffId, String email, String newPassword) async {
    _isLoading = true;
    notifyListeners();

    final success = await _mongoService.resetPassword(staffId, email, newPassword);
    
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> sendOtp(String email, String otp) async {
    return await _emailService.sendOtpEmail(email, otp);
  }

  void logout() {
    _currentUserRole = null;
    notifyListeners();
  }

  void dischargePatient(String patientId) async {
    final index = _patients.indexWhere((p) => p.id == patientId);
    if (index != -1) {
      final p = _patients[index];
      final success = await _mongoService.deletePatient(patientId);
      if (success) {
        await _mongoService.addLog({
          'user': _currentUserRole ?? 'System',
          'action': 'Patient Discharged: ${p.name} from ${p.bedNumber}',
        });
        _patients.removeAt(index);
        _activityLogs = await _mongoService.fetchLogs();
        notifyListeners();
      }
    }
  }
}
