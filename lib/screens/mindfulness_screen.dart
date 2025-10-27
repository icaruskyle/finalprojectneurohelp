// mindfulness_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';

class MindfulnessScreen extends StatefulWidget {
  const MindfulnessScreen({super.key});

  @override
  State<MindfulnessScreen> createState() => _MindfulnessScreenState();
}

class _MindfulnessScreenState extends State<MindfulnessScreen> {
  int step = 0;
  final List<String> steps = [
    "Find a quiet spot and sit comfortably.",
    "Take a deep breath in... and out.",
    "Notice your surroundings — the sounds, colors, and sensations.",
    "Observe your thoughts without judgment.",
    "Focus on this present moment — you are safe and calm.",
    "Well done 🌿 Take a moment to thank yourself for this pause."
  ];

  Timer? _timer;

  void startMindfulness() {
    step = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (step < steps.length - 1) {
        setState(() => step++);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mindfulness Session"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurpleAccent, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.self_improvement,
                    size: 100, color: Colors.white70),
                const SizedBox(height: 20),
                Text(
                  steps[step],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: startMindfulness,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("Start Mindfulness"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
