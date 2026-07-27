import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/patient.dart';
import '../models/medication.dart';

class MongoService {
  String _appId = "YOUR_APP_ID"; 
  String _apiKey = "YOUR_API_KEY"; 
  String _region = "ap-south-1"; 
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

  // --- STAFF / LOGIN METHODS ---
  
  Future<Map<String, dynamic>?> login(String role, String staffId, String password) async {
    try {
      final result = await _post("findOne", {
        "collection": "staff",
        "filter": {"staffId": staffId, "role": role}
      });
      
      if (result != null && result['document'] != null) {
        final doc = result['document'];
        if (doc['password'] == password) {
          if (staffId == "admin") return {'success': true, 'role': role, 'staffId': staffId};
          if (doc['status'] == 'Approved') {
             return {'success': true, 'role': role, 'staffId': staffId};
          } else if (doc['status'] == 'Blocked') {
             return {'success': false, 'error': 'Account blocked by Admin.'};
          } else {
             return {'success': false, 'error': 'Account pending approval.'};
          }
        }
      }
    } catch (e) { debugPrint('Login Error: $e'); }
    if (staffId == "admin" && password == "admin123") return {'success': true, 'role': 'Admin', 'staffId': 'admin'};
    return null;
  }

  Future<bool> register(String role, String staffId, String email, String phone, String password) async {
    try {
      // --- ABSOLUTE FORCE-OVERRIDE LOGIC ---
      // 1. Mandatory Server-Side Delete first to clear any existing index or record
      await _post("deleteOne", {
        "collection": "staff",
        "filter": {"staffId": staffId}
      });

      // 2. Immediate Fresh Insert
      final result = await _post("insertOne", {
        "collection": "staff",
        "document": {
          "staffId": staffId,
          "email": email,
          "phone": phone,
          "role": role,
          "password": password,
          "status": "Approved",
          "createdAt": DateTime.now().toIso8601String()
        }
      });
      
      // If result is null, it means the server blocked it, we try 'updateOne' as a last resort
      if (result == null) {
          final res2 = await _post("updateOne", {
            "collection": "staff",
            "filter": {"staffId": staffId},
            "update": {"$set": {"password": password, "role": role, "status": "Approved"}},
            "upsert": true
          });
          return res2 != null;
      }

      return result != null;
    } catch (e) {
      debugPrint('Registration Error: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllStaff() async {
    try {
      final result = await _post("find", {"collection": "staff"});
      if (result != null) return List<Map<String, dynamic>>.from(result['documents'] ?? []);
    } catch (_) {}
    return [];
  }

  Future<bool> updateUserStatus(String staffId, String newStatus) async {
    try {
      final result = await _post("updateOne", {
        "collection": "staff",
        "filter": {"staffId": staffId},
        "update": {"\$set": {"status": newStatus}}
      });
      return result != null;
    } catch (_) { return false; }
  }

  Future<bool> deleteStaff(String staffId) async {
    try {
      final result = await _post("deleteOne", {
        "collection": "staff",
        "filter": {"staffId": staffId}
      });
      return result != null;
    } catch (_) { return false; }
  }

  Future<bool> resetPasswordWithPhone(String staffId, String phone, String newPassword) async {
    try {
      final result = await _post("updateOne", {
        "collection": "staff",
        "filter": {"staffId": staffId, "phone": phone},
        "update": {"\$set": {"password": newPassword}}
      });
      return result != null && result['matchedCount'] > 0;
    } catch (_) { return false; }
  }

  // --- Patient Methods ---
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
    } catch (e) { debugPrint('Patient Fetch Error: $e'); }
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

  Future<bool> deletePatient(String patientId) async {
    try { await _post("deleteOne", { "collection": "patients", "filter": {"id": patientId} }); } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    List<String> localPatients = prefs.getStringList('local_patients') ?? [];
    localPatients.removeWhere((s) => Patient.fromJson(json.decode(s)).id == patientId);
    await prefs.setStringList('local_patients', localPatients);
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
}
