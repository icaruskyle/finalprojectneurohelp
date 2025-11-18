import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'ai_service.dart';

class MusicScreen extends StatefulWidget {
  final String uid;
  final bool isDarkMode;

  const MusicScreen({super.key, required this.uid, required this.isDarkMode});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> with TickerProviderStateMixin {
  final AIService ai = AIService();
  String currentMood = '🙂 Neutral';
  bool isLoading = true;

  String? selectedCategory;
  List<String> musicList = [];
  TabController? tabController;

  final List<String> moods = [
    "😊 Happy", "😇 Grateful", "😌 Content", "😎 Confident", "🥳 Excited",
    "😚 Loved", "🤗 Hopeful", "🤩 Inspired", "😋 Playful", "🤠 Cheerful",
    "🧘 Calm", "🙂 Neutral", "😢 Sad", "💔 Heartbroken", "😞 Disappointed",
    "😔 Lonely", "😩 Overwhelmed", "😕 Confused", "😟 Anxious", "😰 Stressed",
    "😤 Frustrated", "😠 Irritated", "😡 Angry", "😬 Nervous", "😳 Embarrassed",
    "😴 Tired", "😫 Exhausted", "😩 Hopeless", "😶 Empty", "😑 Bored",
    "🤒 Unwell", "🤯 Burned Out", "⚠️ Suicidal/Warning", "🤔 Reflective",
    "😌 Thoughtful", "😮 Surprised", "😶 Indifferent", "😐 Blank", "🫤 Uncertain",
    "🤫 Quiet", "😅 Awkward", "🤨 Skeptical", "🤓 Focused", "🤭 Amused"
  ];

  final List<String> categories = [
    "Songs for Sad Songs",
    "Songs for Happy Songs",
    "Songs that Ease Your Pain",
    "Podcast for Mental Health",
  ];

  @override
  void initState() {
    super.initState();
    detectMood();
  }

  Future<void> detectMood() async {
    setState(() {
      isLoading = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('daily_journal')
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      String journalText = '';
      if (snapshot.docs.isNotEmpty) {
        journalText = snapshot.docs.first.data()['text'] ?? '';
      }

      final mood = await ai.predictMood(journalText);

      setState(() {
        currentMood = mood;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        currentMood = '🙂 Neutral';
        isLoading = false;
      });
    }
  }

  Future<void> selectCategory(String category) async {
    setState(() {
      selectedCategory = category;
      tabController = TabController(length: moods.length, vsync: this);
      isLoading = true;
    });

    // Scroll to detected mood
    final moodIndex = moods.indexOf(currentMood);
    if (moodIndex != -1 && tabController != null) {
      tabController!.index = moodIndex;
    }

    // Fetch music dynamically from AI
    final list = await ai.getMusicForMood(currentMood, category);

    setState(() {
      musicList = list;
      isLoading = false;
    });
  }

  void goBackToCategories() {
    setState(() {
      selectedCategory = null;
      musicList = [];
      tabController?.dispose();
      tabController = null;
    });
  }

  Future<void> _openMusic(String url) async {
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
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Listen to Music"),
        backgroundColor: isDark ? Colors.deepPurple.shade700 : Colors.deepPurple,
        leading: selectedCategory != null
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: goBackToCategories,
        )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: detectMood,
            tooltip: "Refresh Mood Music",
          ),
        ],
      ),
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : selectedCategory == null
          ? Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: categories.map((cat) {
            return Card(
              color: isDark ? Colors.deepPurple.shade800 : Colors.deepPurple.shade50,
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: Text(
                  cat,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "Mood detected: $currentMood",
                  style: const TextStyle(color: Colors.white70),
                ),
                onTap: () => selectCategory(cat),
              ),
            );
          }).toList(),
        ),
      )
          : Column(
        children: [
          TabBar(
            controller: tabController,
            isScrollable: true,
            indicatorColor: Colors.white,
            tabs: moods.map((m) => Tab(text: m)).toList(),
          ),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: moods.map((m) {
                return FutureBuilder<List<String>>(
                  future: ai.getMusicForMood(m, selectedCategory!),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final list = snapshot.data!;
                    if (list.isEmpty) {
                      return Center(
                        child: Text(
                          "No music found for $m",
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final url = list[index];
                        return Card(
                          color: isDark ? Colors.deepPurple.shade800 : Colors.deepPurple.shade50,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: const Icon(Icons.music_note, color: Colors.white),
                            title: Text(
                              "Song ${index + 1}",
                              style: const TextStyle(color: Colors.white),
                            ),
                            trailing: const Icon(Icons.open_in_new, color: Colors.white),
                            onTap: () => _openMusic(url),
                          ),
                        );
                      },
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
