import 'package:flutter/material.dart';

class SelfHelpScreen extends StatelessWidget {
  const SelfHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final resources = [
      {
        "title": "Breathing Exercise",
        "desc": "Practice deep breathing for 5 minutes to reduce stress."
      },
      {
        "title": "Mindfulness",
        "desc": "Focus on the present moment and acknowledge your feelings."
      },
      {
        "title": "Journaling",
        "desc": "Write down your thoughts to clear your mind."
      },
      {
        "title": "Gratitude List",
        "desc": "List 3 things you’re grateful for today."
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Self-Help Resources"),
        backgroundColor: Colors.purple,
      ),
      body: ListView.builder(
        itemCount: resources.length,
        itemBuilder: (context, index) {
          final resource = resources[index];
          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              leading: const Icon(Icons.self_improvement,
                  color: Colors.deepPurple),
              title: Text(resource["title"]!),
              subtitle: Text(resource["desc"]!),
            ),
          );
        },
      ),
    );
  }
}
