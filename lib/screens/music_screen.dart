import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'ai_service.dart';

class MusicScreen extends StatefulWidget {
  final String uid;
  final bool isDarkMode;

  const MusicScreen({super.key, required this.uid, required this.isDarkMode});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final AIService ai = AIService();
  String currentMood = '🙂 Neutral';
  bool isLoading = true;

  String? selectedCategory;
  List<String> musicList = [];
  YoutubePlayerController? _youtubeController;

  final List<String> categories = [
    "Songs for Sad Mood",
    "Songs for Happy Mood",
    "Podcasts for Mental Health",
  ];

  final List<Color> categoryColors = [
    Colors.deepPurple.shade300,
    Colors.deepPurple.shade500,
    Colors.deepPurple.shade700,
  ];

  @override
  void initState() {
    super.initState();
    detectMood();
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    super.dispose();
  }

  Future<void> detectMood() async {
    setState(() => isLoading = true);
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
    } catch (_) {
      setState(() {
        currentMood = '🙂 Neutral';
        isLoading = false;
      });
    }
  }

  Future<void> selectCategory(String category) async {
    setState(() {
      selectedCategory = category;
      isLoading = true;
    });

    final list = await ai.getMusicForMood(currentMood, category);

    setState(() {
      musicList = list;
      isLoading = false;
    });

    if (musicList.isNotEmpty) {
      final videoId = YoutubePlayer.convertUrlToId(musicList[0]);
      if (videoId != null) {
        _youtubeController?.dispose();
        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
          ),
        );
      }
    }
  }

  void goBackToCategories() {
    setState(() {
      selectedCategory = null;
      musicList = [];
      _youtubeController?.dispose();
      _youtubeController = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final bgColor = isDark ? Colors.black : const Color(0xFFF6F7FB);

    return Scaffold(
      appBar: AppBar(
        title: const Text("NeuroHelp Music"),
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
      backgroundColor: bgColor,
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
          : selectedCategory == null
          ? Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            return Card(
              color: categoryColors[index],
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: Text(
                  cat,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "Mood detected: $currentMood",
                  style: const TextStyle(color: Colors.white70),
                ),
                onTap: () => selectCategory(cat),
              ),
            );
          },
        ),
      )
          : Column(
        children: [
          Expanded(
            child: musicList.isEmpty
                ? Center(
              child: Text(
                "No music found for $currentMood",
                style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontSize: 16),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: musicList.length,
              itemBuilder: (context, index) {
                final url = musicList[index];
                final videoId = YoutubePlayer.convertUrlToId(url);
                if (videoId == null) return const SizedBox();
                return Card(
                  color: Colors.deepPurple.shade50,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: YoutubePlayer(
                    controller: YoutubePlayerController(
                      initialVideoId: videoId,
                      flags: const YoutubePlayerFlags(
                        autoPlay: false,
                        mute: false,
                      ),
                    ),
                    showVideoProgressIndicator: true,
                    progressIndicatorColor: Colors.deepPurple,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}