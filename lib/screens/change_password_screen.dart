import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool codeSent = false;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null && user.email != null) {
      _emailController.text = user.email!;
    }
  }

  // Generate a 6-digit code
  String _generateCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Send code to Firestore
  Future<void> _sendCode() async {
    final user = _auth.currentUser;
    if (user != null) {
      final code = _generateCode();
      await _firestore.collection('password_reset_codes').doc(user.uid).set({
        'code': code,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // In a real app, send this code via email using Cloud Functions or SMTP
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Confirmation code: $code")),
      );

      setState(() => codeSent = true);
    }
  }

  // Verify code and update password
  Future<void> _verifyAndChangePassword() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final enteredCode = _codeController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    final doc = await _firestore.collection('password_reset_codes').doc(user.uid).get();
    if (!doc.exists || doc['code'] != enteredCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid confirmation code")),
      );
      return;
    }

    try {
      await user.updatePassword(newPassword);
      await _firestore.collection('password_reset_codes').doc(user.uid).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password changed successfully!")),
      );
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _codeController.clear();
      setState(() => codeSent = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Change Password"),
        backgroundColor: Colors.deepPurple,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            color: Colors.white.withOpacity(0.9),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _emailController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: "Registered Email",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!codeSent)
                    ElevatedButton(
                      onPressed: _sendCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Send Confirmation Code"),
                    ),
                  if (codeSent) ...[
                    TextField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: "Enter Confirmation Code",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "New Password",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "Confirm New Password",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _verifyAndChangePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Update Password"),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
