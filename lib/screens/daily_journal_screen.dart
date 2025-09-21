import 'package:flutter/material.dart';

class DailyJournalScreen extends StatelessWidget {
  const DailyJournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Journal"),
        backgroundColor: Colors.deepPurple,
      ),
      body: const Center(
        child: Text(
          "Daily Journal feature coming soon!",
          style: TextStyle(fontSize: 18, color: Colors.deepPurple),
        ),
      ),
    );
  }
}
