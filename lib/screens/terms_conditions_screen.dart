import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Terms and Conditions"),
        backgroundColor: Colors.deepPurple,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            "Welcome to NeuroHelp.\n\n"
            "By using this app, you agree to the following:\n\n"
            "1. You are responsible for the information you provide.\n"
            "2. The app provides mental health support but is not a substitute "
            "for professional medical advice.\n"
            "3. Your data is handled securely and in compliance with applicable laws.\n"
            "4. Misuse of the platform may lead to account suspension.\n\n"
            "Thank you for trusting NeuroHelp.",
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
