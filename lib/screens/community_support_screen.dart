import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class CommunitySupportScreen extends StatefulWidget {
  final bool isDarkMode;
  const CommunitySupportScreen({super.key, required this.isDarkMode});

  @override
  State<CommunitySupportScreen> createState() => _CommunitySupportScreenState();
}

class _CommunitySupportScreenState extends State<CommunitySupportScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _selectedCategories = ['All'];

  final List<String> _categories = [
    'All',
    'Online Support',
    'Organizations',
    'Community Forums',
    'Youth Support',
    'Hotlines'
  ];

  Future<void> _launchURL(String url) async {
    if (url.trim().isEmpty) return;

    if (!url.startsWith('http')) {
      url = 'https://$url';
    }

    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open link.")),
      );
    }
  }


  Widget _categoryChips(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: _categories.map((cat) {
          final isSelected = _selectedCategories.contains(cat);
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                cat,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
              selected: isSelected,
              selectedColor: Colors.deepPurple,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
              onSelected: (_) {
                setState(() {
                  if (cat == 'All') {
                    _selectedCategories = ['All'];
                  } else {
                    _selectedCategories.remove('All');
                    if (isSelected) {
                      _selectedCategories.remove(cat);
                    } else {
                      _selectedCategories.add(cat);
                    }
                    if (_selectedCategories.isEmpty) {
                      _selectedCategories = ['All'];
                    }
                  }
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // 🔹 CARD UI
  Widget _buildGroupCard(Map<String, dynamic> group, bool isDark) {
    final titleColor = isDark ? Colors.white : Colors.deepPurple;
    final descColor = isDark ? Colors.white70 : Colors.black87;
    final accent = isDark ? Colors.deepPurpleAccent : Colors.deepPurple;

    return Card(
      elevation: 3,
      color: isDark ? Colors.grey[850] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _launchURL(group['link'] ?? ''),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(Icons.groups, color: accent, size: 28),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group['name'] ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      group['description'] ?? '',
                      style: TextStyle(fontSize: 14, color: descColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        group['category'] ?? 'Other',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _launchURL(group['link'] ?? ''),
                child: Icon(Icons.open_in_new, color: accent),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text(
          '🤝 Community Support',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search,
                      color: isDark ? Colors.white70 : Colors.deepPurple),
                  hintText: 'Search groups...',
                  filled: true,
                  fillColor: isDark ? Colors.grey[850] : Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
            ),
            const SizedBox(height: 10),

            _categoryChips(isDark),
            const SizedBox(height: 8),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('communities')
                    .orderBy('title')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Center(child: Text("Something went wrong"));
                  }

                  final groups = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return {
                      'name': data['title'] ?? '',
                      'description': data['description'] ?? '',
                      'link': data['link'] ?? '',
                      'category': data['category'] ?? 'Other',
                    };
                  }).toList();

                  final filtered = groups.where((g) {
                    final catMatch = _selectedCategories.contains('All') ||
                        _selectedCategories.contains(g['category']);
                    final searchMatch = _searchController.text.isEmpty ||
                        g['name']
                            .toLowerCase()
                            .contains(_searchController.text.toLowerCase());
                    return catMatch && searchMatch;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        "No results found.",
                        style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _buildGroupCard(filtered[index], isDark);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}