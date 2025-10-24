// daily_journal_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import 'mood_updates_screen.dart';
import 'emergency_contacts_screen.dart';

class DailyJournalScreen extends StatefulWidget {
  final String username;

  const DailyJournalScreen({super.key, required this.username});

  @override
  State<DailyJournalScreen> createState() => _DailyJournalScreenState();
}

class _DailyJournalScreenState extends State<DailyJournalScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> _entries = [];

  String get _journalKey => "dailyJournal_${widget.username}";
  String get _moodKey => "moodHistory_${widget.username}";

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getStringList(_journalKey) ?? [];
    setState(() {
      _entries = savedData.map((e) {
        final parts = e.split('|');
        return {
          "text": parts.isNotEmpty ? parts[0] : "",
          "mood": parts.length > 1 ? parts[1] : "Unknown",
          "date": parts.length > 2
              ? parts[2]
              : DateTime.now().toString().split(" ")[0],
        };
      }).toList();
    });
  }

  Future<void> _saveEntry() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final suicidalDetected = _detectSuicidalRisk(text);
    final prefs = await SharedPreferences.getInstance();
    final mood = _predictMood(text);
    final date = DateTime.now().toString().split(" ")[0];

    setState(() {
      _entries.insert(0, {
        "text": text,
        "mood": mood,
        "date": date,
      });
      _controller.clear();
    });

    await prefs.setStringList(
      _journalKey,
      _entries.map((e) => "${e["text"]}|${e["mood"]}|${e["date"]}").toList(),
    );

    final moodHistory = prefs.getStringList(_moodKey) ?? [];
    moodHistory.insert(0, "$date → $mood");
    await prefs.setStringList(_moodKey, moodHistory);

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
      }
    }
  }

  Future<void> _deleteEntry(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _entries.removeAt(index));
    await prefs.setStringList(
      _journalKey,
      _entries.map((e) => "${e["text"]}|${e["mood"]}|${e["date"]}").toList(),
    );
  }

  Future<void> _showSuicidalAlertDialog() async {
    const defaultHelplineNumber = "+15551234567";
    const fallbackHelplineUrl = "https://findahelpline.com";

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Immediate Help Recommended"),
          content: const Text(
            "Your entry contains language that suggests you may be at risk of self-harm or suicide.\n\n"
                "If you're in immediate danger, please call local emergency services or a crisis helpline right now. "
                "Would you like to call a helpline, view emergency contacts, or cancel?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _openEmergencyContacts();
              },
              child: const Text("View Contacts"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _callNumber(defaultHelplineNumber);
              },
              child: const Text("Call Helpline",
                  style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _openUrl(fallbackHelplineUrl);
              },
              child: const Text("Open Help Site"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _callNumber(String number) async {
    final uri = Uri.parse('tel:$number');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _openUrl("https://findahelpline.com");
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open phone dialer.")),
        );
      }
    }
  }

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not open the link.")),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open the link.")),
        );
      }
    }
  }

  void _openEmergencyContacts() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EmergencyContactsScreen()),
    );
  }

  bool _detectSuicidalRisk(String text) {
    final lower = text.toLowerCase();
    final critical = [
      "i want to die",
      "i want to kill myself",
      "i'm going to kill myself",
      "im going to kill myself",
      "i want to end my life",
      "kill myself",
      "end my life",
      "suicide",
      "i'm suicidal",
      "i am suicidal",
      "i can't go on",
      "i cant go on",
      "i don't want to live",
      "i dont want to live",
      "going to jump",
      "going to overdose",
      "thoughts of suicide",
      "thoughts of killing myself",
      "goodbye forever",
      "no reason to live",
      "die"
    ];

    for (final p in critical) {
      if (lower.contains(p)) return true;
    }

    final pattern = RegExp(
      r'\b(kill|suicide|die|end my life|end it all|overdose|jump)\b',
      caseSensitive: false,
    );
    if (pattern.hasMatch(lower)) {
      final contextPattern = RegExp(
        r'\b(myself|life|all|now|today|tonight)\b',
        caseSensitive: false,
      );
      if (contextPattern.hasMatch(lower)) return true;
      return true;
    }

    return false;
  }

  // 🟣 UPDATED SECTION: use _detectSuicidalRisk to ensure "die" and similar always return warning
  String _predictMood(String text) {
    final lower = text.toLowerCase();

    // If detection logic says suicidal risk, return warning
    if (_detectSuicidalRisk(lower)) {
      return "⚠️ Warning: Suicidal Content Detected";
    }

    if (lower.contains("happy") ||
        lower.contains("excited") ||
        lower.contains("grateful") ||
        lower.contains("joy") ||
        lower.contains("amazing")) {
      return "😊 Happy";
    } else if (lower.contains("sad") ||
        lower.contains("depressed") ||
        lower.contains("cry") ||
        lower.contains("lonely")) {
      return "😢 Sad";
    } else if (lower.contains("angry") ||
        lower.contains("mad") ||
        lower.contains("frustrated")) {
      return "😡 Angry";
    } else if (lower.contains("tired") ||
        lower.contains("exhausted") ||
        lower.contains("sleepy")) {
      return "😴 Tired";
    } else if (lower.contains("calm") ||
        lower.contains("relaxed") ||
        lower.contains("peaceful")) {
      return "🧘 Calm";
    } else if (lower.contains("anxious") ||
        lower.contains("nervous") ||
        lower.contains("worried")) {
      return "😟 Anxious";
    } else {
      final randomMoods = ["🙂 Neutral", "🤔 Reflective", "😌 Content"];
      return randomMoods[Random().nextInt(randomMoods.length)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text("${widget.username}'s Daily Journal"),
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
                  builder: (_) => MoodUpdatesScreen(username: widget.username),
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
                labelStyle: TextStyle(
                    color: isDark ? Colors.purple[200] : Colors.deepPurple),
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Save Entry"),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _entries.isEmpty
                  ? Center(
                child: Text(
                  "No journal entries yet",
                  style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54),
                ),
              )
                  : ListView.builder(
                itemCount: _entries.length,
                itemBuilder: (context, index) {
                  final entry = _entries[index];
                  return Card(
                    color: isDark
                        ? Colors.deepPurple.shade800
                        : Colors.deepPurple.shade50,
                    margin:
                    const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(
                        entry["text"] ?? "",
                        style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : Colors.black87),
                      ),
                      subtitle: Text(
                        "🗓 ${entry["date"]}  •  Mood: ${entry["mood"]}",
                        style: TextStyle(
                          color: (entry["mood"]?.contains("⚠️") ?? false)
                              ? Colors.redAccent
                              : isDark
                              ? Colors.purpleAccent.shade100
                              : Colors.deepPurple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete,
                            color: Colors.redAccent),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Delete Entry"),
                              content: const Text(
                                  "Are you sure you want to delete this entry?"),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context),
                                    child: const Text("Cancel")),
                                TextButton(
                                  onPressed: () {
                                    _deleteEntry(index);
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
