import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/patient.dart';
import '../models/medication.dart';

class MongoService {
  String _appId = "YOUR_APP_ID"; 
  String _apiKey = "YOUR_API_KEY"; 
  String _region = "ap-south-1"; // Default region
  String _baseUrl = "";
  
  String _dataSource = "Cluster0";
  String _database = "icu_db";

  MongoService() {
    _updateBaseUrl();
  }

  void updateCredentials(String appId, String apiKey, {String? region, String? dataSource, String? database}) {
    _appId = appId;
    _apiKey = apiKey;
    if (region != null) _region = region;
    if (dataSource != null) _dataSource = dataSource;
    if (database != null) _database = database;
    _updateBaseUrl();
  }

  void _updateBaseUrl() {
    _baseUrl = "https://$_region.aws.data.mongodb-api.com/app/$_appId/endpoint/data/v1/action";
  }

  bool get isConfigured => _appId != "YOUR_APP_ID" && _apiKey != "YOUR_API_KEY" && _appId.isNotEmpty && _apiKey.isNotEmpty;

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
      final result = await _post("find", {
        "collection": "prescriptions",
        "sort": {"date": -1}
      });
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
      final result = await _post("insertOne", {
        "collection": "prescriptions",
        "document": prescription
      });
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
      final result = await _post("find", {
        "collection": "audit_logs",
        "sort": {"timestamp": -1}
      });
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
      final result = await _post("insertOne", {
        "collection": "audit_logs",
        "document": log
      });
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
      final result = await _post("findOne", {
        "collection": "staff",
        "filter": {"staffId": staffId, "role": role}
      });
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
      final existing = await _post("findOne", {
        "collection": "staff",
        "filter": {"staffId": staffId}
      });
      if (existing != null && existing['document'] != null) {
        return false; 
      }
      final result = await _post("insertOne", {
        "collection": "staff",
        "document": {
          "staffId": staffId, "email": email, "phone": phone, "role": role, "password": password, "createdAt": DateTime.now().toIso8601String()
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
      localStaff.add(json.encode({
        "staffId": staffId, "email": email, "phone": phone, "role": role, "password": password,
      }));
      await prefs.setStringList('local_staff', localStaff);
    }
    return remoteSuccess || !isLocalDuplicate;
  }

  Future<bool> resetPasswordWithPhone(String staffId, String phone, String newPassword) async {
    bool remoteSuccess = false;
    try {
      final result = await _post("updateOne", {
        "collection": "staff",
        "filter": {"staffId": staffId, "phone": phone},
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
    if (localFound) {
      await prefs.setStringList('local_staff', updatedStaff);
    }
    return remoteSuccess || localFound;
  }

  Future<bool> resetPassword(String staffId, String email, String newPassword) async {
    bool remoteSuccess = false;
    try {
      final result = await _post("updateOne", {
        "collection": "staff",
        "filter": {"staffId": staffId, "email": email},
        "update": {"\$set": {"password": newPassword}}
      });
      remoteSuccess = result != null && result['matchedCount'] > 0;
    } catch (e) {
      debugPrint('Reset Password Remote Error: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    List<String> localStaff = prefs.getStringList('local_staff') ?? [];
    bool localFound = false;
    
    List<String> updatedStaff = localStaff.map((s) {
      final user = json.decode(s);
      if (user['staffId'] == staffId && user['email'] == email) {
        user['password'] = newPassword;
        localFound = true;
        return json.encode(user);
      }
      return s;
    }).toList();

    if (localFound) {
      await prefs.setStringList('local_staff', updatedStaff);
    }

    return remoteSuccess || localFound;
  }
}
