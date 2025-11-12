import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'ai_service.dart';
import 'package:intl/intl.dart';

class HeneuroTab extends StatefulWidget {
  final bool isDarkMode; // Controlled by Dashboard
  const HeneuroTab({super.key, required this.isDarkMode});

  @override
  State<HeneuroTab> createState() => _HeneuroTabState();
}

class _HeneuroTabState extends State<HeneuroTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _controller = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ai = AIService();

  final user = FirebaseAuth.instance.currentUser;

  bool isSidebarOpen = true;
  String? currentSessionId;
  List<Map<String, String>> messages = [];
  List<Map<String, dynamic>> sessions = [];
  bool _isLoading = false;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  // ---------------- Session Management ----------------
  Future<void> _loadSessions() async {
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('chat_history')
        .orderBy('created_at', descending: true)
        .get();

    setState(() {
      sessions = snapshot.docs
          .map((doc) => {
        'id': doc.id,
        'name': doc['name'] ?? 'Session',
        'created_at': doc['created_at'],
      })
          .toList();
    });
  }

  Future<void> _createSessionIfNone() async {
    if (currentSessionId == null) {
      await createNewSession();
    }
  }

  Future<void> createNewSession() async {
    if (user == null) return;

    final now = DateTime.now();
    final newDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('chat_history')
        .doc();

    await newDoc.set({
      'messages': json.encode([]),
      'created_at': now.toIso8601String(),
      'name': 'New Session',
    });

    await _loadSessions();
    setState(() {
      currentSessionId = newDoc.id;
      messages = [];
      isSidebarOpen = false;
    });
  }

  Future<void> openSession(String sessionId) async {
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('chat_history')
        .doc(sessionId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        currentSessionId = sessionId;
        messages =
        List<Map<String, String>>.from(json.decode(data['messages'] ?? '[]'));
        isSidebarOpen = false;
      });
    }
  }

  Future<void> deleteSession(String sessionId) async {
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('chat_history')
        .doc(sessionId)
        .delete();

    if (sessionId == currentSessionId) {
      setState(() {
        currentSessionId = null;
        messages = [];
      });
    }

    await _loadSessions();
  }

  Future<void> clearMessages() async {
    if (currentSessionId == null || user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('chat_history')
        .doc(currentSessionId)
        .update({'messages': json.encode([])});

    setState(() => messages = []);
  }

  // ---------------- Chat ----------------
  Future<void> _sendMessage() async {
    final userInput = _controller.text.trim();
    if (userInput.isEmpty) return;

    await _createSessionIfNone();

    setState(() {
      messages.add({
        "sender": "user",
        "text": userInput,
        "time": DateTime.now().toIso8601String()
      });
      _isLoading = true;
      isSidebarOpen = false;
    });
    _controller.clear();

    // ✅ Use the updated AIService method
    final reply = await ai.predictMood(userInput);

    setState(() {
      messages.add({
        "sender": "ai",
        "text": reply,
        "time": DateTime.now().toIso8601String()
      });
      _isLoading = false;
    });

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('chat_history')
        .doc(currentSessionId);
    await docRef.set({'messages': json.encode(messages)}, SetOptions(merge: true));
  }

  String formatTime(String isoTime) {
    final dt = DateTime.parse(isoTime).toLocal();
    return DateFormat('hh:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final bg = widget.isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final text = widget.isDarkMode ? Colors.white : Colors.black;

    final filteredMessages = searchQuery.isEmpty
        ? messages
        : messages
        .where((msg) =>
        msg['text']!.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat with Heneuro 🤖"),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(isSidebarOpen ? Icons.close : Icons.menu),
            onPressed: () {
              setState(() => isSidebarOpen = !isSidebarOpen);
            },
          ),
          if (currentSessionId != null)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: "Clear Messages",
              onPressed: clearMessages,
            ),
        ],
      ),
      backgroundColor: bg,
      body: Row(
        children: [
          // ---------------- Sidebar ----------------
          if (isSidebarOpen)
            Container(
              width: 250,
              color: widget.isDarkMode ? Colors.grey[900] : Colors.deepPurple.shade50,
              child: Column(
                children: [
                  // Top bar with + button
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Chat Sessions',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.deepPurple),
                          tooltip: "New Session",
                          onPressed: createNewSession,
                        ),
                      ],
                    ),
                  ),
                  // Search box
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                          labelText: 'Search messages',
                          border: OutlineInputBorder()),
                      onChanged: (val) => setState(() => searchQuery = val),
                    ),
                  ),
                  // List of sessions
                  Expanded(
                    child: ListView.builder(
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        final createdAt = DateTime.parse(
                            session['created_at'] ?? DateTime.now().toString());
                        final sessionId = session['id'];
                        final sessionName = session['name'];

                        return ListTile(
                          title: Text(
                            sessionName,
                            style: TextStyle(
                              color: sessionId == currentSessionId
                                  ? Colors.deepPurple
                                  : text,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            DateFormat('MMM dd, yyyy – hh:mm a').format(createdAt),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_forever,
                                color: Colors.red, size: 20),
                            onPressed: () => deleteSession(sessionId),
                          ),
                          onTap: () => openSession(sessionId),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          // ---------------- Chat Area ----------------
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: ScrollController(),
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredMessages.length,
                    itemBuilder: (context, index) {
                      final msg = filteredMessages[index];
                      final isUser = msg["sender"] == "user";

                      return Align(
                        alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: isUser
                                ? Colors.deepPurple
                                : (widget.isDarkMode
                                ? Colors.grey[800]
                                : Colors.deepPurple.shade100),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(12),
                              topRight: const Radius.circular(12),
                              bottomLeft: Radius.circular(isUser ? 12 : 0),
                              bottomRight: Radius.circular(isUser ? 0 : 12),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg["text"] ?? "",
                                style: TextStyle(
                                  color: isUser ? Colors.white : text,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                msg["time"] != null
                                    ? formatTime(msg["time"]!)
                                    : "",
                                style: TextStyle(
                                    fontSize: 10,
                                    color: isUser
                                        ? Colors.white70
                                        : text.withOpacity(0.7)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: TextStyle(color: text),
                          decoration: InputDecoration(
                            hintText: "Ask something...",
                            hintStyle: TextStyle(color: text.withOpacity(0.6)),
                            filled: true,
                            fillColor: widget.isDarkMode
                                ? Colors.deepPurple.withOpacity(0.2)
                                : Colors.deepPurple.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _sendMessage,
                        icon: const Icon(Icons.send, color: Colors.white, size: 20),
                        label: const Text("Send",
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
