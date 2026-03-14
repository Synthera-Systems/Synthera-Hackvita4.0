// lib/services/sms_service.dart
import 'package:telephony/telephony.dart';

class SmsService {
  static final Telephony telephony = Telephony.instance;

  // CHANGED: Now returns Future<bool> instead of Future<void>
  static Future<bool> sendSOSDirect({
    required List<dynamic> contacts,
    required double lat,
    required double lon,
  }) async {
    if (contacts.isEmpty) return false;

    bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;

    if (permissionsGranted ?? false) {
      // PRO-TIP: Kept the message simple to avoid Indian carrier spam filters blocking it
      final String body = "🚨 EMERGENCY SOS (SafeNet) 🚨\n\nI need help. My coordinates: $lat, $lon";

      try {
        for (var contact in contacts) {
          // Add +91 if missing, keep only numbers and +
          String address = contact['phno'].toString().replaceAll(RegExp(r'[^\d+]'), '');
          if (!address.startsWith('+')) {
            address = '+91$address'; // Default to India for your demo
          }
          
          await telephony.sendSms(
            to: address,
            message: body,
            statusListener: (SendStatus status) {
              print("📊 SMS to $address status: ${status.name}");
            },
          );
        }
        return true; // <--- SUCCESS
      } catch (e) {
        print("❌ Telephony Error: $e");
        return false; // <--- FAIL
      }
    }
    return false; // <--- FAIL (No permission)
  }
}