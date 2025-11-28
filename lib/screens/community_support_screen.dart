import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommunitySupportScreen extends StatefulWidget {
  final bool isDarkMode;
  const CommunitySupportScreen({super.key, required this.isDarkMode});

  @override
  State<CommunitySupportScreen> createState() => _CommunitySupportScreenState();
}

class _CommunitySupportScreenState extends State<CommunitySupportScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  List<Map<String, dynamic>> _supportGroups = [];

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  /// 🔥 LOAD DATA FROM FIREBASE
  Future<void> _loadGroups() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('support_groups')
        .get();

    setState(() {
      _supportGroups = snapshot.docs.map((doc) {
        return {
          "id": doc.id,
          "name": doc["name"],
          "description": doc["description"],
          "link": doc["link"],
          "category": doc["category"],
        };
      }).toList();
    });
  }

  /// 🔥 ADD NEW GROUP
  Future<void> _addGroup() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final linkController = TextEditingController();
    String category = "Organizations";

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Add Support Group"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name")),
                TextField(controller: descriptionController, decoration: const InputDecoration(labelText: "Description")),
                TextField(controller: linkController, decoration: const InputDecoration(labelText: "Link")),
                DropdownButton<String>(
                  value: category,
                  items: const [
                    DropdownMenuItem(value: "Online Support", child: Text("Online Support")),
                    DropdownMenuItem(value: "Organizations", child: Text("Organizations")),
                    DropdownMenuItem(value: "Community Forums", child: Text("Community Forums")),
                    DropdownMenuItem(value: "Youth Support", child: Text("Youth Support")),
                    DropdownMenuItem(value: "Hotlines", child: Text("Hotlines")),
                  ],
                  onChanged: (value) => category = value!,
                )
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            TextButton(
                onPressed: () async {
                  await FirebaseFirestore.instance.collection('support_groups').add({
                    "name": nameController.text,
                    "description": descriptionController.text,
                    "link": linkController.text,
                    "category": category,
                  });
                  Navigator.pop(context);
                  _loadGroups();
                },
                child: const Text("Add")),
          ],
        );
      },
    );
  }

  /// 🔥 EDIT GROUP
  Future<void> _editGroup(Map<String, dynamic> group) async {
    final nameController = TextEditingController(text: group["name"]);
    final descriptionController = TextEditingController(text: group["description"]);
    final linkController = TextEditingController(text: group["link"]);
    String category = group["category"];

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Edit Support Group"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name")),
                TextField(controller: descriptionController, decoration: const InputDecoration(labelText: "Description")),
                TextField(controller: linkController, decoration: const InputDecoration(labelText: "Link")),
                DropdownButton<String>(
                  value: category,
                  items: const [
                    DropdownMenuItem(value: "Online Support", child: Text("Online Support")),
                    DropdownMenuItem(value: "Organizations", child: Text("Organizations")),
                    DropdownMenuItem(value: "Community Forums", child: Text("Community Forums")),
                    DropdownMenuItem(value: "Youth Support", child: Text("Youth Support")),
                    DropdownMenuItem(value: "Hotlines", child: Text("Hotlines")),
                  ],
                  onChanged: (value) => category = value!,
                )
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            TextButton(
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('support_groups')
                      .doc(group["id"])
                      .update({
                    "name": nameController.text,
                    "description": descriptionController.text,
                    "link": linkController.text,
                    "category": category,
                  });

                  Navigator.pop(context);
                  _loadGroups();
                },
                child: const Text("Save")),
          ],
        );
      },
    );
  }

  /// 🔥 DELETE GROUP
  Future<void> _deleteGroup(String id) async {
    await FirebaseFirestore.instance.collection("support_groups").doc(id).delete();
    _loadGroups();
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;

    final filteredGroups = _supportGroups.where((group) {
      final matchesCategory =
          _selectedCategory == 'All' || group['category'] == _selectedCategory;
      final matchesSearch = group['name']
          .toLowerCase()
          .contains(_searchController.text.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "🤝 Community Support",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addGroup,
          )
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search,
                    color: isDark ? Colors.white : Colors.deepPurple),
                hintText: "Search support groups...",
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.deepPurple.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: "Filter by Category",
                prefixIcon: Icon(Icons.filter_list,
                    color: isDark ? Colors.white : Colors.deepPurple),
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.deepPurple.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All')),
                DropdownMenuItem(value: 'Online Support', child: Text('Online Support')),
                DropdownMenuItem(value: 'Organizations', child: Text('Organizations')),
                DropdownMenuItem(value: 'Community Forums', child: Text('Community Forums')),
                DropdownMenuItem(value: 'Youth Support', child: Text('Youth Support')),
                DropdownMenuItem(value: 'Hotlines', child: Text('Hotlines')),
              ],
              onChanged: (value) => setState(() => _selectedCategory = value!),
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: filteredGroups.isEmpty
                ? Center(
              child: Text(
                "No community support groups found.",
                style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white70 : Colors.grey),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: filteredGroups.length,
              itemBuilder: (context, index) {
                final item = filteredGroups[index];

                return Card(
                  color: isDark ? Colors.grey[850] : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Icon(Icons.groups,
                        color:
                        isDark ? Colors.purpleAccent : Colors.deepPurple,
                        size: 30),
                    title: Text(
                      item['name'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isDark ? Colors.white : Colors.deepPurple,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        item['description'],
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),

                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                            icon: Icon(Icons.open_in_new,
                                color: isDark
                                    ? Colors.purpleAccent
                                    : Colors.deepPurple),
                            onPressed: () => _launchURL(item['link'])),
                        IconButton(
                            icon: Icon(Icons.edit,
                                color: isDark
                                    ? Colors.blueAccent
                                    : Colors.blue),
                            onPressed: () => _editGroup(item)),
                        IconButton(
                            icon: Icon(Icons.delete,
                                color: Colors.redAccent),
                            onPressed: () => _deleteGroup(item['id'])),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
