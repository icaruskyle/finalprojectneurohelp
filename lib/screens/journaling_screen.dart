import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JournalingScreen extends StatefulWidget {
  const JournalingScreen({super.key});

  @override
  State<JournalingScreen> createState() => _JournalingScreenState();
}

class _JournalingScreenState extends State<JournalingScreen> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String uid;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) uid = user.uid;
  }

  Future<void> saveNote() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('journals')
        .add({
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _showTopNotification("✅ Your journal entry has been saved!");
  }

  Future<void> deleteNote(String docId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('journals')
        .doc(docId)
        .delete();

    _showTopNotification("🗑 Journal entry deleted.");
  }

  void _showTopNotification(String message, {bool isError = false}) {
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50,
        left: 20,
        right: 20,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(12),
          color: isError ? Colors.red[400] : Colors.deepPurple[400],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3)).then((_) => overlayEntry.remove());
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Journaling"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [Colors.deepPurple.shade800, Colors.black87]
                : [Colors.purpleAccent, Colors.deepPurple],
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
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: "Write your thoughts here...",
                  hintStyle: TextStyle(
                      color: isDarkMode ? Colors.white54 : Colors.black45),
                  filled: true,
                  fillColor:
                  isDarkMode ? Colors.grey[800] : Colors.white.withOpacity(0.9),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('users')
                      .doc(uid)
                      .collection('journals')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return const Center(
                        child: Text(
                          "No journal entries yet.",
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final text = doc['text'] ?? '';
                        final timestamp = doc['timestamp'] != null
                            ? (doc['timestamp'] as Timestamp).toDate()
                            : DateTime.now();
                        return Card(
                          color: isDarkMode
                              ? Colors.grey[850]
                              : Colors.white.withOpacity(0.9),
                          child: ListTile(
                            title: Text(
                              text,
                              style: TextStyle(
                                  color: isDarkMode ? Colors.white : Colors.black87),
                            ),
                            subtitle: Text(
                              "${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}",
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete,
                                  color: isDarkMode ? Colors.red[300] : Colors.red),
                              onPressed: () => deleteNote(doc.id),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
