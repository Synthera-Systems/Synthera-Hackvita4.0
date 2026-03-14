// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'routes.dart';
import 'services/notification_service.dart';

// Changed main to async to load the .env file before the app boots
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  await dotenv.load(fileName: ".env");       
  await NotificationService.init();
  runApp(const SafeNetApp());
}

class SafeNetApp extends StatelessWidget {
  const SafeNetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeNet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB71C1C),
          primary: const Color(0xFFD32F2F),
          surface: const Color(0xFFFFF8F8),
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF8F8),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.splash, // <--- CHANGED THIS TO SPLASH
      routes: AppRoutes.define(),
    );
  }
}