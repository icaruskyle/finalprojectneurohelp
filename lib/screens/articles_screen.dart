import 'package:flutter/material.dart';

class ArticlesScreen extends StatelessWidget {
  const ArticlesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Latest Articles"),
        backgroundColor: Colors.deepPurple,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          "📰 Here you'll find articles about mental health, self-care, and emotional well-being. "
              "Stay tuned for regular updates!",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
