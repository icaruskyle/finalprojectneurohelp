import 'package:flutter/material.dart';

class CommunitySupportScreen extends StatelessWidget {
  const CommunitySupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Community Support"),
        backgroundColor: Colors.deepPurple,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          "🤝 Join support groups, share experiences, and connect with others in the NeuroHelp community.",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
