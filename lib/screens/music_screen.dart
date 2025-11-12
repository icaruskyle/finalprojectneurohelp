import 'package:flutter/material.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

class MusicScreen extends StatefulWidget {
  final bool isDarkMode;
  const MusicScreen({super.key, required this.isDarkMode});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final AudioPlayer _player = AudioPlayer();
  List tracks = [];
  bool isLoading = false;
  String? accessToken;

  @override
  void initState() {
    super.initState();
    _loginAndFetch();
  }

  Future<void> _loginAndFetch() async {
    setState(() => isLoading = true);
    try {
      await _authenticateSpotify();
      tracks = await _getTracks();
    } catch (e) {
      print('Spotify Error: $e');
    }
    setState(() => isLoading = false);
  }

  // Spotify Authentication
  Future<void> _authenticateSpotify() async {
    const clientId = '9971ab74b7694d19b7b7ff7856524724';
    const redirectUri = 'neurohelp://callback';

    final url = Uri.https('accounts.spotify.com', '/authorize', {
      'client_id': clientId,
      'response_type': 'token',
      'redirect_uri': redirectUri,
      'scope': 'user-read-private user-read-email streaming',
    });

    final result = await FlutterWebAuth.authenticate(
        url: url.toString(), callbackUrlScheme: 'neurohelp');

    final fragment = Uri.parse(result).fragment;
    final params = Uri.splitQueryString(fragment);

    accessToken = params['access_token'];
  }

  // Fetch new releases from Spotify
  Future<List> _getTracks() async {
    if (accessToken == null) return [];

    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/browse/new-releases'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['albums']['items'];
    } else {
      print('Spotify API Error: ${response.statusCode}');
      return [];
    }
  }

  void _playPreview(String? url) async {
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preview not available for this track')),
      );
      return;
    }

    try {
      await _player.setUrl(url);
      _player.play();
    } catch (e) {
      print('Error playing track: $e');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDarkMode ? Colors.black : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : Colors.black;
    final appBarColor = widget.isDarkMode ? Colors.grey[900] : Colors.blue;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Music'),
        backgroundColor: appBarColor,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: tracks.length,
        itemBuilder: (context, index) {
          final track = tracks[index];
          return Card(
            color: widget.isDarkMode ? Colors.grey[850] : Colors.white,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: Image.network(track['images'][0]['url']),
              title: Text(track['name'], style: TextStyle(color: textColor)),
              subtitle: Text(track['artists'][0]['name'],
                  style: TextStyle(color: textColor.withOpacity(0.7))),
              trailing: IconButton(
                icon: const Icon(Icons.play_arrow),
                color: widget.isDarkMode ? Colors.white : Colors.black,
                onPressed: () => _playPreview(track['preview_url']),
              ),
            ),
          );
        },
      ),
    );
  }
}
