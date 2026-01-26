import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';

class MindfulnessScreen extends StatefulWidget {
  final bool isDarkMode;
  const MindfulnessScreen({super.key, this.isDarkMode = false});

  @override
  State<MindfulnessScreen> createState() => _MindfulnessScreenState();
}

class _MindfulnessScreenState extends State<MindfulnessScreen>
    with SingleTickerProviderStateMixin {
  int step = 0;
  Timer? _timer;
  late AnimationController _particleController;

  bool isRunning = false;
  int sessionCount = 0;
  late String uid;
  int get totalSteps => steps.length;

  final FlutterTts tts = FlutterTts();

  final AudioPlayer _audioPlayer = AudioPlayer();

  final List<String> steps = [
    "Find a quiet and comfortable position. Sit or lie down.",
    "Gently close your eyes if you feel comfortable.",
    "Take a slow, deep breath in through your nose.",
    "Feel your lungs expanding as you inhale.",
    "Slowly breathe out through your mouth, releasing tension.",
    "Notice the weight of your body against the chair or floor.",
    "Bring attention to your hands. Feel their warmth and texture.",
    "Relax your shoulders. Let them gently drop.",
    "Focus on your breathing. Inhale… and exhale.",
    "Observe the sounds around you without judging them.",
    "If your mind wanders, gently bring it back to your breath.",
    "Scan your body from head to toe, releasing any tension.",
    "Feel your feet grounded and connected to the earth.",
    "Acknowledge your thoughts, then let them pass.",
    "Stay present in this moment. You are safe and calm.",
    "Take one final deep breath in… and slowly breathe out.",
    "Well done 🌿 Thank yourself for this mindful pause."
  ];

  final List<Offset> _particles = [];
  final random = Random();

  final List<int> sessionOptions = [5, 10, 15];
  int selectedMinutes = 5;
  int _stepDurationSeconds = 5;

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;
    uid = user?.uid ?? "";

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
    if (uid.isEmpty) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('mindfulness_sessions')
        .get();
    setState(() {
      sessionCount = snapshot.docs.length;
    });
  }

  Future<void> _speak(String text) async {
    await tts.stop();
    await tts.speak(text);
  }

  void startMindfulness() async {
    if (isRunning) return;

    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource("audio/Healing.mp3"));

    setState(() {
      isRunning = true;
      step = 0;
    });
    _speak(steps[step]);

    DateTime startTime = DateTime.now(  );
    _timer?.cancel();

    _stepDurationSeconds =
        (selectedMinutes * 60 ~/ totalSteps).clamp(7, 90);



    _timer = Timer.periodic(Duration(seconds: _stepDurationSeconds), (timer) async {
      if (!mounted || !isRunning) {
        timer.cancel();
        return;
      }

      if (step < steps.length - 1) {
        setState(() => step++);
        _speak(steps[step]);
      } else {
        timer.cancel();
        setState(() => isRunning = false);
        await _audioPlayer.stop();

        final duration = DateTime.now().difference(startTime).inSeconds;
        await _saveSessionToFirebase(duration: duration);
        _showTopNotification("🌿 Mindfulness session completed!");
        _speak("Mindfulness session completed");
      }
    });
  }

  void resetMindfulness() async {
    _timer?.cancel();
    tts.stop();
    await _audioPlayer.stop();
    setState(() {
      step = 0;
      isRunning = false;
    });
  }

  Future<void> _saveSessionToFirebase({required int duration}) async {
    if (uid.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('mindfulness_sessions')
        .add({
      'timestamp': DateTime.now(),
      'duration': duration,
      'sessionMinutes': selectedMinutes,
    });
    setState(() {
      sessionCount++;
    });
  }

  void _showTopNotification(String message) {
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50,
        left: 20,
        right: 20,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(12),
          color: Colors.deepPurple[400],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3)).then((_) => overlayEntry.remove());
  }

  @override
  void dispose() {
    _timer?.cancel();
    tts.stop();
    _particleController.dispose();
    _audioPlayer.dispose();
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
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ParticlePainter(_particles, _particleController.value, isDark),
                  size: MediaQuery.of(context).size,
                );
              },
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    /// SESSION SELECTOR
                    Text(
                      "Session Duration",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: sessionOptions.map((min) {
                        final isSelected = min == selectedMinutes;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedMinutes = min;
                              if (isRunning) resetMindfulness();
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.blue
                                  : (isDark ? Colors.grey[800] : Colors.grey[300]),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              "$min min",
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? Colors.white : Colors.black),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 30),

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

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: isRunning ? null : startMindfulness,
                          icon: Icon(isRunning ? Icons.hourglass_top : Icons.play_arrow),
                          label: Text(isRunning ? "Running" : "Start"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            isRunning ? Colors.grey : Colors.deepPurpleAccent,
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
                    ),
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
      ..color = (isDark ? Colors.purpleAccent : Colors.white70).withOpacity(0.3)
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
