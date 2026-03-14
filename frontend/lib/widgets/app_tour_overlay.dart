import 'package:flutter/material.dart';

class AppTourOverlay extends StatefulWidget {
  final VoidCallback onComplete;
  const AppTourOverlay({super.key, required this.onComplete});

  @override
  State<AppTourOverlay> createState() => _AppTourOverlayState();
}

class _AppTourOverlayState extends State<AppTourOverlay> {
  int _currentStep = 0;

  final List<Map<String, dynamic>> _steps = [
    {
      "title": "Emergency SOS",
      "description": "In immediate danger? Tap the SOS button. We'll use Internet first, then automatically switch to Mesh if you're offline.",
      "icon": Icons.emergency,
    },
    {
      "title": "Safe Circle",
      "description": "Add your trusted contacts here. They receive your live location and status the moment help is triggered.",
      "icon": Icons.people_alt,
    },
    {
      "title": "Fake Call Simulation",
      "description": "Tap 'Fake Call' to schedule a realistic incoming call—a perfect excuse to step away from uncomfortable situations.",
      "icon": Icons.phone_callback,
    },
    {
      "title": "Mesh Hero Mode",
      "description": "Keep the app active to become a Relay Node. Your phone can catch and forward SOS signals from others who are offline.",
      "icon": Icons.wifi_tethering,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];

    return Material(
      color: Colors.black.withOpacity(0.85),
      child: InkWell(
        onTap: () {
          setState(() {
            if (_currentStep < _steps.length - 1) {
              _currentStep++;
            } else {
              widget.onComplete();
            }
          });
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(step['icon'], color: Colors.white, size: 80),
              const SizedBox(height: 30),
              Text(
                step['title'],
                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                step['description'],
                style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
              const Text(
                "TAP TO CONTINUE",
                style: TextStyle(color: Colors.redAccent, letterSpacing: 2, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_steps.length, (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentStep == index ? Colors.red : Colors.white24,
                  ),
                )),
              )
            ],
          ),
        ),
      ),
    );
  }
}