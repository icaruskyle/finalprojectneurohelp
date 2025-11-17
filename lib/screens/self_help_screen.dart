// self_help_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'breathing_exercise_screen.dart';
import 'mindfulness_screen.dart';
import 'journaling_screen.dart';
import 'gratitude_screen.dart';

class SelfHelpScreen extends StatelessWidget {
  const SelfHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get current user's uid
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final List<Map<String, dynamic>> resources = [
      {
        "title": "Breathing Exercise",
        "desc": "Relax your mind and body with guided deep breathing.",
        "icon": Icons.air,
        "route": const BreathingExerciseScreen(),
      },
      {
        "title": "Mindfulness",
        "desc": "Take a few minutes to stay in the present moment.",
        "icon": Icons.self_improvement,
        "route": const MindfulnessScreen(),
      },
      {
        "title": "Journaling",
        "desc": "Write down your thoughts and emotions to release stress.",
        "icon": Icons.edit_note,
        "route": const JournalingScreen(),
      },
      {
        "title": "Gratitude List",
        "desc": "Reflect on things that make you thankful today.",
        "icon": Icons.favorite,
        "route": GratitudeScreen(uid: uid), // pass uid here
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Self-Help Resources"),
        backgroundColor: Colors.deepPurple,
        elevation: 4,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurpleAccent, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: resources.length,
          itemBuilder: (context, index) {
            final resource = resources[index];

            final String title = resource['title'] as String;
            final String desc = resource['desc'] as String;
            final IconData icon = resource['icon'] as IconData;
            final Widget route = resource['route'] as Widget;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => route),
                );
              },
              child: Container(
                margin:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.7)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ListTile(
                  leading: Icon(icon, color: Colors.deepPurple, size: 36),
                  title: Text(
                    title,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple),
                  ),
                  subtitle: Text(desc, style: const TextStyle(fontSize: 14)),
                  trailing:
                  const Icon(Icons.arrow_forward_ios, color: Colors.deepPurple),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
