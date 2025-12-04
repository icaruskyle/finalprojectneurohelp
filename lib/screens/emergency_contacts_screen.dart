import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'theme_notifier.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  final List<TextEditingController> _numberControllers = [];

  @override
  void dispose() {
    _nameController.dispose();
    for (var c in _numberControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callNumber(String number) async {
    final Uri uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showContactDialog({
    String? contactId,
    String? initialName,
    List<String>? initialNumbers,
  }) {
    _nameController.text = initialName ?? '';
    _numberControllers.clear();

    if (initialNumbers != null && initialNumbers.isNotEmpty) {
      for (var num in initialNumbers) {
        _numberControllers.add(TextEditingController(text: num));
      }
    } else {
      _numberControllers.add(TextEditingController());
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateSB) => AlertDialog(
          title: Text(contactId == null ? "Add Emergency Contact" : "Edit Emergency Contact"),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Name"),
                ),
                const SizedBox(height: 10),

                ..._numberControllers.asMap().entries.map((entry) {
                  int idx = entry.key;
                  TextEditingController controller = entry.value;
                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(labelText: "Number ${idx + 1}"),
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () {
                          if (_numberControllers.length > 1) {
                            setStateSB(() {
                              _numberControllers.removeAt(idx);
                            });
                          }
                        },
                      )
                    ],
                  );
                }),

                TextButton.icon(
                  onPressed: () {
                    setStateSB(() {
                      _numberControllers.add(TextEditingController());
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("Add another number"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final user = _auth.currentUser;
                if (user != null &&
                    _nameController.text.isNotEmpty &&
                    _numberControllers.any((c) => c.text.isNotEmpty)) {
                  List<String> numbers = _numberControllers
                      .where((c) => c.text.trim().isNotEmpty)
                      .map((c) => c.text.trim())
                      .toList();

                  if (contactId == null) {
                    await _firestore
                        .collection('users')
                        .doc(user.uid)
                        .collection('emergency_contacts')
                        .add({
                      'title': _nameController.text.trim(),
                      'numbers': numbers,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                  } else {
                    await _firestore
                        .collection('users')
                        .doc(user.uid)
                        .collection('emergency_contacts')
                        .doc(contactId)
                        .update({
                      'title': _nameController.text.trim(),
                      'numbers': numbers,
                    });
                  }
                }

                _nameController.clear();
                _numberControllers.clear();
                Navigator.pop(context);
              },
              child: Text(contactId == null ? "Add" : "Save"),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteContact(String contactId) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('emergency_contacts')
          .doc(contactId)
          .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeNotifier>(context).isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency Contacts / Helplines"),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showContactDialog(),
          ),
        ],
      ),

      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: isDarkMode ? Colors.black : Colors.white,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildHotlineCard(
                  title: "HOPELINE",
                  numbers: [
                    "(02) 804-4673 (Landline)",
                    "0917-558-4673 (Globe)",
                    "0918-873-4673 (Smart)"
                  ],
                  description: "24/7 free confidential support.",
                  link: "https://www.facebook.com/HopelinePH",
                ),
                const SizedBox(height: 16),

                _buildHotlineCard(
                  title: "In Touch: Crisis Line",
                  numbers: [
                    "(02) 893-7603",
                    "0919-056-0709",
                    "0917-800-1123",
                    "0922-893-8944"
                  ],
                  link: "https://www.facebook.com/InTouchCrisisLine",
                ),
                const SizedBox(height: 16),

                _buildHotlineCard(
                  title: "NCMH Crisis Hotline",
                  numbers: ["1553", "0917-899-8727", "0908-639-2672"],
                  description: "Connects you to a volunteer.",
                  link: "https://www.facebook.com/NCMHCrisisLine",
                ),
                const SizedBox(height: 16),

                _buildHotlineCard(
                  title: "MentalHealthPH",
                  numbers: ["1553", "7-989-8727", "0917-899-8727"],
                  link: "https://www.facebook.com/mentalhealthph",
                ),
                const SizedBox(height: 16),

                // 🟣 REAL-TIME USER CONTACTS USING STREAMBUILDER
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('users')
                      .doc(_auth.currentUser!.uid)
                      .collection('emergency_contacts')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox();
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const SizedBox();
                    }

                    final docs = snapshot.data!.docs;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        const Text(
                          "Your Contacts",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple),
                        ),
                        const SizedBox(height: 10),

                        ...docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;

                          return Column(
                            children: [
                              _buildHotlineCard(
                                title: data['title'],
                                numbers: List<String>.from(data['numbers']),
                                showEditDelete: true,
                                onEdit: () => _showContactDialog(
                                  contactId: doc.id,
                                  initialName: data['title'],
                                  initialNumbers: List<String>.from(data['numbers']),
                                ),
                                onDelete: () => _deleteContact(doc.id),
                              ),
                              const SizedBox(height: 16),
                            ],
                          );
                        }).toList(),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // CARD WIDGET
  Widget _buildHotlineCard({
    required String title,
    required List<String> numbers,
    String? description,
    String? link,
    bool showEditDelete = false,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFE3F2FD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(2, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ),

              if (showEditDelete) ...[
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ],
          ),

          const SizedBox(height: 8),

          ...numbers.map((number) => Row(
            children: [
              const Icon(Icons.phone, color: Colors.deepPurple),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => _callNumber(number),
                  child: Text(
                    number,
                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                  ),
                ),
              ),
            ],
          )),

          if (description != null) ...[
            const SizedBox(height: 10),
            Text(description!, style: const TextStyle(fontSize: 12)),
          ],

          if (link != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _launchURL(link!),
              child: const Text(
                "View on Facebook",
                style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
