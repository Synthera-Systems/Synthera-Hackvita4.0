// lib/screens/fake_call_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';

enum CallState { waiting, ringing, active }

class FakeCallScreen extends StatefulWidget {
  final String callerId;

  const FakeCallScreen({super.key, required this.callerId});

  @override
  State<FakeCallScreen> createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends State<FakeCallScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  CallState _callState = CallState.waiting; 
  
  StreamSubscription<Position>? _positionStream;
  
  // Real ticking timer for the active call
  Timer? _activeCallTimer;
  int _activeCallSeconds = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _startBlackScreenTimer();
    _startLiveLocationStream();
  }

  void _startLiveLocationStream() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, 
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      ApiService.sendLiveLocation(position.latitude, position.longitude);
    });
  }

  void _startBlackScreenTimer() async {
    await Future.delayed(const Duration(seconds: 7));
    if (mounted) {
      setState(() {
        _callState = CallState.ringing; 
      });
      _playRingtone();
    }
  }

  Future<void> _playRingtone() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource('audio/ringtone.mp3'));
  }

  void _acceptCall() {
    _audioPlayer.stop();
    setState(() {
      _callState = CallState.active;
    });

    // Start the active call timer
    _activeCallTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _activeCallSeconds++;
        });
      }
    });
  }

  void _endCall() {
    _audioPlayer.stop();
    _activeCallTimer?.cancel();
    Navigator.pop(context); 
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    _positionStream?.cancel();
    _activeCallTimer?.cancel();
    
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // Helper to format seconds into MM:SS
  String get _formattedTime {
    final minutes = (_activeCallSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_activeCallSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_callState == CallState.waiting) {
      return const Scaffold(
        backgroundColor: Colors.black, 
        body: SizedBox.expand(), 
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E), // Deep iOS grey
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            const Text(
              'Incoming Call',
              style: TextStyle(color: Colors.white54, fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              widget.callerId, 
              style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w400),
            ),
            
            // Show either nothing (ringing) or the ticking timer (active)
            const SizedBox(height: 10),
            Text(
              _callState == CallState.active ? _formattedTime : '', 
              style: const TextStyle(color: Colors.white54, fontSize: 18),
            ),

            const Spacer(),
            
            // --- ACTIVE CALL CONTROLS GRID ---
            if (_callState == CallState.active)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSecondaryButton(Icons.mic_off_outlined, 'mute'),
                        _buildSecondaryButton(Icons.dialpad, 'keypad'),
                        _buildSecondaryButton(Icons.volume_up_outlined, 'speaker'),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSecondaryButton(Icons.add, 'add call'),
                        _buildSecondaryButton(Icons.videocam_outlined, 'FaceTime'),
                        _buildSecondaryButton(Icons.person_outline, 'contacts'),
                      ],
                    ),
                  ],
                ),
              ),

            // --- BOTTOM PRIMARY ACTIONS ---
            Padding(
              padding: const EdgeInsets.only(left: 40, right: 40, bottom: 60, top: 40),
              child: Row(
                mainAxisAlignment: _callState == CallState.active ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
                children: [
                  if (_callState == CallState.ringing)
                    _buildPrimaryButton(color: Colors.red, icon: Icons.call_end, label: 'Decline', onTap: _endCall),
                  
                  if (_callState == CallState.ringing)
                    _buildPrimaryButton(color: Colors.green, icon: Icons.call, label: 'Accept', onTap: _acceptCall),
                  
                  if (_callState == CallState.active)
                    _buildPrimaryButton(color: Colors.red, icon: Icons.call_end, label: 'End', onTap: _endCall),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // The large solid colored buttons (Accept / Decline / End)
  Widget _buildPrimaryButton({required Color color, required IconData icon, required String label, required VoidCallback onTap}) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 75,
            width: 75,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 36),
          ),
        ),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ],
    );
  }

  // The smaller, translucent utility buttons (Mute, Speaker, Keypad, etc.)
  Widget _buildSecondaryButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          height: 65,
          width: 65,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15), // Translucent glass effect
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 30),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      ],
    );
  }
}