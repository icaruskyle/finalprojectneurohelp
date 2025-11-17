// mood_updates_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MoodUpdatesScreen extends StatefulWidget {
  final String uid; // use uid consistently

  const MoodUpdatesScreen({super.key, required this.uid});

  @override
  State<MoodUpdatesScreen> createState() => _MoodUpdatesScreenState();
}

class _MoodUpdatesScreenState extends State<MoodUpdatesScreen> {
  Map<String, int> _moodCount = {};
  Map<String, int> _positiveCount = {};
  Map<String, int> _negativeCount = {};
  Map<String, int> _neutralCount = {};
  Map<String, List<String>> _dailyMoods = {};
  Map<String, double> _dailyMoodAverage = {};

  final User? user = FirebaseAuth.instance.currentUser;

  final List<String> positiveMoods = [
    "😊 Happy", "😇 Grateful", "😌 Content", "😎 Confident", "🥳 Excited",
    "😚 Loved", "🤗 Hopeful", "🤩 Inspired", "😋 Playful", "🤠 Cheerful",
    "🧘 Calm", "🙂 Neutral",
  ];

  final List<String> negativeMoods = [
    "😢 Sad", "💔 Heartbroken", "😞 Disappointed", "😔 Lonely", "😩 Overwhelmed",
    "😕 Confused", "😟 Anxious", "😰 Stressed", "😤 Frustrated", "😠 Irritated",
    "😡 Angry", "😬 Nervous", "😳 Embarrassed", "😴 Tired", "😫 Exhausted",
    "😩 Hopeless", "😶 Empty", "😑 Bored", "🤒 Unwell", "🤯 Burned Out", "⚠️ Suicidal/Warning",
  ];

  final List<String> neutralMoods = [
    "🤔 Reflective", "😌 Thoughtful", "😮 Surprised", "😶 Indifferent", "😐 Blank",
    "🫤 Uncertain", "🤫 Quiet", "😅 Awkward", "🤨 Skeptical", "🤓 Focused", "🤭 Amused",
  ];

  Color _getMoodColor(String mood) {
    if (positiveMoods.contains(mood)) return Colors.yellow.shade700;
    if (negativeMoods.contains(mood)) return Colors.red.shade400;
    if (neutralMoods.contains(mood)) return Colors.blue.shade400;
    return Colors.purple.shade300;
  }

  int _getMoodValue(String mood) {
    if (positiveMoods.contains(mood)) return 1;
    if (negativeMoods.contains(mood)) return -1;
    return 0;
  }

  void _updateMoodStats(List<QueryDocumentSnapshot> docs) {
    _moodCount.clear();
    _positiveCount.clear();
    _negativeCount.clear();
    _neutralCount.clear();
    _dailyMoods.clear();
    _dailyMoodAverage.clear();

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final mood = data['mood'] ?? 'Unknown';
      final date = data['date'] != null
          ? DateFormat('yyyy-MM-dd').format(DateTime.parse(data['date']).toLocal())
          : 'Unknown';

      _moodCount[mood] = (_moodCount[mood] ?? 0) + 1;

      if (positiveMoods.contains(mood)) {
        _positiveCount[mood] = (_positiveCount[mood] ?? 0) + 1;
      } else if (negativeMoods.contains(mood)) {
        _negativeCount[mood] = (_negativeCount[mood] ?? 0) + 1;
      } else if (neutralMoods.contains(mood)) {
        _neutralCount[mood] = (_neutralCount[mood] ?? 0) + 1;
      }

      if (!_dailyMoods.containsKey(date)) _dailyMoods[date] = [];
      _dailyMoods[date]!.add(mood);
    }

    _dailyMoods.forEach((date, moods) {
      double avg = moods.map((m) => _getMoodValue(m)).reduce((a, b) => a + b) / moods.length;
      _dailyMoodAverage[date] = avg;
    });
  }

  List<PieChartSectionData> _buildChartSections(Map<String, int> dataMap) {
    final total = dataMap.values.fold(0, (a, b) => a + b);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return dataMap.entries.map((entry) {
      final percentage = total == 0 ? 0.0 : (entry.value / total) * 100;
      final color = _getMoodColor(entry.key);
      return PieChartSectionData(
        color: color,
        value: percentage,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();
  }

  List<LineChartBarData> _buildDailyMoodLines() {
    final sortedDates = _dailyMoods.keys.toList()..sort();
    List<FlSpot> trendSpots = [];

    for (var i = 0; i < sortedDates.length; i++) {
      trendSpots.add(FlSpot(i.toDouble(), _dailyMoodAverage[sortedDates[i]]!));
    }

    return [
      LineChartBarData(
        spots: trendSpots,
        isCurved: true,
        barWidth: 3,
        color: Colors.greenAccent,
        dotData: FlDotData(show: true), // only show dots on trend line
        belowBarData: BarAreaData(show: false),
      )
    ];
  }

  Future<void> _deleteMoodEntry(String moodId, String? journalId) async {
    if (user == null) return;
    final uid = user!.uid;

    final moodRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('mood_history');

    final journalRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('daily_journal');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Mood Entry"),
        content: const Text(
            "Are you sure you want to delete this mood entry? It will also delete the linked journal entry."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              try {
                await moodRef.doc(moodId).delete();
                if (journalId != null && journalId.isNotEmpty) {
                  await journalRef.doc(journalId).delete();
                }
                Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Mood entry and linked journal deleted.")),
                  );
                }
              } catch (e) {
                Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error deleting: $e")),
                  );
                }
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text("No user logged in", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        ),
      );
    }

    final uid = user!.uid;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: const Text("Mood Tracker"),
        backgroundColor: isDark ? Colors.deepPurple.shade700 : Colors.deepPurple,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('mood_history')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          _updateMoodStats(docs);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCategoryChartCard("Overall Mood Overview", _moodCount, isDark),
                  const SizedBox(height: 16),
                  if (_positiveCount.isNotEmpty)
                    _buildCategoryChartCard("Positive Moods", _positiveCount, isDark),
                  const SizedBox(height: 16),
                  if (_negativeCount.isNotEmpty)
                    _buildCategoryChartCard("Negative Moods", _negativeCount, isDark),
                  const SizedBox(height: 16),
                  if (_neutralCount.isNotEmpty)
                    _buildCategoryChartCard("Neutral / Reflective Moods", _neutralCount, isDark),
                  const SizedBox(height: 16),
                  if (_dailyMoods.isNotEmpty)
                    _buildDailyMoodChart(isDark),
                  const SizedBox(height: 20),
                  const Text("Mood History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final docId = docs[index].id;
                      final mood = data['mood'] ?? 'Unknown';
                      final date = data['date'] != null
                          ? DateTime.parse(data['date']).toLocal().toString().split(' ')[0]
                          : '';
                      final journalId = data['journalId'] ?? null;

                      return Card(
                        color: isDark ? Colors.deepPurple.shade800 : Colors.deepPurple.shade50,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getMoodColor(mood),
                            child: const Icon(Icons.mood, color: Colors.white),
                          ),
                          title: Text(mood,
                              style: TextStyle(
                                  color: isDark ? Colors.white : Colors.deepPurple.shade800,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text("🗓 Date: $date",
                              style: TextStyle(color: isDark ? Colors.purple[200] : Colors.black87)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => _deleteMoodEntry(docId, journalId),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryChartCard(String title, Map<String, int> data, bool isDark) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? Colors.deepPurple.shade800 : Colors.deepPurple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: PieChart(
                PieChartData(
                  sections: _buildChartSections(data),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 30,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildMoodLegend(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodLegend(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _legendItem("Positive", Colors.yellow.shade700, isDark),
        _legendItem("Neutral", Colors.blue.shade400, isDark),
        _legendItem("Negative", Colors.red.shade400, isDark),
      ],
    );
  }

  Widget _legendItem(String label, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDailyMoodChart(bool isDark) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? Colors.deepPurple.shade800 : Colors.deepPurple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Daily Mood Progress",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: LineChart(
                LineChartData(
                  lineBarsData: _buildDailyMoodLines(),
                  minY: -1.5,
                  maxY: 1.5,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final color = isDark ? Colors.white70 : Colors.black87;
                          if (value == -1) return Text("Neg", style: TextStyle(color: color));
                          if (value == 0) return Text("Neu", style: TextStyle(color: color));
                          if (value == 1) return Text("Pos", style: TextStyle(color: color));
                          return Text('', style: TextStyle(color: color));
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final color = isDark ? Colors.white70 : Colors.black87;
                          final index = value.toInt();
                          if (index >= 0 && index < _dailyMoods.keys.length) {
                            return Text(
                              _dailyMoods.keys.toList()[index].substring(5),
                              style: TextStyle(color: color, fontSize: 10),
                            );
                          }
                          return Text('', style: TextStyle(color: color));
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBorderRadius: BorderRadius.circular(8),
                      getTooltipColor: (touchedSpots) => isDark ? Colors.grey.shade900 : Colors.black87,
                      getTooltipItems: (spots) {
                        return spots.map((spot) {
                          final date = _dailyMoods.keys.toList()[spot.x.toInt()];
                          return LineTooltipItem(
                            "Avg Mood\n$date",
                            TextStyle(color: Colors.greenAccent),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
