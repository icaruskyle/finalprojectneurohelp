// gratitude_feature.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Wellness-style Gratitude screen with 3-item input + history page.
/// Copy this file into your project and add routing to GratitudeHistoryScreen.
class GratitudeScreen extends StatefulWidget {
  const GratitudeScreen({super.key});

  @override
  State<GratitudeScreen> createState() => _GratitudeScreenState();
}

class _GratitudeScreenState extends State<GratitudeScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final TextEditingController _c1 = TextEditingController();
  final TextEditingController _c2 = TextEditingController();
  final TextEditingController _c3 = TextEditingController();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // rotating prompts
  final List<String> _prompts = [
    "What made you smile today?",
    "Who helped you this week?",
    "What's one thing you're proud of?",
    "What small thing brightened your day?",
    "What's a kindness you received?",
    "What skill or strength helped you today?",
    "What moment made you feel calm?",
    "What made today easier than yesterday?"
  ];
  final Random _rnd = Random();

  String _prompt1 = "";
  String _prompt2 = "";
  String _prompt3 = "";

  bool _isSaving = false;
  String uid = "";

  @override
  void initState() {
    super.initState();
    _setRandomPrompts();
    final user = _auth.currentUser;
    if (user != null) uid = user.uid;
    _initNotifications();
  }

  void _setRandomPrompts() {
    // choose 3 different prompts
    final copy = List<String>.from(_prompts);
    copy.shuffle(_rnd);
    setState(() {
      _prompt1 = copy.removeAt(0);
      _prompt2 = copy.removeAt(0);
      _prompt3 = copy.removeAt(0);
    });
  }

  // ---------- Local Notifications ----------
  void _initNotifications() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Manila'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(settings);

    _scheduleDailyReminder();
  }

  void _scheduleDailyReminder() async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 20, 0); // 8 PM

    final nextScheduled = scheduled.isAfter(now)
        ? scheduled
        : scheduled.add(const Duration(days: 1));

    await _notificationsPlugin.zonedSchedule(
      0,
      "Don't forget your gratitudes 💜",
      "List 3 things you're grateful for today.",
      nextScheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'gratitude_channel',
          'Daily Gratitude',
          channelDescription: 'Daily reminder to write gratitude',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }


  // ---------- Save all three as one entry ----------
  Future<void> _saveAll() async {
    final a = _c1.text.trim();
    final b = _c2.text.trim();
    final c = _c3.text.trim();

    if (a.isEmpty && b.isEmpty && c.isEmpty) {
      _showTopNotification("Write at least one gratitude to save.", isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final docRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('gratitude_entries');

      await docRef.add({
        'item1': a,
        'item2': b,
        'item3': c,
        'starred': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // clear inputs and rotate prompts
      _c1.clear();
      _c2.clear();
      _c3.clear();
      _setRandomPrompts();

      _showTopNotification("✅ Gratitude saved. Nice one!");
    } catch (e) {
      _showTopNotification("Could not save. Try again.", isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ---------- Helper: top overlay notification ----------
  void _showTopNotification(String message, {bool isError = false}) {
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 48,
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
              style: const TextStyle(color: Colors.white, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2)).then((_) => overlayEntry.remove());
  }

  // ---------- Navigate to History ----------
  void _openHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (ctx) => GratitudeHistoryScreen(uid: uid)),
    );
  }

  @override
  void dispose() {
    _c1.dispose();
    _c2.dispose();
    _c3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gratitude"),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            tooltip: "View history",
            onPressed: _openHistory,
            icon: const Icon(Icons.history),
          )
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
            colors: [Color(0xFF1C1C3A), Color(0xFF1C1C2A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : const LinearGradient(
            colors: [Color(0xFF7E57C2), Color(0xFFB388FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // header card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
                        blurRadius: 12,
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        "3 Things You're Grateful For",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.deepPurple.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Write three short items — small things count.",
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _setRandomPrompts,
                              icon: const Icon(Icons.lightbulb),
                              label: const Text("Need ideas?"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.deepPurple,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // inputs (soft cards)
                _buildInputCard(_c1, _prompt1, isDark),
                const SizedBox(height: 12),
                _buildInputCard(_c2, _prompt2, isDark),
                const SizedBox(height: 12),
                _buildInputCard(_c3, _prompt3, isDark),

                const SizedBox(height: 18),

                // save button
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveAll,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Text(
                          "Save All",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // quick tips / small CTA
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Quick prompts",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _prompts.take(5).map((p) {
                    return ActionChip(
                      label: Text(
                        p,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      onPressed: () {
                        // paste into first empty field
                        if (_c1.text.isEmpty) {
                          _c1.text = p;
                        } else if (_c2.text.isEmpty) {
                          _c2.text = p;
                        } else {
                          _c3.text = p;
                        }
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 30),

                // history preview header
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Recent Entries",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton(
                      onPressed: _openHistory,
                      child: const Text(
                        "View all",
                        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),

                // small preview list (3 latest)
                SizedBox(
                  height: 260,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('users')
                        .doc(uid)
                        .collection('gratitude_entries')
                        .orderBy('timestamp', descending: true)
                        .limit(3)
                        .snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = snap.data!.docs;
                      if (docs.isEmpty) {
                        return Center(
                          child: Text(
                            "No entries yet. Start with a small moment.",
                            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                          ),
                        );
                      }
                      return ListView.separated(
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final item1 = data['item1'] ?? '';
                          final item2 = data['item2'] ?? '';
                          final item3 = data['item3'] ?? '';
                          final starred = data['starred'] ?? false;
                          final ts = data['timestamp'] as Timestamp?;
                          final date = ts != null ? ts.toDate() : DateTime.now();
                          return _buildHistoryPreviewCard(
                              doc.id, item1, item2, item3, starred, date, isDark);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // small input card widget
  Widget _buildInputCard(TextEditingController c, String prompt, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.25 : 0.08), blurRadius: 8)
        ],
      ),
      child: TextField(
        controller: c,
        maxLines: 2,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          hintText: prompt,
          hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildHistoryPreviewCard(String id, String i1, String i2, String i3, bool starred,
      DateTime date, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                "${date.day}/${date.month}/${date.year}",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Text("• $i1", style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
              Text("• $i2", style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
              Text("• $i3", style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
            ]),
          ),
          IconButton(
            icon: Icon(starred ? Icons.star : Icons.star_border,
                color: starred ? Colors.amber : (isDark ? Colors.white :Colors.deepPurple)),
            onPressed: () => _toggleStarPreview(id, !starred),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleStarPreview(String id, bool newVal) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('gratitude_entries')
        .doc(id)
        .update({'starred': newVal});
  }
}

/// Separate History Screen (full list + edit/delete/star)
class GratitudeHistoryScreen extends StatelessWidget {
  final String uid;
  const GratitudeHistoryScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gratitude History"),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('users')
            .doc(uid)
            .collection('gratitude_entries')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Text(
                "No gratitude entries yet.",
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return _HistoryCard(
                id: doc.id,
                uid: uid,
                item1: data['item1'] ?? '',
                item2: data['item2'] ?? '',
                item3: data['item3'] ?? '',
                starred: data['starred'] ?? false,
                timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
              );
            },
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatefulWidget {
  final String id;
  final String uid;
  final String item1;
  final String item2;
  final String item3;
  final bool starred;
  final DateTime timestamp;

  const _HistoryCard({
    required this.id,
    required this.uid,
    required this.item1,
    required this.item2,
    required this.item3,
    required this.starred,
    required this.timestamp,
  });

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard> {
  bool _editing = false;
  late TextEditingController _c1;
  late TextEditingController _c2;
  late TextEditingController _c3;
  bool _starred = false;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _c1 = TextEditingController(text: widget.item1);
    _c2 = TextEditingController(text: widget.item2);
    _c3 = TextEditingController(text: widget.item3);
    _starred = widget.starred;
  }

  @override
  void dispose() {
    _c1.dispose();
    _c2.dispose();
    _c3.dispose();
    super.dispose();
  }

  Future<void> _saveEdits() async {
    await _firestore
        .collection('users')
        .doc(widget.uid)
        .collection('gratitude_entries')
        .doc(widget.id)
        .update({
      'item1': _c1.text.trim(),
      'item2': _c2.text.trim(),
      'item3': _c3.text.trim(),
    });
    setState(() => _editing = false);
    _showTop("Saved");
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete entry?"),
        content: const Text("This will permanently delete this gratitude entry."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete")),
        ],
      ),
    );
    if (confirmed ?? false) {
      await _firestore
          .collection('users')
          .doc(widget.uid)
          .collection('gratitude_entries')
          .doc(widget.id)
          .delete();
      _showTop("Deleted");
    }
  }

  Future<void> _toggleStar() async {
    _starred = !_starred;
    await _firestore
        .collection('users')
        .doc(widget.uid)
        .collection('gratitude_entries')
        .doc(widget.id)
        .update({'starred': _starred});
    setState(() {});
  }

  void _showTop(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark; // <-- add this
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 48,
        left: 20,
        right: 20,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(12),
          color: isDark ? Colors.deepPurple[400] : Colors.deepPurple.shade300,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              text,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.deepPurple.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2)).then((_) => entry.remove());
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header with date + star + edit/delete
          Row(
            children: [
              Expanded(
                child: Text(
                  "${widget.timestamp.day}/${widget.timestamp.month}/${widget.timestamp.year}",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              IconButton(
                icon: Icon(_starred ? Icons.star : Icons.star_border, color: _starred ? Colors.amber : (isDark ? Colors.white :Colors.deepPurple)),
                onPressed: _toggleStar,
              ),
              IconButton(
                icon: Icon(Icons.edit, color: isDark ? Colors.white : Colors.deepPurple),
                onPressed: () => setState(() => _editing = !_editing),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: _delete,
              ),
            ],
          ),
          const SizedBox(height: 6),

          if (_editing) ...[
            TextField(controller: _c1, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 6),
            TextField(controller: _c2, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 6),
            TextField(controller: _c3, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 8),
            Row(children: [
              ElevatedButton(onPressed: _saveEdits, child: const Text("Save")),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => setState(() => _editing = false),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                child: const Text("Cancel"),
              ),
            ])
          ] else ...[
            Text("• ${widget.item1}", style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
            Text("• ${widget.item2}", style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
            Text("• ${widget.item3}", style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
          ],
        ],
      ),
    );
  }
}
