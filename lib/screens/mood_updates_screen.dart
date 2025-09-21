import 'package:flutter/material.dart';

class MoodUpdatesScreen extends StatelessWidget {
  const MoodUpdatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mood Updates"),
        backgroundColor: Colors.deepPurple,
      ),
      body: const Center(
        child: Text(
          "Mood Updates feature coming soon!",
          style: TextStyle(fontSize: 18, color: Colors.deepPurple),
        ),
      ),
    );
  }
}
