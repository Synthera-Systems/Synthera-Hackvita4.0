// lib/screens/home_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/sensor_engine.dart';
import '../services/api_service.dart';
import '../services/mesh_service.dart';
import '../services/notification_service.dart';
import '../routes.dart'; 
import 'profile_screen.dart';
import 'fake_call_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SensorEngine _sensorEngine = SensorEngine();
  final MeshService _meshService = MeshService();
  
  Map<String, dynamic>? _userProfile;
  List<dynamic> _contacts = [];
  
  bool _isLoading = true;
  bool _isTriggering = false;

  Timer? _countdownTimer;
  int _secondsRemaining = 5;
  bool _showOverlay = false;

  final TextEditingController _callerIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _loadFakeCallerId(); 
    
    _sensorEngine.onTriggerAlert = () {
      if (!_showOverlay && !_isTriggering) {
        _showCancelOverlay();
      }
    };
    _sensorEngine.start();
    
    _meshService.onRelaySuccess = () {
      if (mounted){ 
        _showHeroModeDialog();
        
        NotificationService.showNotification(
          id: 1, 
          title: '🚨 HERO MODE ACTIVATED', 
          body: 'You successfully caught an offline SOS packet and relayed it to the authorities via your internet connection. You just saved a life.',
        );
      }
    };

    _meshService.initMesh(); 
  }

  Future<void> _loadFakeCallerId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _callerIdController.text = prefs.getString('fake_caller_id') ?? 'Dad (Emergency)';
    });
  }

  @override
  void dispose() {
    _sensorEngine.stop();
    _meshService.stopMesh(); 
    _countdownTimer?.cancel();
    _callerIdController.dispose();
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
          _handleSOS();
          setState(() => _showOverlay = false);
        }
      }
    });
  }

  void _showHeroModeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFF0D47A1), 
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_tethering, color: Colors.white, size: 64),
            const SizedBox(height: 16),
            const Text(
              'HERO MODE ACTIVATED',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'You just acted as a Mesh Relay Node! An offline user nearby triggered an SOS, and your phone successfully caught it and forwarded it to the authorities via your internet connection.',
              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0D47A1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('DISMISS', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchDashboardData() async {
    final prefs = await SharedPreferences.getInstance();

    final cachedProfile = prefs.getString('cached_profile');
    final cachedContacts = prefs.getString('cached_contacts');

    if (cachedProfile != null) {
      setState(() {
        _userProfile = jsonDecode(cachedProfile);
        _isLoading = false; 
      });
    }
    
    if (cachedContacts != null) {
      setState(() {
        _contacts = jsonDecode(cachedContacts);
      });
    }

    if (cachedProfile == null && cachedContacts == null) {
      setState(() => _isLoading = true);
    }

    try {
      final results = await Future.wait([
        ApiService.getUserProfile(),
        ApiService.getContacts(),
      ]);

      if (!mounted) return;

      final freshProfile = results[0] as Map<String, dynamic>?;
      final freshContacts = results[1] as List<dynamic>?;

      setState(() {
        if (freshProfile != null && freshProfile.isNotEmpty) {
          _userProfile = freshProfile;
          prefs.setString('cached_profile', jsonEncode(freshProfile)); 
        }
        
        if (freshContacts != null) {
          _contacts = freshContacts;
          prefs.setString('cached_contacts', jsonEncode(freshContacts)); 
        }
        _isLoading = false;
      });
      
      print("☁️ Dashboard synced with cloud and cached locally.");

    } catch (e) {
      print("🔌 Offline mode or Error: Relying on cached dashboard data. Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- FAKE CALL DIALOG ---
  void _showFakeCallSetupDialog() {
    showDialog(
      context: context,
      // FIX: Use dialogContext to avoid shadowing
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Schedule Fake Call", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Enter the caller ID you want to appear on the screen.", style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: _callerIdController,
                decoration: InputDecoration(
                  labelText: "Caller Name/ID",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext), 
              child: const Text("Cancel", style: TextStyle(color: Colors.grey))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1C1C1E), foregroundColor: Colors.white),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('fake_caller_id', _callerIdController.text);
                
                if (!mounted) return;
                
                // Pop the dialog first
                Navigator.pop(dialogContext); 
                
                // PUSH IMMEDIATELY: The Black Screen Illusion starts now.
                // Do NOT lock the phone physically. Just let it sit on the table.
                Navigator.push(
                  context, 
                  MaterialPageRoute(
                    builder: (_) => FakeCallScreen(callerId: _callerIdController.text)
                  )
                );
              },
              child: const Text("Start Simulation")
            )
          ],
        );
      }
    );
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
      
      print("Trying Layer 1 (Internet)...");
      final internetSuccess = await ApiService.triggerSOS(position.latitude, position.longitude, 55);
      
      if (internetSuccess) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SOS DISPATCHED (INTERNET)!'), backgroundColor: Colors.red)
        );

        // 2. FIRE THE SYSTEM NOTIFICATION WITH SOUND!
        NotificationService.showNotification(
          id: 2, 
          title: '🆘 HELP IS ON THE WAY', 
          body: 'Your live location and emergency alert have been successfully dispatched to your Safe Circle and the Authorities.',
        );
      } else {
        print("Internet Failed. Falling back to Layer 2 (Mesh)...");
        final meshSuccess = await _meshService.broadcastOfflineSOS(position.latitude, position.longitude, 55);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(meshSuccess ? 'SOS BROADCASTED TO MESH!' : 'SOS FAILED (NO INTERNET OR PEERS)'),
            backgroundColor: meshSuccess ? Colors.orange : Colors.grey[800],
          )
        );
      }
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
        title: GestureDetector(
          // --- THE SECRET TRIGGER ---
          onLongPress: () {
            print("🕵️ Secret Trigger: Manual Hero Mode activated.");
            _meshService.simulateRelaySuccess();
          },
          child: Row(
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
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, size: 28),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.profile, arguments: _userProfile);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFB71C1C)))
            : _buildDashboardUI(),

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showFakeCallSetupDialog, 
        backgroundColor: const Color(0xFF1C1C1E),
        icon: const Icon(Icons.phone_in_talk, color: Colors.white),
        label: const Text('Fake Call', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                      Text(_userProfile?['name'] ?? 'Unknown User', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
          Flexible(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, 
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Text('My Safe Circle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  _contacts.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: Text('No contacts yet', style: TextStyle(color: Colors.grey))),
                        )
                      : Flexible(
                          child: ListView.separated(
                            shrinkWrap: true, 
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
                  _showCancelOverlay(); 
                }
              },
              child: Container(
                height: 130, 
                width: 130,
                decoration: BoxDecoration(
                  color: const Color(0xFFB71C1C),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.4), spreadRadius: 5, blurRadius: 20)],
                  border: Border.all(color: Colors.red.shade300, width: 3),
                ),
                child: Center(
                  child: _isTriggering
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('SOS', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 60), 
        ],
      ),
    );
  }
}