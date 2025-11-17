// gratitude_screen.dart
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
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  List<String> gratitudeList = [];
  late String uid;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      uid = user.uid;
      _loadGratitudeList();
      _initNotification();
    }
  }

  // ---------- Initialize Notifications ----------
  void _initNotification() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Manila'));

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    _scheduleDailyReminder();
  }

  void _scheduleDailyReminder() async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduledTime =
    tz.TZDateTime(tz.local, now.year, now.month, now.day, 20, 0);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      '🌸 Daily Gratitude Reminder',
      'Take a moment to write your 3 gratitude items today!',
      scheduledTime.isAfter(now)
          ? scheduledTime
          : scheduledTime.add(const Duration(days: 1)),
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
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ---------- Load Gratitude List from Firestore ----------
  void _loadGratitudeList() async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('gratitude')
        .orderBy('timestamp', descending: true)
        .get();

    setState(() {
      gratitudeList =
          snapshot.docs.map((doc) => doc['text'].toString()).toList();
    });
  }

  // ---------- Add Gratitude ----------
  void addGratitude() async {
    if (_controller.text.isEmpty) return;

    final text = _controller.text;
    _controller.clear();

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('gratitude')
        .add({'text': text, 'timestamp': FieldValue.serverTimestamp()});

    setState(() {
      gratitudeList.insert(0, text);
    });
  }

  // ---------- Delete Gratitude ----------
  void deleteGratitude(int index) async {
    final query = await _firestore
        .collection('users')
        .doc(uid)
        .collection('gratitude')
        .where('text', isEqualTo: gratitudeList[index])
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.delete();
    }

    setState(() {
      gratitudeList.removeAt(index);
    });
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
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: addGratitude,
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
                child: gratitudeList.isEmpty
                    ? const Center(
                  child: Text(
                    "No gratitude items yet.",
                    style: TextStyle(color: Colors.white70),
                  ),
                )
                    : ListView.builder(
                  itemCount: gratitudeList.length,
                  itemBuilder: (context, index) {
                    return Dismissible(
                      key: Key(gratitudeList[index]),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => deleteGratitude(index),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.redAccent,
                        child: const Icon(Icons.delete,
                            color: Colors.white),
                      ),
                      child: Card(
                        color: Colors.white.withOpacity(0.9),
                        child: ListTile(
                          leading: const Icon(Icons.favorite,
                              color: Colors.deepPurple),
                          title: Text(gratitudeList[index]),
                        ),
                      ),
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
