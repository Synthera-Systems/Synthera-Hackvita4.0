// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _contacts = [];
  bool _isLoadingContacts = true;
  bool _isTriggering = false;

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    setState(() => _isLoadingContacts = true);
    final contacts = await ApiService.getContacts();
    setState(() {
      _contacts = contacts;
      _isLoadingContacts = false;
    });
  }

  // Dialog to Add a New Contact
  Future<void> _showAddContactDialog() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                Navigator.pop(context);
                await ApiService.addContact(nameController.text, phoneController.text);
                _fetchContacts(); // Refresh list
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Handle the giant SOS Button press
  Future<void> _handleSOS() async {
    setState(() => _isTriggering = true);

    try {
      // 1. Check GPS Permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception("Location permissions denied");
      }

      // 2. Get Live Location
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      // 3. Fire the Trigger API
      final success = await ApiService.triggerSOS(
        position.latitude, 
        position.longitude, 
        55 // Mocked battery level for the hackathon MVP
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SOS TRIGGERED SUCCESSFULLY!'), backgroundColor: Colors.red));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to trigger SOS over Internet.'), backgroundColor: Colors.orange));
        // TODO: Fallback to Layer 2 (SMS) or Layer 3 (Mesh) here!
      }
    } catch (e) {
      print("SOS Error: $e");
    } finally {
      setState(() => _isTriggering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SafeNet Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // PROFILE CARD
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.shade100,
                    child: const Icon(Icons.person, color: Color(0xFFB71C1C)),
                  ),
                  title: const Text('Dhritiman Saikia', style: TextStyle(fontWeight: FontWeight.bold)), // Hardcoded for demo
                  subtitle: const Text('dhritiman.saikia.11b.244@gmail.com'),
                ),
              ),
            ),

            // EMERGENCY CONTACTS LIST
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Emergency Contacts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle, color: Color(0xFFD32F2F), size: 32),
                              onPressed: _showAddContactDialog,
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: _isLoadingContacts
                            ? const Center(child: CircularProgressIndicator())
                            : _contacts.isEmpty
                                ? const Center(child: Text('No contacts added yet.'))
                                : ListView.builder(
                                    itemCount: _contacts.length,
                                    itemBuilder: (context, index) {
                                      final contact = _contacts[index];
                                      return ListTile(
                                        leading: const Icon(Icons.contact_phone),
                                        title: Text(contact['name'] ?? 'Unknown'),
                                        subtitle: Text(contact['phno'] ?? ''),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.grey),
                                          onPressed: () async {
                                            await ApiService.deleteContact(contact['_id']);
                                            _fetchContacts();
                                          },
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // MASSIVE SOS BUTTON
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: GestureDetector(
                onTap: _isTriggering ? null : _handleSOS,
                child: Container(
                  height: 180,
                  width: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB71C1C),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.red.withOpacity(0.5), spreadRadius: 10, blurRadius: 20, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Center(
                    child: _isTriggering
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('SOS', style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 4)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}