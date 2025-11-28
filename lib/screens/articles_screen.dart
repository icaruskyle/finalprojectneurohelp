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

  /// DEFAULT ARTICLES (Static)
  final List<Map<String, String>> _defaultArticles = [
    {
      'title': 'World Mental Health Day 2025',
      'description': 'Celebrated every October 10, raising awareness on mental health.',
      'link': 'https://www.who.int/campaigns/world-mental-health-day',
      'category': 'Events'
    },
    {
      'title': 'National Suicide Prevention Awareness Month',
      'description': 'Every September, organizations promote suicide prevention.',
      'link': 'https://afsp.org/national-suicide-prevention-week',
      'category': 'Events'
    },
    {
      'title': 'Mindful Monday: Meditation for Beginners',
      'description': 'A practical guide to meditation for managing stress.',
      'link': 'https://www.mindful.org/how-to-meditate/',
      'category': 'Self-Care'
    },
    {
      'title': 'Self-Care Tips for Students',
      'description': 'Balance school and life while protecting your mental health.',
      'link': 'https://www.mentalhealth.org.uk/explore-mental-health/publications/student-guide',
      'category': 'Guides'
    },
    {
      'title': 'Coping with Anxiety and Depression',
      'description': 'Learn symptoms and coping strategies for depression and anxiety.',
      'link': 'https://www.nimh.nih.gov/health/topics/depression',
      'category': 'Guides'
    },
    {
      'title': 'The Power of Talking About Mental Health',
      'description': 'Open conversations reduce stigma and support healing.',
      'link': 'https://www.time-to-change.org.uk/blog/why-talking-about-mental-health-important',
      'category': 'Awareness'
    },
    {
      'title': 'How Music Improves Mental Health',
      'description': 'Music boosts mood, reduces stress, and improves concentration.',
      'link': 'https://psychcentral.com/health/how-music-helps-improve-your-mental-health',
      'category': 'Self-Care'
    },
    {
      'title': 'Youth Mental Health Summit 2025',
      'description': 'Empowering youth to discuss global mental health innovations.',
      'link': 'https://www.unicef.org/mental-health',
      'category': 'Events'
    },
  ];

  final Map<String, Color> _categoryColors = {
    'Events': Colors.teal,
    'Self-Care': Colors.blue,
    'Guides': Colors.orange,
    'Awareness': Colors.pinkAccent,
    'All': Colors.deepPurple
  };

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  // 🔥 Fetch admin-created articles from Firebase
  Stream<List<Map<String, dynamic>>> _getAdminArticles() {
    return FirebaseFirestore.instance
        .collection("articles")
        .orderBy("timestamp", descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text("🧠 Mental Health Articles",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
      ),

      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getAdminArticles(),
        builder: (context, snapshot) {
          final adminArticles = snapshot.data ?? [];

          /// Combine default + admin articles
          final combinedArticles = [
            ..._defaultArticles,
            ...adminArticles.map((a) => {
              "title": a["title"],
              "description": a["description"],
              "link": a["link"],
              "category": a["category"],
            })
          ];

          /// Apply search & category filter
          final filteredArticles = combinedArticles.where((article) {
            final matchesCategory = _selectedCategory == 'All' ||
                article['category'] == _selectedCategory;

            final matchesSearch = article['title']!
                .toLowerCase()
                .contains(_searchController.text.toLowerCase());

            return matchesCategory && matchesSearch;
          }).toList();

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search,
                        color: isDark ? Colors.white : Colors.deepPurple),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        })
                        : null,
                    hintText: "Search articles or events...",
                    filled: true,
                    fillColor:
                    isDark ? Colors.grey[800] : Colors.deepPurple.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),

              // Category Filter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: "Filter by Category",
                    prefixIcon: Icon(Icons.filter_list,
                        color: isDark ? Colors.white : Colors.deepPurple),
                    filled: true,
                    fillColor:
                    isDark ? Colors.grey[800] : Colors.deepPurple.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  items: _categoryColors.keys
                      .map((cat) =>
                      DropdownMenuItem(value: cat, child: Text(cat)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedCategory = value!),
                ),
              ),

              const SizedBox(height: 10),

              // Article List
              Expanded(
                child: filteredArticles.isEmpty
                    ? Center(
                  child: Text(
                    "No articles found.",
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark
                          ? Colors.white70
                          : Colors.grey[700],
                    ),
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  itemCount: filteredArticles.length,
                  itemBuilder: (context, index) {
                    final item = filteredArticles[index];
                    final catColor =
                        _categoryColors[item['category']] ??
                            Colors.deepPurple;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                            Colors.grey[850]!,
                            Colors.grey[900]!
                          ]
                              : [
                            catColor.withOpacity(0.2),
                            Colors.white
                          ],
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        title: Text(
                          item['title']!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: isDark ? Colors.white : catColor,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            item['description']!,
                            style: TextStyle(
                              fontSize: 15,
                              color: isDark
                                  ? Colors.white60
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.open_in_new, color: catColor),
                          onPressed: () => _launchURL(item['link']!),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
