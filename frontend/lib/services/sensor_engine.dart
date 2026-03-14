// lib/services/sensor_engine.dart
import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class SensorEngine {
  StreamSubscription? _subscription;
  
  // Logic Control
  bool _isMonitoringInactivity = false;
  
  // DEMO THRESHOLDS: 
  // 20.0 = A sharp snap of the wrist.
  // 3.0 = Relative stillness (handheld but steady).
  final double impactThreshold = 30.0; 
  final double inactivityThreshold = 3.0; 
  
  // Callback to tell the UI to show the 5s Cancel Timer
  Function()? onTriggerAlert;

  void start() {
    print("🚀 SENSOR ENGINE: High-G & Inactivity Monitoring Active");
    
    _subscription = accelerometerEvents.listen((AccelerometerEvent event) {
      double force = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      // LIVE LOGS: Helps you see the sensor reacting in real-time
      if (force > 10) {
        print("Current G-Force: ${force.toStringAsFixed(2)}");
      }

      // 1. Detect the Impact Spike
      if (force > impactThreshold && !_isMonitoringInactivity) {
        print("💥 IMPACT DETECTED (${force.toStringAsFixed(2)}). Monitoring for inactivity...");
        _startInactivityCheck();
      }
    });
  }

  void _startInactivityCheck() {
    _isMonitoringInactivity = true;
    int quietSeconds = 0;
    
    // Check every second for 5 seconds (Reduced for faster Demo)
    Timer.periodic(const Duration(seconds: 1), (timer) {
      quietSeconds++;
      print("Checking inactivity... second $quietSeconds");
      
      // If the user moves too much, reset/cancel (optional for production, but kept simple for demo)
      
      if (quietSeconds >= 5) {
        timer.cancel();
        _isMonitoringInactivity = false;
        print("🚨 USER INACTIVE AFTER IMPACT. Triggering Alert UI...");
        if (onTriggerAlert != null) onTriggerAlert!();
      }
    });
  }

  void stop() {
    _subscription?.cancel();
    print("🛑 SENSOR ENGINE: Offline");
  }
}