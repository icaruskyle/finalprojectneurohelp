import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

ValueNotifier<String> moodNotifier = ValueNotifier<String>("cheerful");

class MoodUpdatesScreen extends StatefulWidget {
  final String uid;

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
  Map<String, Map<String, String>> _hourlyMoods = {};
  Map<String, double> _weeklyMoodAverage = {};
  Map<String, double> _monthlyMoodAverage = {};

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
    "😢 Sad", "💔 Heartbroken", "😞 Disappointed", "😔 Lonely", "😩 Overwhelmed",
    "😕 Confused", "😟 Anxious", "😰 Stressed", "😤 Frustrated", "😠 Irritated",
    "😡 Angry", "😬 Nervous", "😳 Embarrassed", "😴 Tired", "😫 Exhausted",
    "😩 Hopeless", "😶 Empty", "😑 Bored", "🤒 Unwell", "🤯 Burned Out",
    "⚠️ Suicidal/Warning",
  ];

  final List<String> neutralMoods = [
    "🤔 Reflective", "😌 Thoughtful", "😮 Surprised", "😶 Indifferent", "😐 Blank",
    "🫤 Uncertain", "🤫 Quiet", "😅 Awkward", "🤨 Skeptical", "🤓 Focused", "🤭 Amused",
  ];

  final Map<String, String> moodMeanings = {
    // Positive meanings
    "😊 Happy": "You are experiencing joy and emotional satisfaction. This often reflects contentment with recent events or relationships.",
    "😇 Grateful": "You feel thankful and appreciative. Gratitude is linked to improved emotional well-being and resilience.",
    "😌 Content": "You feel at ease and emotionally balanced. Nothing feels overwhelming right now.",
    "😎 Confident": "You believe in your abilities and decisions. This mood supports motivation and self-growth.",
    "🥳 Excited": "You are energized and looking forward to something positive or new.",
    "😚 Loved": "You feel emotionally valued and cared for, which strengthens emotional security.",
    "🤗 Hopeful": "You believe things can improve. Hope is a strong emotional buffer against stress.",
    "🤩 Inspired": "You feel motivated by ideas, people, or goals that spark creativity or ambition.",
    "😋 Playful": "You are relaxed and open to fun, humor, and light-hearted interactions.",
    "🤠 Cheerful": "You feel upbeat and optimistic, often spreading positivity to others.",
    "🧘 Calm": "Your emotions are steady and peaceful. Stress levels are low.",
    "🙂 Neutral": "You feel emotionally steady without strong positive or negative feelings.",

    // Negative meanings
    "😢 Sad": "You may be feeling emotional pain or disappointment. This feeling is valid and deserves care.",
    "💔 Heartbroken": "You are experiencing deep emotional loss or grief, often connected to relationships.",
    "😞 Disappointed": "Your expectations were not met, leading to emotional letdown.",
    "😔 Lonely": "You may feel emotionally disconnected or in need of companionship.",
    "😩 Overwhelmed": "You may feel mentally or emotionally overloaded. Rest is important.",
    "😕 Confused": "You are uncertain and seeking clarity or understanding.",
    "😟 Anxious": "You may be worrying about future events or outcomes.",
    "😰 Stressed": "Your mind and body may be under pressure from responsibilities or challenges.",
    "😤 Frustrated": "You feel blocked or irritated due to unmet goals or obstacles.",
    "😠 Irritated": "Small things may be bothering you more than usual.",
    "😡 Angry": "You may feel a strong emotional reaction to perceived unfairness or hurt.",
    "😬 Nervous": "You may feel uneasy or tense about an upcoming situation.",
    "😳 Embarrassed": "You feel self-conscious about a situation or mistake.",
    "😴 Tired": "Your body or mind needs rest.",
    "😫 Exhausted": "You may be physically and emotionally drained.",
    "😩 Hopeless": "You may feel discouraged or unable to see positive outcomes.",
    "😶 Empty": "You may feel emotionally numb or disconnected.",
    "😑 Bored": "You may be under-stimulated or craving engagement.",
    "🤒 Unwell": "Your physical condition may be affecting your emotional state.",
    "🤯 Burned Out": "Long-term stress may have reduced your energy and motivation.",
    "⚠️ Suicidal/Warning": "This mood signals emotional distress. Immediate support and professional help are strongly recommended.",

    // Neutral meanings
    "🤔 Reflective": "You are thinking deeply about experiences, decisions, or emotions.",
    "😌 Thoughtful": "You are calmly processing ideas or emotions.",
    "😮 Surprised": "Something unexpected affected your emotional state.",
    "😶 Indifferent": "You feel emotionally detached or unaffected.",
    "😐 Blank": "You may feel mentally empty or emotionally paused.",
    "🫤 Uncertain": "You may be unsure about a situation or decision.",
    "🤫 Quiet": "You may be introspective or conserving emotional energy.",
    "😅 Awkward": "You may feel slightly uncomfortable but not distressed.",
    "🤨 Skeptical": "You are questioning or doubting something.",
    "🤓 Focused": "You are mentally engaged and attentive.",
    "🤭 Amused": "You feel quietly entertained or pleased.",
  };

  Color _getMoodColor(String mood) {
    if (positiveMoods.contains(mood)) return Colors.green.shade600;
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

      if (!_dailyMoods.containsKey(date)) _dailyMoods[date] = [];
      _dailyMoods[date]!.add(mood);

      if (!_hourlyMoods.containsKey(date)) _hourlyMoods[date] = {};
      _hourlyMoods[date]![hour] = mood;

      _weeklyMoodAverage[week] = (_weeklyMoodAverage[week] ?? 0) + _getMoodValue(mood);
      _monthlyMoodAverage[month] = (_monthlyMoodAverage[month] ?? 0) + _getMoodValue(mood);
    }

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

    _dailyMoods.forEach((date, moods) {
      double avg = moods.map((m) => _getMoodValue(m)).reduce((a, b) => a + b) / moods.length;
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          _updateMoodStats(docs);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: isDark ? Colors.deepPurple.shade700 : Colors.deepPurple.shade100,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
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
                              _moodCounterItem("Happy", _happyCount, Colors.green.shade600),
                              _moodCounterItem("Neutral", _neutralCountReal, Colors.blue.shade400),
                              _moodCounterItem("Sad", _sadCount, Colors.red.shade400),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  _buildMoodMeaningSection(isDark),
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

  Widget _buildMoodMeaningSection(bool isDark) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: isDark ? Colors.deepPurple.shade800 : Colors.deepPurple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Mood Meanings & Interpretations",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 12),
            _buildMoodGroup(
                title: "Positive Moods",
                moods: positiveMoods,
                isDark: isDark,
                color: Colors.green.shade600),
            _buildMoodGroup(
                title: "Neutral Moods",
                moods: neutralMoods,
                isDark: isDark,
                color: Colors.blue.shade400),
            _buildMoodGroup(
                title: "Negative Moods",
                moods: negativeMoods,
                isDark: isDark,
                color: Colors.red.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodGroup({
    required String title,
    required List<String> moods,
    required bool isDark,
    required Color color,
  }) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      collapsedIconColor: color,
      iconColor: color,
      title: Text(
        "$title (${moods.length})",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      children: moods.map((mood) {
        return _buildMoodItem(mood, isDark);
      }).toList(),
    );
  }

  Widget _buildMoodItem(String mood, bool isDark) {
    final meaning = moodMeanings[mood] ?? "No interpretation available.";
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark ? _getMoodColor(mood).withOpacity(0.2)
            : _getMoodColor(mood).withOpacity(0.12),
      ),
      child: ListTile(
        title: Text(
          mood,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            meaning,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
