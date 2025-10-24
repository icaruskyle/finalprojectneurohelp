import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MoodUpdatesScreen extends StatefulWidget {
  final String username;

  const MoodUpdatesScreen({super.key, required this.username});

  @override
  State<MoodUpdatesScreen> createState() => _MoodUpdatesScreenState();
}

class _MoodUpdatesScreenState extends State<MoodUpdatesScreen> {
  List<String> _moodHistory = [];

  String get _moodKey => "moodHistory_${widget.username}";

  @override
  void initState() {
    super.initState();
    _loadMoodHistory();
  }

  Future<void> _loadMoodHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_moodKey) ?? [];
    setState(() {
      _moodHistory = history;
    });
  }

  Future<void> _deleteMoodEntry(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _moodHistory.removeAt(index);
    });
    await prefs.setStringList(_moodKey, _moodHistory);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text("${widget.username}'s Mood History"),
        backgroundColor:
        isDark ? Colors.deepPurple.shade700 : Colors.deepPurple,
      ),
      body: _moodHistory.isEmpty
          ? Center(
        child: Text(
          "No mood updates yet",
          style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 16),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _moodHistory.length,
        itemBuilder: (context, index) {
          final entry = _moodHistory[index];
          final parts = entry.split('→');
          final date = parts[0].trim();
          final mood = parts.length > 1 ? parts[1].trim() : "Unknown";

          return Card(
            color: isDark
                ? Colors.deepPurple.shade800
                : Colors.deepPurple.shade50,
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: Text(
                mood,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.deepPurple,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                "🗓 Date: $date",
                style: TextStyle(
                  color: isDark ? Colors.purple[200] : Colors.black87,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Delete Mood Entry"),
                      content: const Text(
                          "Are you sure you want to delete this mood entry?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () {
                            _deleteMoodEntry(index);
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "Delete",
                            style: TextStyle(color: Colors.red),
                          ),
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
    );
  }
}
