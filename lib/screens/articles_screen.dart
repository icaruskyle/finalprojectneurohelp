import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ArticlesScreen extends StatefulWidget {
  const ArticlesScreen({super.key});

  @override
  State<ArticlesScreen> createState() => _ArticlesScreenState();
}

class _ArticlesScreenState extends State<ArticlesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final List<Map<String, String>> _articles = [
    {
      'title': 'World Mental Health Day 2025',
      'description':
      'Celebrated every October 10, this event raises awareness about mental health and encourages open discussion on emotional well-being.',
      'link': 'https://www.who.int/campaigns/world-mental-health-day',
      'category': 'Events'
    },
    {
      'title': 'National Suicide Prevention Awareness Month',
      'description':
      'Every September, advocates and organizations promote awareness and support for suicide prevention.',
      'link': 'https://afsp.org/national-suicide-prevention-week',
      'category': 'Events'
    },
    {
      'title': 'Mindful Monday: Meditation for Beginners',
      'description':
      'A practical guide to starting meditation to manage stress, anxiety, and emotional overwhelm.',
      'link': 'https://www.mindful.org/how-to-meditate/',
      'category': 'Self-Care'
    },
    {
      'title': 'Self-Care Tips for Students',
      'description':
      'Learn how to balance school, work, and personal life while maintaining your mental health.',
      'link': 'https://www.mentalhealth.org.uk/explore-mental-health/publications/student-guide',
      'category': 'Guides'
    },
    {
      'title': 'Coping with Anxiety and Depression',
      'description':
      'Understand symptoms and explore coping strategies and support networks for managing depression and anxiety.',
      'link': 'https://www.nimh.nih.gov/health/topics/depression',
      'category': 'Guides'
    },
    {
      'title': 'The Power of Talking About Mental Health',
      'description':
      'How open conversations can reduce stigma and support healing in communities.',
      'link':
      'https://www.time-to-change.org.uk/blog/why-talking-about-mental-health-important',
      'category': 'Awareness'
    },
    {
      'title': 'How Music Improves Mental Health',
      'description':
      'Learn how music boosts mood, reduces stress, and improves concentration.',
      'link':
      'https://psychcentral.com/health/how-music-helps-improve-your-mental-health',
      'category': 'Self-Care'
    },
    {
      'title': 'Youth Mental Health Summit 2025',
      'description':
      'An annual global event empowering youth advocates to discuss innovation in mental health and digital well-being.',
      'link': 'https://www.unicef.org/mental-health',
      'category': 'Events'
    },
  ];

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Apply search + category filters
    final filteredArticles = _articles.where((article) {
      final matchesCategory =
          _selectedCategory == 'All' || article['category'] == _selectedCategory;
      final matchesSearch = article['title']!
          .toLowerCase()
          .contains(_searchController.text.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "🧠 Mental Health Articles",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          // 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                hintText: "Search articles or events...",
                filled: true,
                fillColor: Colors.deepPurple.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // 🎯 Category Filter Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: "Filter by Category",
                prefixIcon:
                const Icon(Icons.filter_list, color: Colors.deepPurple),
                filled: true,
                fillColor: Colors.deepPurple.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All')),
                DropdownMenuItem(value: 'Events', child: Text('Events')),
                DropdownMenuItem(value: 'Self-Care', child: Text('Self-Care')),
                DropdownMenuItem(value: 'Guides', child: Text('Guides')),
                DropdownMenuItem(value: 'Awareness', child: Text('Awareness')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
          ),

          const SizedBox(height: 10),

          // 📰 Article List
          Expanded(
            child: filteredArticles.isEmpty
                ? const Center(
              child: Text(
                "No articles found.",
                style:
                TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              itemCount: filteredArticles.length,
              itemBuilder: (context, index) {
                final item = filteredArticles[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    title: Text(
                      item['title']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.deepPurple,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        item['description']!,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.open_in_new,
                          color: Colors.deepPurple),
                      onPressed: () => _launchURL(item['link']!),
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
