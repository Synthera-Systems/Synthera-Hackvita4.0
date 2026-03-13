// lib/screens/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();
  final _markController = TextEditingController();

  String? _selectedGender;
  String? _selectedBloodGroup;

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    _markController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Defines the modern, rounded border for all input fields
    final _modernBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0), // Smooth, modern rounded corners
      borderSide: const BorderSide(color: Colors.grey),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Create Account', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFFB71C1C),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar Upload (Demo UI)
              Center(
                child: Stack(
                  children: [
                    ClipOval(
                      child: SvgPicture.asset(
                        'assets/icons/default_avatar.svg',
                        height: 100,
                        width: 100,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFD32F2F),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name', 
                  border: _modernBorder,
                  enabledBorder: _modernBorder,
                ),
              ),
              const SizedBox(height: 16),

              // Email (Verification button removed)
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email', 
                  border: _modernBorder,
                  enabledBorder: _modernBorder,
                ),
              ),
              const SizedBox(height: 16),

              // Phone (Verification button removed)
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number', 
                  border: _modernBorder,
                  enabledBorder: _modernBorder,
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password', 
                  border: _modernBorder,
                  enabledBorder: _modernBorder,
                ),
              ),
              const SizedBox(height: 16),

              // Age and Gender Row
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Age', 
                        border: _modernBorder,
                        enabledBorder: _modernBorder,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Gender', 
                        border: _modernBorder,
                        enabledBorder: _modernBorder,
                      ),
                      value: _selectedGender,
                      items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                      onChanged: (val) => setState(() => _selectedGender = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Blood Group', 
                  border: _modernBorder,
                  enabledBorder: _modernBorder,
                ),
                value: _selectedBloodGroup,
                items: _bloodGroups.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                onChanged: (val) => setState(() => _selectedBloodGroup = val),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _markController,
                decoration: InputDecoration(
                  labelText: 'Identification Mark', 
                  hintText: 'e.g. Scar on left eyebrow',
                  border: _modernBorder,
                  enabledBorder: _modernBorder,
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Match the inputs
                  ),
                ),
                onPressed: () {
                  // Build JSON payload here later
                  print("Create Account Tapped");
                },
                child: const Text('CREATE ACCOUNT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}