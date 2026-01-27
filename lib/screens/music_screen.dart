import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ai_service.dart';
import '../data/music_data.dart';


Color textColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;
Color secondaryTextColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : Colors.black54;
Color cardColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2A2A2A)
        : Colors.white;
Color tileColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFF9F9F9);
class MusicScreen extends StatefulWidget {
  final String uid;
  final bool isDarkMode;

  const MusicScreen({
    super.key,
    required this.uid,
    required this.isDarkMode,
  });

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final AIService ai = AIService();
  String currentMood = '🙂 Neutral';
  bool isLoading = true;

  String? selectedCategory;
  String searchQuery = '';

  AudioPlayer? _audioPlayer;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  bool isPlaying = false;

  String? currentTitle;
  String? currentAsset;

  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> recentlyPlayed = [];


  final List<String> categories = MusicData.categories;
  final Map<String, List<String>> assetMusic = MusicData.assetMusic;

  final int visualizerBars = 20;
  List<double> barHeights = [];
  Timer? visualizerTimer;
  final Random rnd = Random();

  @override
  void initState() {
    super.initState();

    _audioPlayer = AudioPlayer();

    _audioPlayer!.onDurationChanged.listen((d) {
      setState(() => duration = d);
    });

    _audioPlayer!.onPositionChanged.listen((p) {
      setState(() => position = p);
    });

    _audioPlayer!.onPlayerComplete.listen((_) {
      setState(() {
        isPlaying = false;
        position = Duration.zero;
      });
      stopVisualizer();
    });

    barHeights = List<double>.generate(visualizerBars, (_) => 4.0);

    _init();
  }

  Future<void> _init() async {
    await loadRecentlyPlayed();
    await detectMood();

    if (mounted) {
      setState(() => isLoading = false);
    }
  }
  @override
  void dispose() {
    visualizerTimer?.cancel();
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> detectMood() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('daily_journal')
          .orderBy('date', descending: true)
          .limit(5)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() => currentMood = '🙂 Neutral');
        return;
      }

      final texts = snapshot.docs
          .map((d) => d.data()['text']?.toString() ?? '')
          .where((t) => t.trim().isNotEmpty)
          .toList();

      if (texts.isEmpty) {
        setState(() => currentMood = '🙂 Neutral');
        return;
      }

      final combinedText = texts.join('\n');

      print('Mood input length: ${combinedText.length}');
      print(combinedText);

      final mood = await ai.predictMood(combinedText);
      setState(() => currentMood = mood);
    } catch (e) {
      print('detectMood error: $e');
      setState(() => currentMood = '🙂 Neutral');
    }
  }

  Future<void> loadRecentlyPlayed() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getStringList('recently_played') ?? [];
    setState(() {
      recentlyPlayed =
          raw.map((s) => Map<String, dynamic>.from(json.decode(s))).toList();
    });
  }

  Future<void> saveToRecentlyPlayed(String title, String url) async {
    final sp = await SharedPreferences.getInstance();
    final entry = {"title": title, "url": url, "ts": DateTime.now().toIso8601String()};
    recentlyPlayed.removeWhere((e) => e['url'] == url);
    recentlyPlayed.insert(0, entry);
    if (recentlyPlayed.length > 20) recentlyPlayed = recentlyPlayed.sublist(0, 20);

    final encoded = recentlyPlayed.map((e) => json.encode(e)).toList();
    await sp.setStringList('recently_played', encoded);
    setState(() {});
  }

  Future<void> selectCategory(String category) async {
    setState(() {
      selectedCategory = category;
      isLoading = true;
      items = [];
      searchQuery = '';
    });

    final assetList = List<String>.from(assetMusic[category] ?? []);
    assetList.shuffle(rnd);
    final temp = assetList
        .map((path) => {"title": path.split('/').last, "url": path, "type": "asset"})
        .toList();
    setState(() {
      items = temp;
      isLoading = false;
    });
  }

  void goBackToCategories() {
    setState(() {
      selectedCategory = null;
      items = [];
      searchQuery = '';
    });
  }

  Future<void> playItem(Map<String, dynamic> item, {bool openPlayer = true}) async {
    try {
      await _audioPlayer?.stop();
      await _audioPlayer?.play(AssetSource(item['url']));
      setState(() {
        currentTitle = item['title'];
        currentAsset = item['url'];
        isPlaying = true;
      });
      startVisualizer();
      await saveToRecentlyPlayed(item['title'], item['url']);
      if (openPlayer) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FullPlayerPage(
              title: currentTitle ?? 'Unknown',
              asset: currentAsset ?? '',
              audioPlayer: _audioPlayer!,
              isDarkMode: widget.isDarkMode,
              onStop: () {
                _audioPlayer?.stop();
                setState(() => isPlaying = false);
                stopVisualizer();
              },
              getPosition: () => position,
              getDuration: () => duration,
              onSeek: (d) => _audioPlayer?.seek(d),
              onToggle: () {
                if (isPlaying) {
                  _audioPlayer?.pause();
                  stopVisualizer();
                } else {
                  _audioPlayer?.resume();
                  startVisualizer();
                }
                setState(() => isPlaying = !isPlaying);
              },
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error playing: ${e.toString()}')));
    }
  }

  Future<void> _stopAll() async {
    await _audioPlayer?.stop();
    setState(() {
      isPlaying = false;
      currentAsset = null;
      currentTitle = null;
      position = Duration.zero;
    });
    stopVisualizer();
  }

  void startVisualizer() {
    visualizerTimer?.cancel();
    visualizerTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      setState(() {
        for (var i = 0; i < barHeights.length; i++) {
          final factor = 1 + (position.inMilliseconds % 1000) / 1000;
          barHeights[i] = 4 + rnd.nextDouble() * 60 * factor;
        }
      });
    });
  }

  void stopVisualizer() {
    visualizerTimer?.cancel();
    visualizerTimer = null;
    setState(() {
      barHeights = List<double>.generate(visualizerBars, (_) => 4.0);
    });
  }

  List<Map<String, dynamic>> get filteredItems {
    if (searchQuery.trim().isEmpty) return items;
    final q = searchQuery.toLowerCase();
    return items.where((it) {
      final title = (it['title'] ?? '').toString().toLowerCase();
      return title.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    return WillPopScope(
      onWillPop: () async {
        if (selectedCategory != null) {
          goBackToCategories();
          return false;
        }
        return true;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: isDark ? Colors.black : Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('NeuroHelp Music', style: TextStyle(color: textColor(context))),
        ),
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? const [Color(0xFF4A148C), Color(0xFF7B1FA2)]
                      : const [Color(0xFFF8F0FB), Color(0xFFEADCF7)],
                ),
              ),
            ),
            SafeArea(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.2),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        key: ValueKey(currentMood),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? const [Color(0xFF6A1B9A), Color(0xFF8E24AA)]
                                : const [Color(0xFFEDE7F6), Color(0xFFD1C4E9)],
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.mood, color: isDark ? Colors.white : Colors.purple.shade800, size: 30),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mood',
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : Colors.purple.shade700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currentMood,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.purple.shade900,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.55,
                          child: selectedCategory == null
                              ? buildCategoryList()
                              : buildMusicList(),
                        ),
                        buildRecentlyPlayedSection(),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (currentTitle != null)
              Positioned(left: 0, right: 0, bottom: 0, child: miniPlayer(context)),
          ],
        ),
      ),
    );
  }

  Widget buildCategoryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, idx) {
        final cat = categories[idx];
        return GestureDetector(
          onTap: () => selectCategory(cat),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardColor(context).withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              title: Text(cat, style: TextStyle(color: textColor(context), fontWeight: FontWeight.bold)),
              subtitle: Text('Mood: $currentMood', style: TextStyle(color: secondaryTextColor(context))),
              trailing: Icon(Icons.chevron_right, color: textColor(context)),
            ),
          ),
        );
      },
    );
  }

  Widget buildMusicList() {
    final list = filteredItems;
    if (list.isEmpty) {
      return Center(
        child: Text('No songs found', style: TextStyle(color: textColor(context))),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, idx) {
        final item = list[idx];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: cardColor(context).withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            title: Text(item['title'] ?? '', style: TextStyle(color: textColor(context))),
            subtitle: Text(item['url'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: secondaryTextColor(context))),
            trailing: IconButton(icon: Icon(Icons.play_arrow, color: textColor(context)), onPressed: () => playItem(item)),
            onTap: () => playItem(item),
          ),
        );
      },
    );
  }

  Widget buildRecentlyPlayedSection() {
    if (recentlyPlayed.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recently Played',
            style: TextStyle(
              color: textColor(context),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentlyPlayed.length,
            separatorBuilder: (_, __) => Divider(
              color: Colors.white.withOpacity(0.15),
              height: 1,
            ),
            itemBuilder: (context, idx) {
              final e = recentlyPlayed[idx];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.history,
                  color: Colors.purpleAccent,
                ),
                title: Text(
                  e['title'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textColor(context)),
                ),
                onTap: () => playItem({
                  'title': e['title'],
                  'url': e['url'],
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget miniPlayer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF7B1FA2), Color(0xFFCE93D8)]),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (currentTitle != null && currentAsset != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FullPlayerPage(
                      title: currentTitle ?? 'Unknown',
                      asset: currentAsset ?? '',
                      audioPlayer: _audioPlayer!,
                      isDarkMode: widget.isDarkMode,
                      onStop: () {
                        _audioPlayer?.stop();
                        setState(() => isPlaying = false);
                        stopVisualizer();
                      },
                      getPosition: () => position,
                      getDuration: () => duration,
                      onSeek: (d) => _audioPlayer?.seek(d),
                      onToggle: () {
                        if (isPlaying) {
                          _audioPlayer?.pause();
                          stopVisualizer();
                        } else {
                          _audioPlayer?.resume();
                          startVisualizer();
                        }

                        setState(() => isPlaying = !isPlaying);
                      },
                    ),
                  ),
                );
              }
            },
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  colors: [Color(0xFF7B1FA2), Color(0xFFCE93D8)],
                ),
              ),
              child: const Icon(Icons.music_note, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(currentTitle ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Slider(
                  value: position.inMilliseconds.toDouble().clamp(0, duration.inMilliseconds.toDouble() > 0 ? duration.inMilliseconds.toDouble() : 1),
                  min: 0,
                  max: duration.inMilliseconds.toDouble() > 0 ? duration.inMilliseconds.toDouble() : 1,
                  onChanged: (v) {
                    final d = Duration(milliseconds: v.toInt());
                    _audioPlayer?.seek(d);
                  },
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: Colors.white, size: 36),
            onPressed: () {
              if (isPlaying) {
                _audioPlayer?.pause();
                stopVisualizer();
              } else {
                _audioPlayer?.resume();
                startVisualizer();
              }
              setState(() => isPlaying = !isPlaying);
            },
          ),
        ],
      ),
    );
  }
}

class FullPlayerPage extends StatefulWidget {
  final String title;
  final String asset;
  final AudioPlayer audioPlayer;
  final bool isDarkMode;
  final VoidCallback onStop;
  final Duration Function() getPosition;
  final Duration Function() getDuration;
  final void Function(Duration) onSeek;
  final VoidCallback onToggle;

  const FullPlayerPage({
    super.key,
    required this.title,
    required this.asset,
    required this.audioPlayer,
    required this.isDarkMode,
    required this.onStop,
    required this.getPosition,
    required this.getDuration,
    required this.onSeek,
    required this.onToggle,
  });

  @override
  State<FullPlayerPage> createState() => _FullPlayerPageState();
}

class _FullPlayerPageState extends State<FullPlayerPage> {
  Timer? _timer;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  final Random rnd = Random();
  List<double> bars = List.generate(24, (_) => 4.0);
  Timer? animTimer;

  @override
  void initState() {
    super.initState();
    animTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      setState(() {
        for (int i = 0; i < bars.length; i++) {
          bars[i] = 4 + rnd.nextDouble() * 60;
        }
      });
    });
    _timer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      setState(() {
        position = widget.getPosition();
        duration = widget.getDuration();
      });
    });
  }

  @override
  void dispose() {
    animTimer?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.title,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [Colors.purple.shade400, Colors.purple.shade200],
              ),
            ),
            child: const Icon(Icons.music_note, size: 120, color: Colors.white),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: bars
                  .map((h) => Container(
                width: 4,
                height: h,
                decoration: BoxDecoration(
                  color: Colors.purpleAccent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
          Slider(
            min: 0,
            max: duration.inMilliseconds > 0
                ? duration.inMilliseconds.toDouble()
                : 1,
            value: position.inMilliseconds
                .toDouble()
                .clamp(0, duration.inMilliseconds.toDouble()),
            onChanged: (v) =>
                widget.onSeek(Duration(milliseconds: v.toInt())),
          ),
          Text(
            '${position.toString().split('.').first} / ${duration.toString().split('.').first}',
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
          const SizedBox(height: 20),
          IconButton(
            icon: Icon(
              widget.audioPlayer.state == PlayerState.playing
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_fill,
              size: 60,
              color: Colors.purple,
            ),
            onPressed: () {
              widget.onToggle();
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}