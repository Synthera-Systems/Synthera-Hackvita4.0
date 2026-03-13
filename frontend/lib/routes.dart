// lib/routes.dart
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart'; 

class AppRoutes {
  static const String login = '/';
  static const String signup = '/signup';
  static const String home = '/home'; 

  static Map<String, WidgetBuilder> define() {
    return {
      login: (context) => const LoginScreen(),
      signup: (context) => const SignupScreen(),
      home: (context) => const HomeScreen(), // ADD THIS LINE
    };
  }
}