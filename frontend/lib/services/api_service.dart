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
        
        // --- SAVE UUID FOR MESH IDENTITY ---
        if (data['user'] != null && data['user']['uuid'] != null) {
          await prefs.setString('user_uuid', data['user']['uuid']);
          print("🆔 User UUID saved: ${data['user']['uuid']}");
        }
        
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  static Future<bool> signup(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      // 201 Created is standard for signup, but we check 200 just in case
      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Account created successfully!");
        return true;
      } else {
        print("Signup failed: ${response.body}");
        return false;
      }
    } catch (e) {
      print('Signup error: $e');
      return false;
    }
  }

  // --- EMERGENCY CONTACTS APIS ---
// --- EMERGENCY CONTACTS APIS ---
  static Future<List<dynamic>> getContacts() async {
    try {
      final response = await http.get(
        // REMOVED trailing slash to match your screenshot GET
        Uri.parse('$baseUrl/emergency-contacts'), 
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      print("Get Contacts Failed: ${response.statusCode}");
      return [];
    } catch (e) {
      print('Get contacts error: $e');
      return [];
    }
  }

  static Future<bool> addContact(String name, String phno) async {
    try {
      final response = await http.post(
        // Ensure this matches the POST in your screenshot
        Uri.parse('$baseUrl/emergency-contacts/'), 
        headers: await _getHeaders(),
        body: jsonEncode({'name': name, 'phno': phno}),
      );
      print("Add Contact Response: ${response.statusCode} - ${response.body}");
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Add contact error: $e');
      return false;
    }
  }

  // --- SOS TRIGGER API ---
  static Future<bool> triggerSOS(double lat, double lon, int battery) async {
    try {
      final url = Uri.parse('$baseUrl/trigger');
      var headers = await _getHeaders();
      
      final body = jsonEncode({
        'lat': lat,
        'lon': lon,
        'battery': battery,
        'time': DateTime.now().toUtc().toIso8601String()
      });

      print("📡 Sending SOS to $url");
      var response = await http.post(url, headers: headers, body: body);

      // --- TOKEN EXPIRED LOGIC ---
      if (response.statusCode == 401) {
        print("🔑 Token expired. Attempting refresh...");
        bool refreshed = await refreshAccessToken();
        
        if (refreshed) {
          print("🔄 Token refreshed! Retrying SOS...");
          headers = await _getHeaders(); // Get fresh headers with the new token
          response = await http.post(url, headers: headers, body: body);
        } else {
          print("⛔ Refresh failed. User must log in again.");
          return false;
        }
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ SOS Success: ${response.body}");
        return true;
      } else {
        print("❌ SOS Backend Error (${response.statusCode}): ${response.body}");
        return false;
      }
    } catch (e) {
      print('SOS Trigger Network Error: $e');
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


// --- LIVE LOCATION STREAMING ---
  static Future<bool> sendLiveLocation(double lat, double lon) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) return false;

      // NOTE: You will need to create this endpoint on your Node.js backend!
      // e.g., router.post('/sos/live-location', ...)
      final response = await http.post(
        Uri.parse('$baseUrl/sos/live-location'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'lat': lat,
          'lon': lon,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("📍 Live Location Ping Sent: $lat, $lon");
        return true;
      }
      return false;
    } catch (e) {
      print("Live Location Error: $e");
      return false;
    }
  }

  // --- USER PROFILE API ---
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Ensure UUID is cached for the Mesh Service
        if (data['uuid'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_uuid', data['uuid']);
        }
        
        return data;
      }
      return null;
    } catch (e) {
      print('Get profile error: $e');
      return null;
    }
  }

  // --- OFFLINE MESH RELAY ---
  static Future<bool> relayOfflineSOS(String victimUuid, double lat, double lon) async {
    try {
      // NOTE: Ensure this matches your teammate's backend route
      final url = Uri.parse('$baseUrl/trigger/relay'); 
      final headers = await _getHeaders();
      
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'victim_uuid': victimUuid,
          'lat': lat,
          'lon': lon,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Mesh Relay Success!");
        return true;
      }
      print("❌ Mesh Relay Rejected: ${response.statusCode}");
      return false;
    } catch (e) {
      print('Relay API Error: $e');
      return false;
    }
  }
}

