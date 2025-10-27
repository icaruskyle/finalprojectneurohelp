// journaling_screen.dart
import 'package:flutter/material.dart';

class JournalingScreen extends StatefulWidget {
  const JournalingScreen({super.key});

  @override
  State<JournalingScreen> createState() => _JournalingScreenState();
}

class _JournalingScreenState extends State<JournalingScreen> {
  final TextEditingController _controller = TextEditingController();
  String? savedNote;

  void saveNote() {
    setState(() {
      savedNote = _controller.text;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Your journal entry has been saved 💜")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Journaling"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purpleAccent, Colors.deepPurple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                "🖊 Reflect on your thoughts or write about your day.",
                style: TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _controller,
                maxLines: 8,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: "Write your thoughts here...",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: saveNote,
                icon: const Icon(Icons.save),
                label: const Text("Save Entry"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.deepPurple,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
              ),
              const SizedBox(height: 20),
              if (savedNote != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("🗒 Your Saved Entry:",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(savedNote!),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
