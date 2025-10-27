import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

class MoodUpdatesScreen extends StatefulWidget {
  final String username;

  const MoodUpdatesScreen({super.key, required this.username});

  @override
  State<MoodUpdatesScreen> createState() => _MoodUpdatesScreenState();
}

class _MoodUpdatesScreenState extends State<MoodUpdatesScreen> {
  List<String> _moodHistory = [];
  Map<String, int> _moodCount = {};
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
      _updateMoodStats();
    });
  }

  Future<void> _deleteMoodEntry(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _moodHistory.removeAt(index);
      _updateMoodStats();
    });
    await prefs.setStringList(_moodKey, _moodHistory);
  }

  void _updateMoodStats() {
    _moodCount.clear();
    for (var entry in _moodHistory) {
      final parts = entry.split('→');
      final mood = parts.length > 1 ? parts[1].trim() : "Unknown";
      _moodCount[mood] = (_moodCount[mood] ?? 0) + 1;
    }
  }

  List<PieChartSectionData> _buildChartSections() {
    final total = _moodHistory.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _moodCount.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      final color = _getMoodColor(entry.key);
      return PieChartSectionData(
        color: color,
        value: percentage,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();
  }

  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case "happy":
        return Colors.yellow.shade700;
      case "sad":
        return Colors.blue.shade400;
      case "angry":
        return Colors.red.shade400;
      case "relaxed":
        return Colors.green.shade400;
      case "stressed":
        return Colors.orange.shade400;
      default:
        return Colors.purple.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text("${widget.username}'s Mood Tracker"),
        backgroundColor:
        isDark ? Colors.deepPurple.shade700 : Colors.deepPurple,
        centerTitle: true,
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
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mood Chart
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                color: isDark
                    ? Colors.deepPurple.shade800
                    : Colors.deepPurple.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        "Mood Overview",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 180,
                        child: PieChart(
                          PieChartData(
                            sections: _buildChartSections(),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Total entries: ${_moodHistory.length}",
                        style: TextStyle(
                            color: isDark
                                ? Colors.white70
                                : Colors.grey.shade800),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Mood Percentages
              if (_moodCount.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _moodCount.entries.map((entry) {
                    final percentage =
                        (entry.value / _moodHistory.length) * 100;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: _getMoodColor(entry.key),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              Text(
                                entry.key,
                                style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87),
                              ),
                            ],
                          ),
                          Text(
                            "${percentage.toStringAsFixed(1)}%",
                            style: TextStyle(
                                color: isDark
                                    ? Colors.purple[200]
                                    : Colors.deepPurple),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 20),

              // Mood History List
              const Text(
                "Mood History",
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _moodHistory.length,
                itemBuilder: (context, index) {
                  final entry = _moodHistory[index];
                  final parts = entry.split('→');
                  final date = parts[0].trim();
                  final mood =
                  parts.length > 1 ? parts[1].trim() : "Unknown";

                  return Card(
                    color: isDark
                        ? Colors.deepPurple.shade800
                        : Colors.deepPurple.shade50,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getMoodColor(mood),
                        child: const Icon(Icons.mood, color: Colors.white),
                      ),
                      title: Text(
                        mood,
                        style: TextStyle(
                          color: isDark
                              ? Colors.white
                              : Colors.deepPurple.shade800,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "🗓 Date: $date",
                        style: TextStyle(
                          color:
                          isDark ? Colors.purple[200] : Colors.black87,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete,
                            color: Colors.redAccent),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Delete Mood Entry"),
                              content: const Text(
                                  "Are you sure you want to delete this mood entry?"),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context),
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
            ],
          ),
        ),
      ),
    );
  }
}
