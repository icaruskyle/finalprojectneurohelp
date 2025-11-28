import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _userContacts = [];

  final TextEditingController _nameController = TextEditingController();
  final List<TextEditingController> _numberControllers = [];

  @override
  void initState() {
    super.initState();
    _loadUserContacts();
  }

  Future<void> _loadUserContacts() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('emergency_contacts')
        .orderBy('createdAt', descending: true)
        .get();

    setState(() {
      _userContacts = snapshot.docs
          .map((doc) => {
        'id': doc.id,
        'title': doc['title'],
        'numbers': List<String>.from(doc['numbers'])
      })
          .toList();
    });
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _callNumber(String number) async {
    final Uri uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not call $number';
    }
  }

  void _showContactDialog({String? contactId, String? initialName, List<String>? initialNumbers}) {
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
        builder: (context, setState) => AlertDialog(
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
                ..._numberControllers.asMap().entries.map(
                      (entry) {
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
                              setState(() {
                                _numberControllers.removeAt(idx);
                              });
                            }
                          },
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 5),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
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
                    final docRef = await _firestore
                        .collection('users')
                        .doc(user.uid)
                        .collection('emergency_contacts')
                        .add({
                      'title': _nameController.text.trim(),
                      'numbers': numbers,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    setState(() {
                      _userContacts.insert(0, {
                        'id': docRef.id,
                        'title': _nameController.text.trim(),
                        'numbers': numbers,
                      });
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
                    setState(() {
                      final index = _userContacts.indexWhere((c) => c['id'] == contactId);
                      if (index != -1) {
                        _userContacts[index]['title'] = _nameController.text.trim();
                        _userContacts[index]['numbers'] = numbers;
                      }
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
      setState(() {
        _userContacts.removeWhere((c) => c['id'] == contactId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency Contacts/Helplines"),
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
        color: Colors.white,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // --- Preset Hotlines ---
                _buildHotlineCard(
                  title: "HOPELINE",
                  numbers: [
                    "(02) 804-4673 (Landline)",
                    "0917-558-4673 (Globe)",
                    "0918-873-4673 (Smart)",
                  ],
                  description: "24/7 free confidential support over the phone.",
                  link: "https://www.facebook.com/HopelinePH",
                ),
                const SizedBox(height: 16),
                _buildHotlineCard(
                  title: "In Touch: Crisis Line",
                  numbers: [
                    "(02) 893-7603 (Landline)",
                    "0919-056-0709 (Smart)",
                    "0917-800-1123 (Globe)",
                    "0922-893-8944 (Smart)",
                  ],
                  link: "https://www.facebook.com/InTouchCrisisLine",
                ),
                const SizedBox(height: 16),
                _buildHotlineCard(
                  title: "NCMH Crisis Hotline",
                  numbers: [
                    "(02) 1553 (Luzon landline)",
                    "0917-899-8727 (Globe)",
                    "0908-639-2672 (Smart)",
                  ],
                  description:
                  "Automated system asks for language selection and connects you to a volunteer.",
                  link: "https://www.facebook.com/NCMHCrisisLine",
                ),
                const SizedBox(height: 16),
                _buildHotlineCard(
                  title: "MentalHealth PH",
                  numbers: ["(02) 1553", "(02) 7-989-8727", "0917-899-8727"],
                  description:
                  "MentalHealthPH provides support and guidance for mental health concerns.",
                  link: "https://www.facebook.com/mentalhealthph",
                ),
                const SizedBox(height: 16),
                _buildHotlineCard(
                  title: "Bantay Bata Helpline 163",
                  numbers: ["(02) 163 (Landline)"],
                  description:
                  "Child protection and domestic violence concerns.",
                  link: "https://www.abs-cbnfoundation.com/bantaybata163",
                ),
                const SizedBox(height: 16),
                _buildHotlineCard(
                  title: "Philippine Red Cross Hotline",
                  numbers: ["143 (Emergency)", "(02) 8790-2300"],
                  description:
                  "For first aid, blood donation info, and disaster support.",
                  link: "https://www.redcross.org.ph",
                ),
                const SizedBox(height: 16),
                _buildHotlineCard(
                  title: "YouthLine Philippines",
                  numbers: ["0995-869-7637", "0917-885-3987"],
                  description:
                  "Support for youth experiencing stress, depression, or suicidal thoughts.",
                  link: "https://www.facebook.com/youthline.ph",
                ),
                const SizedBox(height: 16),
                _buildHotlineCard(
                  title: "Call Center ng Department of Health (DOH)",
                  numbers: ["1555", "(02) 8651-7800"],
                  description:
                  "For health-related inquiries and mental health referrals.",
                  link: "https://www.doh.gov.ph",
                ),
                const SizedBox(height: 16),

                // --- User-added contacts ---
                if (_userContacts.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Your Contacts",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._userContacts.map(
                            (contact) => Column(
                          children: [
                            _buildHotlineCard(
                              title: contact['title'],
                              numbers: List<String>.from(contact['numbers']),
                              showEditDelete: true,
                              onEdit: () => _showContactDialog(
                                  contactId: contact['id'],
                                  initialName: contact['title'],
                                  initialNumbers: List<String>.from(contact['numbers'])),
                              onDelete: () => _deleteContact(contact['id']),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(2, 2),
          ),
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
                  softWrap: true,
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
              ]
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
            Text(
              description,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
              softWrap: true,
            ),
          ],
          if (link != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _launchURL(link),
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
