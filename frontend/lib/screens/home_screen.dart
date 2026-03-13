// lib/screens/home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import '../services/sensor_engine.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SensorEngine _sensorEngine = SensorEngine();
  
  Map<String, dynamic>? _userProfile;
  List<dynamic> _contacts = [];
  
  bool _isLoading = true;
  bool _isTriggering = false;

  // --- TIMER OVERLAY STATE ---
  Timer? _countdownTimer;
  int _secondsRemaining = 5;
  bool _showOverlay = false;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    
    // Link the sensor trigger to the UI overlay
    _sensorEngine.onTriggerAlert = () {
      if (!_showOverlay && !_isTriggering) {
        _showCancelOverlay();
      }
    };
    _sensorEngine.start();
  }

  @override
  void dispose() {
    _sensorEngine.stop();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _showCancelOverlay() {
    setState(() {
      _showOverlay = true;
      _secondsRemaining = 5;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        if (_showOverlay) {
          _handleSOS(); // Fire the actual API call
          setState(() => _showOverlay = false);
        }
      }
    });
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      ApiService.getUserProfile(),
      ApiService.getContacts(),
    ]);

    if (!mounted) return;

    setState(() {
      _userProfile = results[0] as Map<String, dynamic>?;
      _contacts = results[1] as List<dynamic>;
      _isLoading = false;
    });
  }

  Future<void> _showAddContactDialog() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Emergency Contact', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 16),
            TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), foregroundColor: Colors.white),
            onPressed: () async {
              if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                await ApiService.addContact(nameController.text, phoneController.text);
                await _fetchDashboardData(); 
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSOS() async {
    if (mounted) setState(() => _isTriggering = true);
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final success = await ApiService.triggerSOS(position.latitude, position.longitude, 55);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'SOS DISPATCHED!' : 'Trigger Failed (No Internet)'),
          backgroundColor: success ? Colors.red : Colors.orange,
        )
      );
    } catch (e) {
      print("SOS Error: $e");
    } finally {
      if (mounted) setState(() => _isTriggering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/icons/safenet_logo.svg',
              height: 30,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
            const SizedBox(width: 10),
            const Text('SafeNet', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, size: 28),
            onPressed: () => print("Open Profile"),
          ),
        ],
      ),
      body: Stack(
        children: [
          // MAIN DASHBOARD CONTENT
          _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFB71C1C)))
            : _buildDashboardUI(),

          // --- EMERGENCY CANCEL OVERLAY ---
          if (_showOverlay)
            Container(
              color: const Color(0xFFB71C1C).withOpacity(0.95),
              width: double.infinity,
              height: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 100),
                  const SizedBox(height: 24),
                  const Text("EMERGENCY DETECTED", 
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text("Sending SOS in $_secondsRemaining seconds...", 
                    style: const TextStyle(color: Colors.white70, fontSize: 18)),
                  const SizedBox(height: 60),
                  SizedBox(
                    width: 250,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFB71C1C),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                      ),
                      onPressed: () {
                        _countdownTimer?.cancel();
                        setState(() => _showOverlay = false);
                        print("❌ SOS Cancelled by user.");
                      },
                      child: const Text("I AM SAFE (CANCEL)", 
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDashboardUI() {
    return SafeArea(
      child: Column(
        children: [
          // USER DETAILS CARD
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              border: Border.all(color: Colors.red.shade100),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.red.shade50,
                  child: const Icon(Icons.person, color: Color(0xFFB71C1C)),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_userProfile?['name'] ?? 'Loading...', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(_userProfile?['email'] ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),
                ),
                if (_userProfile?['blood_group'] != null)
                  Chip(
                    label: Text(_userProfile!['blood_group'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    backgroundColor: const Color(0xFFB71C1C),
                  )
              ],
            ),
          ),

          // EMERGENCY CONTACTS
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Text('My Safe Circle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: _contacts.isEmpty
                        ? const Center(child: Text('No contacts yet'))
                        : ListView.separated(
                            itemCount: _contacts.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final contact = _contacts[index];
                              return ListTile(
                                title: Text(contact['name'] ?? 'Unknown'),
                                subtitle: Text(contact['phno'] ?? ''),
                                trailing: IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                                  onPressed: () async {
                                    setState(() => _isLoading = true);
                                    await ApiService.deleteContact(contact['_id']);
                                    await _fetchDashboardData();
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: OutlinedButton.icon(
                      onPressed: _showAddContactDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Emergency Contact'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        foregroundColor: const Color(0xFFB71C1C),
                        side: const BorderSide(color: Color(0xFFB71C1C)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // SOS BUTTON
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: GestureDetector(
              onTap: () {
                if (!_isTriggering && !_showOverlay) {
                  _showCancelOverlay(); // Manual button now uses countdown too!
                }
              },
              child: Container(
                height: 150,
                width: 150,
                decoration: BoxDecoration(
                  color: const Color(0xFFB71C1C),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.4), spreadRadius: 5, blurRadius: 20)],
                  border: Border.all(color: Colors.red.shade300, width: 3),
                ),
                child: Center(
                  child: _isTriggering
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('SOS', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}