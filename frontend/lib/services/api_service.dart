// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  // Dynamically pulls the URL from your .env file
  // Fallback to localhost just in case .env fails to load
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';

  // --- THE INTERCEPTOR ---
  // Attaches the Bearer token to all requests
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // --- REFRESH TOKEN LOGIC ---
  static Future<bool> refreshAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');

    if (refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        await prefs.setString('access_token', data['access_token']);
        
        if (data.containsKey('refresh_token')) {
          await prefs.setString('refresh_token', data['refresh_token']);
        }
        
        print("Token refreshed successfully!");
        return true;
      }
      print("Refresh failed. User needs to log in again.");
      return false;
    } catch (e) {
      print('Refresh token error: $e');
      return false;
    }
  }

  // --- AUTH APIS ---
  static Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/signin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['access_token']);
        await prefs.setString('refresh_token', data['refresh_token']);
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  // --- EMERGENCY CONTACTS APIS ---
  static Future<List<dynamic>> getContacts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/emergency-contacts/'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print('Get contacts error: $e');
      return [];
    }
  }

  static Future<bool> addContact(String name, String phno) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/emergency-contacts/'),
        headers: await _getHeaders(),
        body: jsonEncode({'name': name, 'phno': phno}),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Add contact error: $e');
      return false;
    }
  }

  static Future<bool> deleteContact(String contactId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/emergency-contacts/$contactId'),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Delete contact error: $e');
      return false;
    }
  }

  // --- SOS TRIGGER API ---
  static Future<bool> triggerSOS(double lat, double lon, int battery) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/trigger'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'lat': lat,
          'lon': lon,
          'battery': battery,
          'time': DateTime.now().toUtc().toIso8601String()
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('SOS Trigger error: $e');
      return false;
    }
  }
}