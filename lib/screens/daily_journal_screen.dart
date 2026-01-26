import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'ai_service.dart';
import 'mood_updates_screen.dart';
import 'emergency_contacts_screen.dart';
import 'music_screen.dart';

class DailyJournalScreen extends StatefulWidget {
  const DailyJournalScreen({super.key});

  @override
  State<DailyJournalScreen> createState() => _DailyJournalScreenState();
}

class _DailyJournalScreenState extends State<DailyJournalScreen> {
  final TextEditingController _controller = TextEditingController();
  final AIService ai = AIService();
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // SAVE ENTRY
  Future<void> _saveEntry() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (user == null) return;

    _controller.clear();

    try {
      final uid = user!.uid;

      final journalRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('daily_journal');

      final moodHistoryRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('mood_history');

      // Detect suicidal risk
      final suicidalDetected = _detectSuicidalRisk(text);

      // Fetch birthdate
      final userDoc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();

      DateTime? birthDate;
      if (userDoc.exists &&
          userDoc.data() != null &&
          userDoc.data()!['birthDate'] != null) {
        birthDate = (userDoc.data()!['birthDate'] as Timestamp).toDate();
      }

      // AI mood prediction
      String mood = await ai.predictMood(text);

      // Age-based adjustment
      if (birthDate != null) {
        final adjusted = _adjustMoodBasedOnAge(text, birthDate);
        if (adjusted.isNotEmpty) mood = adjusted;
      }

      final date = DateTime.now().toIso8601String();

      // Save journal
      final journalDocRef = await journalRef.add({
        'text': text,
        'mood': mood,
        'date': date,
      });

      // Save mood history
      await moodHistoryRef.add({
        'mood': mood,
        'date': date,
        'journalId': journalDocRef.id,
      });

      // Save
      if (suicidalDetected) {
        await _showSuicidalAlertDialog();
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Journal saved — detected mood: $mood"),
              backgroundColor: Colors.deepPurple,
              behavior: SnackBarBehavior.floating,
            ),
          );
          await _showCalmingMusicPrompt();
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error saving entry.")),
        );
      }
    }
  }

  // Music Pop Up
  Future<void> _showCalmingMusicPrompt() async {
    if (!mounted || user == null) return;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Need some calm? 🎧"),
          content: const Text(
            "Would you like to listen to calming music to help you relax?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("No"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MusicScreen(
                      uid: user!.uid,
                      isDarkMode:
                      Theme.of(context).brightness == Brightness.dark,
                    ),
                  ),
                );
              },
              child: const Text("Yes, play music"),
            ),
          ],
        );
      },
    );
  }

  // Age Base
  String _adjustMoodBasedOnAge(String text, DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (birthDate.month > now.month ||
        (birthDate.month == now.month && birthDate.day > now.day)) {
      age--;
    }

    final sensitiveKeywords = [
      "i got pregnant",
      "i am pregnant",
      "unexpected pregnancy",
      "nabuntis ako",
      "nagbuntis ako",
      "nagkaroon ng anak",
    ];

    final lowerText = text.toLowerCase();

    for (final keyword in sensitiveKeywords) {
      if (lowerText.contains(keyword)) {
        if (age <= 21) return "😞 Disappointed";
        if (age <= 25) return "🙂 Neutral";
        return "😇 Grateful";
      }
    }
    return "";
  }

  // Delete Entry
  Future<void> _deleteEntry(String journalId) async {
    if (user == null) return;

    try {
      final uid = user!.uid;

      final journalRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('daily_journal');

      final moodHistoryRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('mood_history');

      await journalRef.doc(journalId).delete();

      final moodSnapshot = await moodHistoryRef
          .where('journalId', isEqualTo: journalId)
          .get();

      for (var doc in moodSnapshot.docs) {
        await doc.reference.delete();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Journal entry and linked mood deleted.")),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error deleting entry.")),
        );
      }
    }
  }

  //Alert
  Future<void> _showSuicidalAlertDialog() async {
    const helpline = "+15551234567";
    const fallbackUrl = "https://findahelpline.com";

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Immediate Help Recommended"),
          content: const Text(
            "Your entry suggests you may be at risk of self-harm.\n\n"
                "Please contact emergency services or a crisis helpline.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _openEmergencyContacts();
              },
              child: const Text("View Contacts"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _callNumber(helpline);
              },
              child:
              const Text("Call Helpline", style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _openUrl(fallbackUrl);
              },
              child: const Text("Open Help Site"),
            ),
          ],
        );
      },
    );
  }

  // Helpers
  Future<void> _callNumber(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openEmergencyContacts() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EmergencyContactsScreen()),
    );
  }

  // ================= SUICIDAL DETECTION =================
  bool _detectSuicidalRisk(String text) {
    final lower = text.toLowerCase();
    final critical = [
      "i want to die",
      "kill myself",
      "suicide",
      "ayoko na",
      "pagod na ako",
      "magpakamatay",
      "wala nang pag asa",
    ];
    return critical.any((p) => lower.contains(p));
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text(
            "No user logged in",
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
        ),
      );
    }

    final uid = user!.uid;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: const Text("Daily Journal"),
        backgroundColor:
        isDark ? Colors.deepPurple.shade700 : Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.mood, color: Colors.white),
            tooltip: "View Mood History",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MoodUpdatesScreen(uid: uid),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: 4,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                labelText: "Write your reflection...",
                filled: true,
                fillColor: isDark
                    ? Colors.deepPurple.shade900
                    : Colors.deepPurple.shade50,
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _saveEntry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text("Save Entry"),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('daily_journal')
                    .orderBy('date', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return Center(
                      child: Text(
                        "No journal entries yet",
                        style: TextStyle(
                            color:
                            isDark ? Colors.white70 : Colors.black54),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data =
                      docs[index].data() as Map<String, dynamic>;
                      final docId = docs[index].id;
                      final text = data['text'] ?? '';
                      final mood = data['mood'] ?? 'Unknown';
                      final date = data['date'] != null
                          ? DateTime.parse(data['date'])
                          .toLocal()
                          .toString()
                          .split(' ')[0]
                          : '';

                      return Card(
                        color: isDark
                            ? Colors.deepPurple.shade800
                            : Colors.deepPurple.shade50,
                        margin:
                        const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text(
                            text,
                            style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : Colors.black87),
                          ),
                          subtitle: Text(
                            "🗓 $date  •  Mood: $mood",
                            style: TextStyle(
                                color: isDark
                                    ? Colors.purpleAccent.shade100
                                    : Colors.deepPurple),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.redAccent),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title:
                                  const Text("Delete Entry"),
                                  content: const Text(
                                      "Are you sure you want to delete this entry along with its mood history?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context),
                                      child:
                                      const Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        _deleteEntry(docId);
                                        Navigator.pop(context);
                                      },
                                      child: const Text("Delete",
                                          style: TextStyle(
                                              color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                            },
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
    );
  }
}