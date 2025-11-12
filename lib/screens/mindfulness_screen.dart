// mindfulness_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';

class MindfulnessScreen extends StatefulWidget {
  final bool isDarkMode;
  const MindfulnessScreen({super.key, this.isDarkMode = false});

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
    setState(() => step = 0);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (step < steps.length - 1) {
        setState(() => step++);
      } else {
        timer.cancel();
      }
    });
  }

  void resetMindfulness() {
    _timer?.cancel();
    setState(() => step = 0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final bgGradient = isDark
        ? const LinearGradient(
      colors: [Color(0xFF1C1C1E), Color(0xFF2C2C2E)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    )
        : const LinearGradient(
      colors: [Colors.deepPurpleAccent, Colors.purple],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mindfulness Session"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(seconds: 1),
                  curve: Curves.easeInOut,
                  height: 100 + (step * 5),
                  width: 100 + (step * 5),
                  child: const Icon(Icons.self_improvement,
                      size: 100, color: Colors.white70),
                ),
                const SizedBox(height: 20),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  child: Text(
                    steps[step],
                    key: ValueKey(step),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 30),
                LinearProgressIndicator(
                  value: (step + 1) / steps.length,
                  backgroundColor: Colors.white24,
                  color: Colors.white,
                  minHeight: 6,
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: startMindfulness,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text("Start"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton.icon(
                      onPressed: resetMindfulness,
                      icon: const Icon(Icons.restart_alt),
                      label: const Text("Reset"),
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
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
