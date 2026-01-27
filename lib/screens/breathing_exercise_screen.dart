import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_tts/flutter_tts.dart';

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
  int stepCount = 0;
  Timer? timer;
  double circleSize = 150;
  Color circleColor = Colors.purpleAccent.withOpacity(0.7);
  late AnimationController _particleController;
  final Random random = Random();
  final List<Offset> _particles = [];

  int sessionCount = 0;
  bool isRunning = false;

  final FlutterTts tts = FlutterTts();

  @override
  void initState() {
    super.initState();

    tts.setLanguage("en-US");
    tts.setSpeechRate(0.45);

    for (int i = 0; i < 50; i++) {
      _particles.add(Offset(random.nextDouble(), random.nextDouble()));
    }

    _particleController =
    AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..repeat();

    _fetchSessionCount();
  }

  Future<void> _fetchSessionCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('breathing_sessions')
          .get();

      setState(() {
        sessionCount = snapshot.docs.length;
      });
    }
  }

  Future speak(String text) async {
    await tts.stop();
    await tts.speak(text);
  }

  void startBreathing() {
    if (isRunning) return;

    setState(() {
      isRunning = true;
      stepCount = 0;
      instruction = "Inhale deeply... 🌬️";
      circleSize = 200;
    });

    speak("Inhale");

    timer?.cancel();
    DateTime startTime = DateTime.now();
    int secondsPerStep = 4;

    timer = Timer.periodic(Duration(seconds: secondsPerStep), (t) {
      if (!mounted) return;

      if (!isRunning) {
        t.cancel();
        return;
      }

      setState(() {
        if (stepCount % 3 == 0) {
          instruction = "Inhale deeply... 🌬️";
          circleSize = 200;
          circleColor = Colors.purpleAccent.withOpacity(0.8);
          speak("Inhale");
        } else if (stepCount % 3 == 1) {
          instruction = "Hold... 😌";
          circleSize = 180;
          circleColor = Colors.deepPurple.withOpacity(0.7);
          speak("Hold");
        } else {
          instruction = "Exhale slowly... 💨";
          circleSize = 150;
          circleColor = Colors.deepPurpleAccent.withOpacity(0.6);
          speak("Exhale");
        }
        stepCount++;
      });

      if (stepCount > 8) {
        t.cancel();
        setState(() {
          isRunning = false;
          instruction = "Great job! 💜 Session completed.";
          circleSize = 150;
        });

        speak("Great job. Session completed.");

        _saveSessionToFirebase(
            duration: DateTime.now().difference(startTime).inSeconds);

        sessionCount++;
      }
    });
  }

  void stopBreathing() {
    if (!isRunning) return;

    timer?.cancel();
    tts.stop();

    setState(() {
      isRunning = false;
      instruction = "Session stopped.";
      circleSize = 150;
      circleColor = Colors.purpleAccent.withOpacity(0.7);
    });
  }

  Future<void> _saveSessionToFirebase({required int duration}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('breathing_sessions')
          .add({
        'timestamp': DateTime.now(),
        'duration': duration,
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    tts.stop();
    _particleController.dispose();
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
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ParticlePainter(
                      _particles, _particleController.value, isDark),
                  size: MediaQuery.of(context).size,
                );
              },
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Sessions Completed: $sessionCount",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  AnimatedContainer(
                    duration: const Duration(seconds: 4),
                    curve: Curves.easeInOut,
                    height: circleSize,
                    width: circleSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          circleColor,
                          circleColor.withOpacity(0.4),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: circleColor.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        )
                      ],
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
                    onPressed: () {
                      isRunning ? stopBreathing() : startBreathing();
                    },
                    icon: Icon(isRunning ? Icons.stop : Icons.play_arrow),
                    label: Text(isRunning ? "Stop" : "Start"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isRunning
                          ? Colors.redAccent
                          : Colors.deepPurpleAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      shadowColor: Colors.purpleAccent,
                      elevation: 8,
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<Offset> particles;
  final double progress;
  final bool isDark;
  ParticlePainter(this.particles, this.progress, this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color =
      (isDark ? Colors.purpleAccent : Colors.white70).withOpacity(0.3)
      ..style = PaintingStyle.fill;

    for (var p in particles) {
      final dx = (p.dx + progress) % 1 * size.width;
      final dy = (p.dy + progress) % 1 * size.height;
      canvas.drawCircle(Offset(dx, dy), 4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}
