import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class GratitudeScreen extends StatefulWidget {
  const GratitudeScreen({super.key});

  @override
  State<GratitudeScreen> createState() => _GratitudeScreenState();
}

class _GratitudeScreenState extends State<GratitudeScreen> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  late String uid;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      uid = user.uid;
      _initNotifications();
    }
  }

  // ---------- Initialize Notifications ----------
  void _initNotifications() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Manila'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final settings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(settings);

    _scheduleDailyReminder();
  }

  void _scheduleDailyReminder() async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduledTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, 20, 0);

    await _notificationsPlugin.zonedSchedule(
      0,
      '🌸 Daily Gratitude Reminder',
      'Take a moment to write your 3 gratitude items today!',
      scheduledTime.isAfter(now) ? scheduledTime : scheduledTime.add(const Duration(days: 1)),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'gratitude_channel',
          'Daily Gratitude',
          channelDescription: 'Reminder to write your gratitude list',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> addGratitude(String text) async {
    if (text.isEmpty) return;
    _controller.clear();

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('gratitude')
        .add({'text': text, 'timestamp': FieldValue.serverTimestamp()});

    _showTopNotification("✅ Gratitude added!");
  }

  Future<void> deleteGratitude(String docId) async {
    await _firestore.collection('users').doc(uid).collection('gratitude').doc(docId).delete();
    _showTopNotification("🗑️ Gratitude deleted!", isError: true);
  }

  // ---------- Top Notification ----------
  void _showTopNotification(String message, {bool isError = false}) {
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
          color: isError ? Colors.red[400] : Colors.deepPurple[400],
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
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gratitude List"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [Colors.deepPurple.shade800, Colors.black87]
                : [Colors.deepPurple, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                "🌸 Write down 3 things you’re grateful for today.",
                style: TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: "I'm grateful for...",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => addGratitude(_controller.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.deepPurple,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(14),
                    ),
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('users')
                      .doc(uid)
                      .collection('gratitude')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return const Center(
                        child: Text(
                          "No gratitude items yet.",
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final text = doc['text'] ?? '';
                        return Dismissible(
                          key: Key(doc.id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => deleteGratitude(doc.id),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: Colors.redAccent,
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          child: Card(
                            color: Colors.white.withOpacity(0.9),
                            child: ListTile(
                              leading: const Icon(Icons.favorite, color: Colors.deepPurple),
                              title: Text(text),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
