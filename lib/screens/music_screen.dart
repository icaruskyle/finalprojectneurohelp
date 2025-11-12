import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MusicScreen extends StatefulWidget {
  final String username;
  const MusicScreen({super.key, required this.username});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://open.spotify.com/'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Spotify Player - ${widget.username}'),
        backgroundColor: Colors.deepPurple,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
