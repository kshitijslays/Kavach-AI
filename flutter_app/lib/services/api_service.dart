import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  final String baseUrl = AppConstants.apiBaseUrl;

  Future<Map<String, dynamic>> login(String email, String password) async {
    debugPrint('📡 [API] Login request for: $email');
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    ).timeout(Duration(milliseconds: AppConstants.apiTimeout));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> sendOTP(String email, {bool isSignUp = false}) async {
    debugPrint('📡 [API] Send OTP request for: $email (isSignUp: $isSignUp)');
    final response = await http.post(
      Uri.parse('$baseUrl/auth/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'isSignUp': isSignUp,
      }),
    ).timeout(Duration(milliseconds: AppConstants.apiTimeout));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> verifyOTP(String email, String otp, {String? name, String? phone, String? password}) async {
    debugPrint('📡 [API] Verify OTP request for: $email');
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'otp': otp,
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (password != null) 'password': password,
      }),
    ).timeout(Duration(milliseconds: AppConstants.apiTimeout));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getProfile(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(Duration(milliseconds: AppConstants.apiTimeout));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateProfile(String token, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/auth/update-profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    ).timeout(Duration(milliseconds: AppConstants.apiTimeout));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> triggerEmergencyAlert(String token, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/emergency/alert'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      ).timeout(Duration(milliseconds: AppConstants.apiTimeout));
      return _handleResponse(response);
    } catch (e) {
      print('❌ [API] Trigger Emergency Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadEmergencyAudio(String token, String filePath, List<dynamic> contacts) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/emergency/audio-alert'));
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['contacts'] = jsonEncode(contacts);
    request.files.add(await http.MultipartFile.fromPath('audio', filePath));
    
    final streamedResponse = await request.send().timeout(const Duration(seconds: 45));
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    debugPrint('⏳ [API] Response: ${response.statusCode}');
    try {
      final body = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return body;
      } else {
        final message = body['message'] ?? 'Something went wrong (Status: ${response.statusCode})';
        debugPrint('❌ [API] Error Response: $message');
        throw Exception(message);
      }
    } catch (e) {
      if (e is FormatException) {
        debugPrint('❌ [API] Invalid JSON Response: ${response.body}');
        if (response.statusCode >= 500) {
          throw Exception("Server Error (${response.statusCode}). The service might be temporarily unavailable.");
        }
        throw Exception("Server returned an invalid response. Please try again later.");
      }
      debugPrint('❌ [API] Handling Error: $e');
      rethrow;
    }
  }
}
