import 'package:flutter/material.dart';

class MusicScreen extends StatelessWidget {
  const MusicScreen({super.key});

  // Show alert dialog for coming soon feature
  void _showComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Coming Soon"),
        content: const Text("Spotify connection feature is under development."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Example UI
    return Scaffold(
      appBar: AppBar(
        title: const Text("Music"),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _showComingSoon(context),
          child: const Text("Connect to Spotify"),
        ),
      ),
    );
  }
}
