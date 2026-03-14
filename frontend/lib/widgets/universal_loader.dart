// lib/widgets/universal_loader.dart
import 'package:flutter/material.dart';

class UniversalLoader extends StatelessWidget {
  const UniversalLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFFB71C1C), // SafeNet Danger Red
        strokeWidth: 4.0,
      ),
    );
  }
}