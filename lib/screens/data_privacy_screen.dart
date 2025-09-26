import 'package:flutter/material.dart';

class DataPrivacyScreen extends StatelessWidget {
  const DataPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Data Privacy"),
        backgroundColor: Colors.deepPurple,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          "Your privacy is important to us. NeuroHelp follows strict policies "
          "to ensure that your data is safe, encrypted, and only used for "
          "improving your experience.\n\n- We do not sell your data.\n"
          "- You can request data deletion anytime.\n"
          "- Only authorized staff can access your records.",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
