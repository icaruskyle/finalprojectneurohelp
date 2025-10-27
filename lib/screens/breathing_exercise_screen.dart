import 'dart:async';
import 'package:flutter/material.dart';

class BreathingExerciseScreen extends StatefulWidget {
  const BreathingExerciseScreen({super.key});

  @override
  State<BreathingExerciseScreen> createState() =>
      _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen> {
  String instruction = "Tap Start to Begin";
  int breathCount = 0;
  Timer? timer;

  void startBreathing() {
    setState(() {
      breathCount = 0;
      instruction = "Inhale deeply... 🌬️";
    });

    timer = Timer.periodic(const Duration(seconds: 4), (t) {
      setState(() {
        if (breathCount % 2 == 0) {
          instruction = "Hold... 😌";
        } else if (breathCount % 2 == 1) {
          instruction = "Exhale slowly... 💨";
        }
        breathCount++;
      });

      if (breathCount > 6) {
        timer?.cancel();
        setState(() {
          instruction = "Great job! You’ve completed your session 💜";
        });
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Breathing Exercise"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(seconds: 2),
                height: 150 +
                    (breathCount % 2 == 0 ? 50 : 0), // simulate inhale/exhale
                width: 150 +
                    (breathCount % 2 == 0 ? 50 : 0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                instruction,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: startBreathing,
                icon: const Icon(Icons.play_arrow),
                label: const Text("Start Exercise"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.deepPurple,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
