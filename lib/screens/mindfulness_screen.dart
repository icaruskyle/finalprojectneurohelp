import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MindfulnessScreen extends StatefulWidget {
  final bool isDarkMode;
  const MindfulnessScreen({super.key, this.isDarkMode = false});

  @override
  State<MindfulnessScreen> createState() => _MindfulnessScreenState();
}

class _MindfulnessScreenState extends State<MindfulnessScreen>
    with SingleTickerProviderStateMixin {
  int step = 0;
  int sessionCount = 0; // user's completed sessions
  Timer? _timer;
  late AnimationController _particleController;

  final List<String> steps = [
    "Find a quiet spot and sit comfortably.",
    "Take a deep breath in... and out.",
    "Notice your surroundings — the sounds, colors, and sensations.",
    "Observe your thoughts without judgment.",
    "Focus on this present moment — you are safe and calm.",
    "Well done 🌿 Take a moment to thank yourself for this pause."
  ];

  final List<Offset> _particles = [];
  final random = Random();

  @override
  void initState() {
    super.initState();
    _fetchSessionCount();

    // particle animation
    for (int i = 0; i < 50; i++) {
      _particles.add(Offset(random.nextDouble(), random.nextDouble()));
    }
    _particleController =
    AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..repeat();
  }

  Future<void> _fetchSessionCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('mindfulness_sessions')
          .get();
      setState(() {
        sessionCount = snapshot.docs.length;
      });
    }
  }

  void startMindfulness() {
    setState(() => step = 0);
    _timer?.cancel();
    DateTime startTime = DateTime.now();

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (step < steps.length - 1) {
        setState(() => step++);
      } else {
        timer.cancel();
        _saveSessionToFirebase(
            duration: DateTime.now().difference(startTime).inSeconds);
        setState(() => sessionCount++);
      }
    });
  }

  void resetMindfulness() {
    _timer?.cancel();
    setState(() => step = 0);
  }

  Future<void> _saveSessionToFirebase({required int duration}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('mindfulness_sessions')
          .add({
        'timestamp': DateTime.now(),
        'duration': duration,
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
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
        child: Stack(
          children: [
            // Floating particles
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter:
                  ParticlePainter(_particles, _particleController.value, isDark),
                  size: MediaQuery.of(context).size,
                );
              },
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Session counter
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
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
                            backgroundColor: Colors.deepPurpleAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                            elevation: 8,
                          ),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton.icon(
                          onPressed: resetMindfulness,
                          icon: const Icon(Icons.restart_alt),
                          label: const Text("Reset"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                            elevation: 8,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
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
