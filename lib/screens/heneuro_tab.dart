import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'ai_service.dart';
import 'package:intl/intl.dart';

class HeneuroTab extends StatefulWidget {
  final bool isDarkMode;
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
  final ScrollController _scrollController = ScrollController();
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

  // ---------------- Load Chat Sessions ----------------
  Future<void> _loadSessions() async {
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('chat_history')
        .orderBy('created_at', descending: true)
        .get();

    setState(() {
      sessions = snapshot.docs.map((doc) {
        List<dynamic> msgs = [];
        try {
          msgs = json.decode(doc['messages'] ?? '[]');
        } catch (_) {}
        String lastMsg = msgs.isNotEmpty ? (msgs.last['text'] ?? '') : 'No messages yet';
        return {
          'id': doc.id,
          'name': doc['name'] ?? 'Session',
          'created_at': doc['created_at'],
          'last_message': lastMsg,
        };
      }).toList();
    });
  }

  // ---------------- Session Management ----------------
  Future<void> _createSessionIfNone() async {
    if (currentSessionId == null) await createNewSession();
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
      try {
        messages = List<Map<String, String>>.from(json.decode(data['messages'] ?? '[]'));
      } catch (_) {
        messages = [];
      }

      setState(() {
        currentSessionId = sessionId;
        isSidebarOpen = false;
      });
      _scrollToBottom();
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
    _scrollToBottom();

    String reply;
    if (ai.detectSuicidalRisk(userInput)) {
      reply =
      "⚠️ It seems you may be at risk. Please consider reaching out for help immediately.";
    } else {
      reply = await ai.getAIResponse(userInput);
    }

    setState(() {
      messages.add({
        "sender": "ai",
        "text": reply,
        "time": DateTime.now().toIso8601String()
      });
      _isLoading = false;
    });
    _scrollToBottom();

    if (currentSessionId != null && user != null) {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('chat_history')
          .doc(currentSessionId);
      await docRef.set({
        'messages': json.encode(messages),
        'updated_at': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    }

    await _loadSessions(); // refresh sidebar with last messages
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String formatTime(String isoTime) {
    final dt = DateTime.parse(isoTime).toLocal();
    return DateFormat('hh:mm a').format(dt);
  }

  Color _getAIBubbleColor(String text) {
    return widget.isDarkMode ? Colors.grey[800]! : Colors.deepPurple.shade100;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final bg = widget.isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final text = widget.isDarkMode ? Colors.white : Colors.black;

    final filteredSessions = searchQuery.isEmpty
        ? sessions
        : sessions
        .where((session) => session['name']
        .toString()
        .toLowerCase()
        .contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat with Henuero 🤖"),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(isSidebarOpen ? Icons.close : Icons.menu),
            onPressed: () => setState(() => isSidebarOpen = !isSidebarOpen),
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
          // Sidebar
          if (isSidebarOpen)
            Container(
              width: 270,
              color: widget.isDarkMode ? Colors.grey[900] : Colors.deepPurple.shade50,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Chat Sessions',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                          labelText: 'Search session', border: OutlineInputBorder()),
                      onChanged: (val) => setState(() => searchQuery = val),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredSessions.length,
                      itemBuilder: (context, index) {
                        final session = filteredSessions[index];
                        final createdAt = DateTime.parse(
                            session['created_at'] ?? DateTime.now().toString());
                        final sessionId = session['id'];
                        final sessionName = session['name'];
                        final lastMsg = session['last_message'] ?? '';

                        return ListTile(
                          contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          title: Text(
                            sessionName,
                            style: TextStyle(
                              color: sessionId == currentSessionId
                                  ? Colors.deepPurple
                                  : text,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lastMsg.length > 30
                                    ? "${lastMsg.substring(0, 30)}..."
                                    : lastMsg,
                                style: TextStyle(fontSize: 12, color: text.withOpacity(0.7)),
                              ),
                              Text(
                                DateFormat('MMM dd, yyyy – hh:mm a').format(createdAt),
                                style: TextStyle(fontSize: 11, color: text.withOpacity(0.5)),
                              ),
                            ],
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

          // Chat Panel
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isLoading && index == 0) {
                        return TypingIndicator(isDarkMode: widget.isDarkMode);
                      }

                      final msg = messages[messages.length - 1 - (_isLoading ? index - 1 : index)];
                      final isUser = msg["sender"] == "user";

                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: isUser
                                ? Colors.deepPurple
                                : _getAIBubbleColor(msg['text'] ?? ''),
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
                                    color: isUser ? Colors.white : text, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                msg["time"] != null ? formatTime(msg["time"]!) : "",
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
                          onSubmitted: (_) => _sendMessage(),
                          decoration: InputDecoration(
                            hintText: "Ask Henuero something...",
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
                        label: const Text("Send", style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
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

// ---------------- Typing Indicator ----------------
class TypingIndicator extends StatefulWidget {
  final bool isDarkMode;
  const TypingIndicator({super.key, required this.isDarkMode});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _dotAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    _dotAnimation = StepTween(begin: 1, end: 3).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String getDots(int count) => '.' * count;

  @override
  Widget build(BuildContext context) {
    final bubbleColor =
    widget.isDarkMode ? Colors.grey[800] : Colors.deepPurple.shade100;
    final textColor = widget.isDarkMode ? Colors.white : Colors.black87;

    return Align(
      alignment: Alignment.centerLeft,
      child: AnimatedBuilder(
        animation: _dotAnimation,
        builder: (context, child) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(12),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
                bottomLeft: Radius.circular(0),
              ),
            ),
            child: Text(
              'Henuero is typing${getDots(_dotAnimation.value)}',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: textColor,
              ),
            ),
          );
        },
      ),
    );
  }
}
