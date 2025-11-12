import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'ai_service.dart';

class HeneuroTab extends StatefulWidget {
  final bool isDarkMode;
  const HeneuroTab({super.key, required this.isDarkMode});

  @override
  State<HeneuroTab> createState() => _HeneuroTabState();
}

class _HeneuroTabState extends State<HeneuroTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // 👈 Keeps the tab alive when switching

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ai = AIService();

  List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMessages(); // 🔄 Load saved chat history when tab opens
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('chat_history');
    if (saved != null) {
      setState(() {
        _messages = List<Map<String, String>>.from(json.decode(saved));
      });
    }
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_history', json.encode(_messages));
  }

  Future<void> _sendMessage() async {
    final userInput = _controller.text.trim();
    if (userInput.isEmpty) return;

    setState(() {
      _messages.add({"sender": "user", "text": userInput});
      _isLoading = true;
    });
    await _saveMessages();

    _controller.clear();

    final prompt = "You are Heneuro, a kind AI assistant. $userInput";
    final reply = await ai.getAIResponse(prompt);

    setState(() {
      _messages.add({"sender": "ai", "text": reply});
      _isLoading = false;
    });
    await _saveMessages();

    // Auto-scroll to the bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 👈 Required for AutomaticKeepAliveClientMixin

    final bg = widget.isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final text = widget.isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat with Heneuro 🤖"),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _messages.length,
                padding: const EdgeInsets.all(12),
                itemBuilder: (context, index) {
                  final msg = _messages[index];
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
                      child: Text(
                        msg["text"] ?? "",
                        style: TextStyle(
                          color: isUser ? Colors.white : text,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(color: Colors.deepPurple),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
    );
  }
}
