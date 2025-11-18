// mood_updates_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Global notifier for MusicScreen to detect current mood
ValueNotifier<String> moodNotifier = ValueNotifier<String>("cheerful");

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
  Map<String, Map<String, String>> _hourlyMoods = {}; // store hourly moods

  // Weekly & monthly tracking
  Map<String, double> _weeklyMoodAverage = {};
  Map<String, double> _monthlyMoodAverage = {};

  // Real-time mood message & counters
  String _moodMessage = "";
  int _happyCount = 0;
  int _sadCount = 0;
  int _neutralCountReal = 0;

  final User? user = FirebaseAuth.instance.currentUser;

  final List<String> positiveMoods = [
    "😊 Happy", "😇 Grateful", "😌 Content", "😎 Confident", "🥳 Excited",
    "😚 Loved", "🤗 Hopeful", "🤩 Inspired", "😋 Playful", "🤠 Cheerful",
    "🧘 Calm", "🙂 Neutral",
  ];

  final List<String> negativeMoods = [
    "😢 Sad",
    "💔 Heartbroken",
    "😞 Disappointed",
    "😔 Lonely",
    "😩 Overwhelmed",
    "😕 Confused",
    "😟 Anxious",
    "😰 Stressed",
    "😤 Frustrated",
    "😠 Irritated",
    "😡 Angry",
    "😬 Nervous",
    "😳 Embarrassed",
    "😴 Tired",
    "😫 Exhausted",
    "😩 Hopeless",
    "😶 Empty",
    "😑 Bored",
    "🤒 Unwell",
    "🤯 Burned Out",
    "⚠️ Suicidal/Warning",
  ];

  final List<String> neutralMoods = [
    "🤔 Reflective",
    "😌 Thoughtful",
    "😮 Surprised",
    "😶 Indifferent",
    "😐 Blank",
    "🫤 Uncertain",
    "🤫 Quiet",
    "😅 Awkward",
    "🤨 Skeptical",
    "🤓 Focused",
    "🤭 Amused",
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
    _hourlyMoods.clear();
    _weeklyMoodAverage.clear();
    _monthlyMoodAverage.clear();
    _happyCount = 0;
    _sadCount = 0;
    _neutralCountReal = 0;

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final mood = data['mood'] ?? 'Unknown';
      final timestamp = data['date'] != null
          ? DateTime.parse(data['date']).toLocal()
          : DateTime.now();
      final date = DateFormat('yyyy-MM-dd').format(timestamp);
      final hour = DateFormat('HH:00').format(timestamp);
      final week = DateFormat('yyyy-ww').format(timestamp);
      final month = DateFormat('yyyy-MM').format(timestamp);

      _moodCount[mood] = (_moodCount[mood] ?? 0) + 1;

      if (positiveMoods.contains(mood)) {
        _positiveCount[mood] = (_positiveCount[mood] ?? 0) + 1;
        _happyCount++;
      } else if (negativeMoods.contains(mood)) {
        _negativeCount[mood] = (_negativeCount[mood] ?? 0) + 1;
        _sadCount++;
      } else {
        _neutralCount[mood] = (_neutralCount[mood] ?? 0) + 1;
        _neutralCountReal++;
      }

      // Daily
      if (!_dailyMoods.containsKey(date)) _dailyMoods[date] = [];
      _dailyMoods[date]!.add(mood);

      // Hourly
      if (!_hourlyMoods.containsKey(date)) _hourlyMoods[date] = {};
      _hourlyMoods[date]![hour] = mood;

      // Weekly
      _weeklyMoodAverage[week] = (_weeklyMoodAverage[week] ?? 0) + _getMoodValue(mood);

      // Monthly
      _monthlyMoodAverage[month] = (_monthlyMoodAverage[month] ?? 0) + _getMoodValue(mood);
    }

    // Normalize weekly & monthly averages
    _weeklyMoodAverage.updateAll((key, value) {
      int count = docs.where((doc) {
        final ts = doc['date'] != null
            ? DateTime.parse(doc['date']).toLocal()
            : DateTime.now();
        return DateFormat('yyyy-ww').format(ts) == key;
      }).length;
      return count > 0 ? value / count : 0;
    });

    _monthlyMoodAverage.updateAll((key, value) {
      int count = docs.where((doc) {
        final ts = doc['date'] != null
            ? DateTime.parse(doc['date']).toLocal()
            : DateTime.now();
        return DateFormat('yyyy-MM').format(ts) == key;
      }).length;
      return count > 0 ? value / count : 0;
    });

    // Daily averages
    _dailyMoods.forEach((date, moods) {
      double avg = moods.map((m) => _getMoodValue(m)).reduce((a, b) => a + b) /
          moods.length;
      _dailyMoodAverage[date] = avg;
    });

    _updateMoodNotifier();
  }

  void _updateMoodNotifier() {
    if (_dailyMoods.isNotEmpty) {
      final sortedDates = _dailyMoods.keys.toList()..sort();
      final lastDate = sortedDates.last;
      final lastMoods = _dailyMoods[lastDate]!;

      String latestMood = lastMoods.isNotEmpty ? lastMoods.last : "cheerful";
      final lowerMood = latestMood.toLowerCase();

      if (lowerMood.contains("sad") ||
          lowerMood.contains("heartbroken") ||
          lowerMood.contains("lonely") ||
          lowerMood.contains("disappointed") ||
          lowerMood.contains("stressed") ||
          lowerMood.contains("angry") ||
          lowerMood.contains("frustrated")) {
        moodNotifier.value = "sad";
        _moodMessage = "You're feeling down today. Take care of yourself!";
      } else {
        moodNotifier.value = "cheerful";
        _moodMessage = "You're feeling great! Keep it up!";
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text("No user logged in",
              style: TextStyle(color: isDark ? Colors.white : Colors.black)),
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
                  // Real-time mood message and counters
                  Card(
                    color: isDark ? Colors.deepPurple.shade700 : Colors.deepPurple.shade100,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(_moodMessage,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.deepPurple.shade800),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _moodCounterItem("Happy", _happyCount, Colors.yellow.shade700),
                              _moodCounterItem("Neutral", _neutralCountReal, Colors.blue.shade400),
                              _moodCounterItem("Sad", _sadCount, Colors.red.shade400),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCategoryChartCard("Overall Mood Overview", _moodCount, isDark),
                  if (_positiveCount.isNotEmpty)
                    _buildCategoryChartCard("Positive Moods", _positiveCount, isDark),
                  if (_negativeCount.isNotEmpty)
                    _buildCategoryChartCard("Negative Moods", _negativeCount, isDark),
                  if (_neutralCount.isNotEmpty)
                    _buildCategoryChartCard("Neutral / Reflective Moods", _neutralCount, isDark),
                  const SizedBox(height: 16),
                  if (_dailyMoods.isNotEmpty) _buildDailyMoodChart(isDark),
                  _buildHourlyMoods(),
                  const SizedBox(height: 16),
                  if (_weeklyMoodAverage.isNotEmpty)
                    _buildAggregateMoodChart("Weekly Mood Trend", _weeklyMoodAverage, isDark),
                  const SizedBox(height: 16),
                  if (_monthlyMoodAverage.isNotEmpty)
                    _buildAggregateMoodChart("Monthly Mood Trend", _monthlyMoodAverage, isDark),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _moodCounterItem(String label, int count, Color color) {
    return Column(
      children: [
        Text("$count",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 14, color: color)),
      ],
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
          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildChartSections(Map<String, int> dataMap) {
    final total = dataMap.values.fold(0, (a, b) => a + b);
    return dataMap.entries.map((entry) {
      final percentage = total == 0 ? 0.0 : (entry.value / total) * 100;
      final color = _getMoodColor(entry.key);
      return PieChartSectionData(
        color: color,
        value: percentage,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
      );
    }).toList();
  }

  Widget _buildDailyMoodChart(bool isDark) {
    if (_hourlyMoods.isEmpty) return const SizedBox.shrink();
    final dates = _hourlyMoods.keys.toList()..sort();
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? Colors.deepPurple.shade800 : Colors.deepPurple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Hourly Mood Trend",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: LineChart(LineChartData(
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
                        int index = value.toInt();
                        String date = "";
                        String hour = "";
                        int count = 0;
                        for (var d in dates) {
                          final hours = _hourlyMoods[d]!.keys.toList()..sort();
                          if (index < count + hours.length) {
                            date = d.substring(5); // MM-dd
                            hour = hours[index - count];
                            break;
                          }
                          count += hours.length;
                        }
                        if (date.isNotEmpty && hour.isNotEmpty) {
                          return Text("$date\n$hour", style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 9), textAlign: TextAlign.center);
                        }
                        return const Text('');
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
                        int index = spot.x.toInt();
                        int count = 0;
                        String date = "";
                        String hour = "";
                        for (var d in dates) {
                          final hours = _hourlyMoods[d]!.keys.toList()..sort();
                          if (index < count + hours.length) {
                            date = d;
                            hour = hours[index - count];
                            break;
                          }
                          count += hours.length;
                        }
                        final mood = _hourlyMoods[date]![hour]!;
                        return LineTooltipItem("$date\n$hour\nMood: $mood", const TextStyle(color: Colors.greenAccent));
                      }).toList();
                    },
                  ),
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }

  List<LineChartBarData> _buildDailyMoodLines() {
    List<LineChartBarData> lines = [];
    _hourlyMoods.forEach((date, hourlyMap) {
      final sortedHours = hourlyMap.keys.toList()..sort();
      List<FlSpot> spots = [];
      for (var i = 0; i < sortedHours.length; i++) {
        final mood = hourlyMap[sortedHours[i]]!;
        spots.add(FlSpot(i.toDouble(), _getMoodValue(mood).toDouble()));
      }
      lines.add(LineChartBarData(
        spots: spots,
        isCurved: true,
        barWidth: 3,
        color: Colors.orangeAccent,
        dotData: FlDotData(show: true),
        belowBarData: BarAreaData(show: false),
      ));
    });
    return lines;
  }

  Widget _buildAggregateMoodChart(String title, Map<String, double> data, bool isDark) {
    if (data.isEmpty) return const SizedBox.shrink();

    final sortedKeys = data.keys.toList()..sort();
    List<FlSpot> spots = [];
    for (var i = 0; i < sortedKeys.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[sortedKeys[i]]!.toDouble()));
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? Colors.deepPurple.shade800 : Colors.deepPurple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 3,
                      color: Colors.orangeAccent,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
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
                          int index = value.toInt();
                          if (index >= 0 && index < sortedKeys.length) {
                            return Text(sortedKeys[index],
                                style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 10),
                                textAlign: TextAlign.center);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyMoods() {
    return const SizedBox.shrink(); // placeholder; keep your original implementation if any
  }
}
