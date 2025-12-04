// self_help_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'theme_notifier.dart'; // adjust path if needed

// Import your screens
import 'breathing_exercise_screen.dart';
import 'mindfulness_screen.dart';
import 'journaling_screen.dart';
import 'gratitude_screen.dart';

class SelfHelpScreen extends StatelessWidget {
  const SelfHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get current user's uid (if needed by routes)
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    // READ GLOBAL THEME
    final isDarkMode = Provider.of<ThemeNotifier>(context).isDarkMode;

    // Dynamic colors
    final Color accent = isDarkMode ? Colors.purpleAccent : Colors.deepPurple;
    final Color tileBg = isDarkMode ? const Color(0xFF14141A) : Colors.white.withOpacity(0.92);
    final Color tileShadow = isDarkMode ? Colors.black54 : Colors.black26;
    final Color titleColor = Theme.of(context).textTheme.titleLarge?.color ?? (isDarkMode ? Colors.white : Colors.black87);
    final Color subtitleColor = Theme.of(context).textTheme.bodyMedium?.color ?? (isDarkMode ? Colors.white70 : Colors.black54);
    final Color scaffoldStart = isDarkMode ? const Color(0xFF0F0F14) : Colors.deepPurpleAccent;
    final Color scaffoldEnd = isDarkMode ? const Color(0xFF1A1A22) : Colors.purple;

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
        "route": GratitudeScreen(), // pass uid if needed
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Self-Help Resources"),
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.deepPurple,
        elevation: 4,
        foregroundColor: isDarkMode ? Colors.white : Colors.white,
      ),

      // Background gradient adapts to theme
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [scaffoldStart, scaffoldEnd],
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
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: tileBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: tileShadow,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                  border: isDarkMode ? Border.all(color: Colors.white10) : null,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDarkMode ? Colors.white10 : accent.withOpacity(0.12),
                    ),
                    child: Icon(icon, color: accent, size: 28),
                  ),
                  title: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  subtitle: Text(
                    desc,
                    style: TextStyle(fontSize: 14, color: subtitleColor),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, color: accent),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
