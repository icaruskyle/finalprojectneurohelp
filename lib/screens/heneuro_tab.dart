import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:async';
import 'ai_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/scheduler.dart';

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

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    if (user == null) return;

    try {
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
            msgs = json.decode(doc.data()['messages'] ?? '[]');
          } catch (_) {
            msgs = [];
          }
          String lastMsg =
          msgs.isNotEmpty ? (msgs.last['text'] ?? '') : 'No messages yet';
          return {
            'id': doc.id,
            'name': doc.data()['name'] ?? 'Session',
            'created_at': doc.data()['created_at'] ?? DateTime.now().toIso8601String(),
            'last_message': lastMsg,
          };
        }).toList();
      });
    } catch (e) {

      debugPrint("Error loading sessions: $e");
    }
  }

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

    try {
      await newDoc.set({
        'messages': json.encode([]),
        'created_at': now.toIso8601String(),
        'name': 'Session ${DateFormat('yyyyMMdd_HHmm').format(now)}',
      });

      await _loadSessions();
      setState(() {
        currentSessionId = newDoc.id;
        messages = [];
        isSidebarOpen = false;
      });
    } catch (e) {
      debugPrint("Error creating session: $e");
    }
  }

  Future<void> openSession(String sessionId) async {
    if (user == null) return;

    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('chat_history')
          .doc(sessionId);

      final doc = await docRef.get();

      if (doc.exists) {
        final data = doc.data()!;
        List<Map<String, String>> loaded = [];
        try {
          final raw = data['messages'] ?? '[]';
          final decoded = json.decode(raw);
          loaded = List<Map<String, String>>.from(decoded.map((m) {
            return Map<String, String>.from(m.map((k, v) =>
                MapEntry(k.toString(), v == null ? '' : v.toString())));
          }));
        } catch (e) {
          loaded = [];
        }

        setState(() {
          currentSessionId = sessionId;
          messages = loaded;
          isSidebarOpen = false;
        });

        SchedulerBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom(animated: false);
        });
      }
    } catch (e) {
      debugPrint("Error opening session: $e");
    }
  }

  Future<void> deleteSession(String sessionId) async {
    if (user == null) return;
    try {
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
    } catch (e) {
      debugPrint("Error deleting session: $e");
    }
  }

  Future<void> clearMessages() async {
    if (currentSessionId == null || user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('chat_history')
          .doc(currentSessionId)
          .update({'messages': json.encode([])});

      setState(() => messages = []);
    } catch (e) {
      debugPrint("Error clearing messages: $e");
    }
  }

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

    String reply = '';

    try {
      final conversationContext = messages
          .map((msg) => "${msg['sender']}: ${msg['text']}")
          .join("\n");

      reply = await ai
          .getAIResponse(conversationContext)
          .timeout(const Duration(seconds: 20), onTimeout: () {
        return "⚠️ Henuero took too long to respond. Please try again later.";
      });
    } catch (e) {
      reply = "⚠️ Henuero is currently unavailable. Please try again later.";
      debugPrint("AI Error: $e");
    }

    setState(() {
      messages.add({
        "sender": "ai",
        "text": reply,
        "time": DateTime.now().toIso8601String()
      });
      _isLoading = false;
    });

    if (currentSessionId != null && user != null) {
      try {
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('chat_history')
            .doc(currentSessionId);

        await docRef.set({
          'messages': json.encode(messages),
          'updated_at': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));

        await _loadSessions();
      } catch (e) {
        debugPrint("Error saving messages: $e");
      }
    }

    _scrollToBottom();
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position.maxScrollExtent;
    if (animated) {
      try {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } catch (_) {}
    } else {
      try {
        _scrollController.jumpTo(0.0);
      } catch (_) {}
    }
  }

  String formatTime(String isoTime) {
    try {
      final dt = DateTime.parse(isoTime).toLocal();
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return '';
    }
  }

  Color _getAIBubbleColor(String text) {
    return widget.isDarkMode ? Colors.grey[850]! : Colors.deepPurple.shade50;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final bg = widget.isDarkMode ? const Color(0xFF101014) : Colors.white;
    final text = widget.isDarkMode ? Colors.white : Colors.black87;

    final filteredSessions = searchQuery.isEmpty
        ? sessions
        : sessions
        .where((session) => session['name']
        .toString()
        .toLowerCase()
        .contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text(
          "Chat with Henuero 🤖",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor:
        widget.isDarkMode ? Colors.deepPurple.shade400 : Colors.deepPurple,
        elevation: 4,
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
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: isSidebarOpen ? 250 : 0,
            curve: Curves.easeInOut,
            child: AnimatedOpacity(
              opacity: isSidebarOpen ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                color:
                widget.isDarkMode ? const Color(0xFF1E1E23) : Colors.deepPurple.shade50,
                child: Column(
                  children: [
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      child: Row(
                        children: [
                          if (isSidebarOpen)
                            const Expanded(
                              child: Text(
                                'Chat Sessions',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          if (isSidebarOpen)
                            IconButton(
                              icon: const Icon(Icons.add, color: Colors.deepPurple),
                              tooltip: "New Session",
                              onPressed: createNewSession,
                            ),
                        ],
                      ),
                    ),
                    if (isSidebarOpen)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search session',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (val) => setState(() {
                            searchQuery = val;
                          }),
                        ),
                      ),
                    // Session List
                    if (isSidebarOpen)
                      Expanded(
                        child: filteredSessions.isEmpty
                            ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              "No sessions yet. Tap + to create one.",
                              style: TextStyle(color: text.withOpacity(0.6)),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                            : ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: filteredSessions.length,
                          itemBuilder: (context, index) {
                            final session = filteredSessions[index];
                            DateTime createdAt;
                            try {
                              createdAt = DateTime.parse(
                                  session['created_at'] ??
                                      DateTime.now().toIso8601String());
                            } catch (_) {
                              createdAt = DateTime.now();
                            }
                            final sessionId = session['id'];
                            final sessionName = session['name'];
                            final lastMsg = session['last_message'] ?? '';

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              child: ListTile(
                                tileColor: sessionId == currentSessionId
                                    ? Colors.deepPurple.withOpacity(0.12)
                                    : null,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
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
                                      lastMsg.length > 40
                                          ? "${lastMsg.substring(0, 40)}..."
                                          : lastMsg,
                                      style: TextStyle(
                                          fontSize: 12, color: text.withOpacity(0.7)),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      DateFormat('MMM dd, yyyy – hh:mm a')
                                          .format(createdAt),
                                      style: TextStyle(
                                          fontSize: 11, color: text.withOpacity(0.5)),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_forever,
                                      color: Colors.red, size: 20),
                                  onPressed: () => deleteSession(sessionId),
                                ),
                                onTap: () => openSession(sessionId),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

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

                      final msg = messages[messages.length -
                          1 -
                          (_isLoading ? index - 1 : index)];
                      final isUser = msg["sender"] == "user";

                      return Align(
                        alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width *
                                (isSidebarOpen ? 0.55 : 0.75),
                          ),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? Colors.deepPurple
                                  : _getAIBubbleColor(msg['text'] ?? ''),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isUser ? 16 : 0),
                                bottomRight: Radius.circular(isUser ? 0 : 16),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg["text"] ?? "",
                                  style: TextStyle(
                                      color: isUser
                                          ? Colors.white
                                          : widget.isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                      fontSize: 16),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  msg["time"] != null ? formatTime(msg["time"]!) : "",
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: isUser
                                          ? Colors.white70
                                          : widget.isDarkMode
                                          ? Colors.white60
                                          : Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
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
                                ? Colors.deepPurple.withOpacity(0.12)
                                : Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.deepPurple,
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: _isLoading ? null : _sendMessage,
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
    widget.isDarkMode ? Colors.grey[850] : Colors.deepPurple.shade50;
    final textColor = widget.isDarkMode ? Colors.white : Colors.black87;

    return Align(
      alignment: Alignment.centerLeft,
      child: AnimatedBuilder(
        animation: _dotAnimation,
        builder: (context, child) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
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
