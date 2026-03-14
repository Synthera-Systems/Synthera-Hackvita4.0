// lib/routes.dart
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart'; 
import 'screens/profile_screen.dart';
import 'screens/fake_call_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home'; 
  static const String profile = '/profile';
  static const String fakeCall = '/fake_call';

  static Map<String, WidgetBuilder> define() {
    return {
      splash: (context) => const SplashScreen(),
      login: (context) => const LoginScreen(),
      signup: (context) => const SignupScreen(),
      home: (context) => const HomeScreen(),
      
      // Route with argument extraction for Profile
      profile: (context) {
        final userProfile = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return ProfileScreen(userProfile: userProfile);
      },
      
      // Route with argument extraction for Fake Call
      fakeCall: (context) {
        final callerId = ModalRoute.of(context)?.settings.arguments as String? ?? 'Emergency';
        return FakeCallScreen(callerId: callerId);
      },
    };
  }
}