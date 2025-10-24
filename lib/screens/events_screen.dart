import 'package:flutter/material.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upcoming Events"),
        backgroundColor: Colors.deepPurple,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          "📅 Here you can view upcoming mental health awareness events, workshops, and community activities.",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
