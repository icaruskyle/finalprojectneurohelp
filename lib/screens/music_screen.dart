import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Global ValueNotifier to track mood in real-time
ValueNotifier<String> moodNotifier = ValueNotifier<String>('cheerful');

// Singleton AudioPlayer for background playback across screens
final AudioPlayer globalAudioPlayer = AudioPlayer();

class MusicScreen extends StatefulWidget {
  final String username;
  const MusicScreen({super.key, required this.username});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  String? _currentlyPlayingUrl;

  // Songs based on mood
  final List<Map<String, String>> sadSongs = [
    {
      'title': 'Niki - lowkey',
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    },
    {
      'title': 'Earl Agustin - Sad Song',
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    },
    {
      'title': 'Silent Sanctuary - Ikaw at Ako',
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
    },
  ];

  final List<Map<String, String>> cheerfulSongs = [
    {
      'title': 'Niki - Parade',
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
    },
    {
      'title': 'Earl Agustin - Happy Song',
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
    },
    {
      'title': 'Silent Sanctuary - Musika',
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadMood();
    // Listen for mood changes
    moodNotifier.addListener(() {
      _autoPlayBasedOnMood();
      setState(() {}); // rebuild UI
    });
  }

  Future<void> _loadMood() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String mood = prefs.getString('lastMood') ?? 'cheerful';
    moodNotifier.value = mood;
  }

  void _autoPlayBasedOnMood() {
    List<Map<String, String>> songs =
    moodNotifier.value == 'sad' ? sadSongs : cheerfulSongs;

    // Play the first song automatically if nothing is playing
    if (_currentlyPlayingUrl == null && songs.isNotEmpty) {
      _playSong(songs[0]['url']!);
    }
  }

  void _playSong(String url) async {
    if (_currentlyPlayingUrl == url) {
      await globalAudioPlayer.pause();
      setState(() {
        _currentlyPlayingUrl = null;
      });
    } else {
      await globalAudioPlayer.play(UrlSource(url));
      setState(() {
        _currentlyPlayingUrl = url;
      });
    }
  }

  @override
  void dispose() {
    // Do NOT dispose globalAudioPlayer here, to allow background playback
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String currentMood = moodNotifier.value;
    List<Map<String, String>> songs =
    currentMood == 'sad' ? sadSongs : cheerfulSongs;

    return Scaffold(
      appBar: AppBar(
        title: Text('Music Player - ${widget.username}'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              'Your mood: $currentMood',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                final isPlaying = _currentlyPlayingUrl == song['url'];

                return ListTile(
                  leading:
                  Icon(isPlaying ? Icons.pause_circle : Icons.play_circle),
                  title: Text(song['title']!),
                  onTap: () => _playSong(song['url']!),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
