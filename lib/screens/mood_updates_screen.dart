import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MoodUpdatesScreen extends StatefulWidget {
  const MoodUpdatesScreen({super.key});

  @override
  State<MoodUpdatesScreen> createState() => _MoodUpdatesScreenState();
}

class _MoodUpdatesScreenState extends State<MoodUpdatesScreen> {
  List<String> _moodHistory = [];

  @override
  void initState() {
    super.initState();
    _loadMoods();
  }

  Future<void> _loadMoods() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _moodHistory = prefs.getStringList("moodHistory") ?? [];
    });
  }

  Future<void> _saveMood(String mood) async {
    final prefs = await SharedPreferences.getInstance();
    final date = DateTime.now().toString().split(" ")[0]; // yyyy-mm-dd
    final entry = "$date → $mood";

    setState(() {
      _moodHistory.insert(0, entry);
    });

    await prefs.setStringList("moodHistory", _moodHistory);
  }

  @override
  Widget build(BuildContext context) {
    final moods = {
      "😊": "Happy",
      "😐": "Neutral",
      "😢": "Sad",
      "😡": "Angry",
      "😴": "Tired",
      "🤔": "Thoughtful"
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mood Tracker"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "How are you feeling today?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 15,
              children: moods.entries.map((entry) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _saveMood("${entry.key} ${entry.value}"),
                  child: Text(
                    entry.key,
                    style: const TextStyle(fontSize: 28),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            const Text(
              "Mood History",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Expanded(
              child: _moodHistory.isEmpty
                  ? const Center(
                      child: Text("No moods tracked yet."),
                    )
                  : ListView.builder(
                      itemCount: _moodHistory.length,
                      itemBuilder: (context, index) {
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.mood, color: Colors.deepPurple),
                            title: Text(_moodHistory[index]),
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }
}
