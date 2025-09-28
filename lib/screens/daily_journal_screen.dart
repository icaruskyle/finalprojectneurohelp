import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyJournalScreen extends StatefulWidget {
  const DailyJournalScreen({super.key});

  @override
  State<DailyJournalScreen> createState() => _DailyJournalScreenState();
}

class _DailyJournalScreenState extends State<DailyJournalScreen> {
  final TextEditingController _controller = TextEditingController();
  List<String> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _entries = prefs.getStringList("dailyJournal") ?? [];
    });
  }

  Future<void> _saveEntry() async {
    if (_controller.text.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _entries.add(_controller.text);
      _controller.clear();
    });

    await prefs.setStringList("dailyJournal", _entries);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Journal"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Write your reflection...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _saveEntry,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              ),
              child: const Text("Save Entry"),

            ),
            const SizedBox(height: 20),
            Expanded(
              child: _entries.isEmpty
                  ? const Center(
                      child: Text("No journal entries yet"),
                    )
                  : ListView.builder(
                      itemCount: _entries.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            title: Text(_entries[index]),
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
