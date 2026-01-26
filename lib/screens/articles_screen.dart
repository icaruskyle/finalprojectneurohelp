import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class ArticlesScreen extends StatefulWidget {
  final bool isDarkMode;
  const ArticlesScreen({super.key, required this.isDarkMode});

  @override
  State<ArticlesScreen> createState() => _ArticlesScreenState();
}

class _ArticlesScreenState extends State<ArticlesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final Map<String, Color> _categoryColors = {
    'Events': Colors.teal,
    'Self-Care': Colors.blue,
    'Guides': Colors.orange,
    'Awareness': Colors.pinkAccent,
    'All': Colors.deepPurple,
  };

  Future<void> _launchURL(String url) async {
    if (url.trim().isEmpty) return;
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open link")),
      );
    }
  }

  Stream<List<Map<String, dynamic>>> _getAdminArticles() {
    return FirebaseFirestore.instance
        .collection("articles")
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text("🧠 Articles"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: "Search articles...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor:
                isDark ? Colors.grey[800] : Colors.deepPurple.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),


          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: "Category",
                filled: true,
                fillColor:
                isDark ? Colors.grey[800] : Colors.deepPurple.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              items: _categoryColors.keys
                  .map((cat) =>
                  DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedCategory = value!);
              },
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _getAdminArticles(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No articles available"));
                }

                final articles = snapshot.data!;

                final filteredArticles = articles.where((article) {
                  final matchesCategory = _selectedCategory == 'All' ||
                      article['category'] == _selectedCategory;

                  final matchesSearch = article['title']
                      .toString()
                      .toLowerCase()
                      .contains(_searchController.text.toLowerCase());

                  return matchesCategory && matchesSearch;
                }).toList();

                if (filteredArticles.isEmpty) {
                  return const Center(child: Text("No matching articles"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredArticles.length,
                  itemBuilder: (context, index) {
                    final item = filteredArticles[index];
                    final color =
                        _categoryColors[item['category']] ??
                            Colors.deepPurple;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        title: Text(
                          item['title'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        subtitle: Text(item['description']),
                        trailing: IconButton(
                          icon: Icon(Icons.open_in_new, color: color),
                          onPressed: () => _launchURL(item['link']),
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
    );
  }
}
