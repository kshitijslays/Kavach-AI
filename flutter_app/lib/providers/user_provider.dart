import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider with ChangeNotifier {
  Map<String, dynamic>? _user;
  String? _token;
  bool _loading = true;
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  Map<String, dynamic>? get user => _user;
  String? get token => _token;
  bool get loading => _loading;
  bool get isAuthenticated => _user != null || _token != null;

  UserProvider() {
    loadProfile();
  }

  Future<void> loadProfile() async {
    _loading = true;
    notifyListeners();
    try {
      final token = await _storageService.getToken();
      if (token != null) {
        _token = token;
        final data = await _apiService.getProfile(token);
        if (data['user'] != null) {
          _user = data['user'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userEmail', _user?['email'] ?? '');
          if (_user?['emergencyContacts'] != null) {
            await prefs.setString('userEmergencyContacts', jsonEncode(_user?['emergencyContacts']));
          }
          // Sync token for background isolate
          await prefs.setString('userToken', token);
        }
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void login(Map<String, dynamic> userData, String? token) {
    _user = userData;
    if (token != null) {
      _token = token;
      _storageService.saveToken(token);
    }
    
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('userEmail', userData['email'] ?? '');
      if (token != null) {
        prefs.setString('userToken', token);
      }
      if (userData['emergencyContacts'] != null) {
        prefs.setString('userEmergencyContacts', jsonEncode(userData['emergencyContacts']));
      }
    });

    notifyListeners();
  }

  Future<void> logout() async {
    await _storageService.clearToken();
    _user = null;
    _token = null;
    notifyListeners();
  }

  void updateProfile(Map<String, dynamic> updatedData) {
    if (_user != null) {
      _user = {..._user!, ...updatedData};
      notifyListeners();
    }
  }

  Future<void> updateEmergencyContacts(List<dynamic> contacts) async {
    if (_token == null) return;
    
    try {
      final response = await _apiService.updateProfile(_token!, {
        'emergencyContacts': contacts,
      });
      
      if (response['user'] != null) {
        _user = response['user'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userEmergencyContacts', jsonEncode(contacts));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating contacts: $e');
      rethrow;
    }
  }
}
