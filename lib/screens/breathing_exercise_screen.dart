import 'dart:async';
import 'package:flutter/material.dart';

class BreathingExerciseScreen extends StatefulWidget {
  final bool isDarkMode;
  const BreathingExerciseScreen({super.key, this.isDarkMode = false});

  @override
  State<BreathingExerciseScreen> createState() =>
      _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen>
    with SingleTickerProviderStateMixin {
  String instruction = "Tap Start to Begin";
  int stepCount = 0; // counts inhale, hold, exhale steps
  Timer? timer;
  double circleSize = 150;
  Color circleColor = Colors.white70;

  void startBreathing() {
    setState(() {
      stepCount = 0;
      instruction = "Inhale deeply... 🌬️";
      circleSize = 200;
    });

    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 4), (t) {
      setState(() {
        if (stepCount % 3 == 0) {
          instruction = "Inhale deeply... 🌬️";
          circleSize = 200;
          circleColor = Colors.white70;
        } else if (stepCount % 3 == 1) {
          instruction = "Hold... 😌";
          circleSize = 180;
          circleColor = Colors.white54;
        } else {
          instruction = "Exhale slowly... 💨";
          circleSize = 150;
          circleColor = Colors.white30;
        }
        stepCount++;
      });

      if (stepCount > 8) {
        timer?.cancel();
        setState(() {
          instruction = "Great job! You’ve completed your session 💜";
          circleSize = 150;
          circleColor = Colors.white70;
        });
      }
    });
  }

  void resetBreathing() {
    timer?.cancel();
    setState(() {
      stepCount = 0;
      instruction = "Tap Start to Begin";
      circleSize = 150;
      circleColor = Colors.white70;
    });
  }

  @override
  void dispose() {
    timer?.cancel();
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
      colors: [Colors.deepPurple, Colors.purpleAccent],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Breathing Exercise"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(seconds: 4),
                curve: Curves.easeInOut,
                height: circleSize,
                width: circleSize,
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 30),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 800),
                opacity: 1.0,
                child: Text(
                  instruction,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: startBreathing,
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
                    onPressed: resetBreathing,
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
    );
  }
}
