// self_help_screen.dart
import 'package:flutter/material.dart';
import 'breathing_exercise_screen.dart';
import 'mindfulness_screen.dart';
import 'journaling_screen.dart';
import 'gratitude_screen.dart';

class SelfHelpScreen extends StatelessWidget {
  const SelfHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        "route": const GratitudeScreen(),
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
          itemCount: resources.length,
          itemBuilder: (context, index) {
            final resource = resources[index];

            final String title = resource['title'] as String;
            final String desc = resource['desc'] as String;
            final IconData icon = resource['icon'] as IconData;
            final Widget? route = resource['route'] as Widget?;

            return Card(
              color: Colors.white.withOpacity(0.9),
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 6,
              child: ListTile(
                contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                leading: Icon(icon, color: Colors.deepPurple, size: 36),
                title: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                subtitle: Text(desc, style: const TextStyle(fontSize: 14)),
                trailing: const Icon(Icons.arrow_forward_ios,
                    color: Colors.deepPurple),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => route!),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
