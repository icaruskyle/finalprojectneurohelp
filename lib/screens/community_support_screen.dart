import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CommunitySupportScreen extends StatefulWidget {
  const CommunitySupportScreen({super.key});

  @override
  State<CommunitySupportScreen> createState() => _CommunitySupportScreenState();
}

class _CommunitySupportScreenState extends State<CommunitySupportScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final List<Map<String, String>> _supportGroups = [
    {
      'name': '7 Cups - Online Emotional Support',
      'description':
      'Free online chat with trained listeners for anyone needing to talk. Great for emotional distress and loneliness.',
      'link': 'https://www.7cups.com',
      'category': 'Online Support'
    },
    {
      'name': 'NAMI (National Alliance on Mental Illness)',
      'description':
      'Offers education, support groups, and resources for individuals and families affected by mental illness.',
      'link': 'https://www.nami.org/Home',
      'category': 'Organizations'
    },
    {
      'name': 'Reddit - r/MentalHealth',
      'description':
      'An active online forum where people share personal stories and mental health discussions.',
      'link': 'https://www.reddit.com/r/mentalhealth/',
      'category': 'Community Forums'
    },
    {
      'name': 'Mental Health PH',
      'description':
      'A Filipino mental health advocacy group providing local support, campaigns, and educational events.',
      'link': 'https://mentalhealthph.org/',
      'category': 'Organizations'
    },
    {
      'name': 'The Mighty Community',
      'description':
      'A safe place where people share their experiences living with mental illness and chronic conditions.',
      'link': 'https://themighty.com/',
      'category': 'Community Forums'
    },
    {
      'name': 'Mind UK',
      'description':
      'A UK-based charity providing advice, information, and online peer support for mental health issues.',
      'link': 'https://www.mind.org.uk/',
      'category': 'Organizations'
    },
    {
      'name': 'Teen Line',
      'description':
      'A confidential hotline and community where teens can talk with trained teen listeners about their problems.',
      'link': 'https://teenlineonline.org/',
      'category': 'Youth Support'
    },
    {
      'name': 'Crisis Text Line',
      'description':
      'Text-based emotional support 24/7. In the US, text HELLO to 741741. Available globally via website.',
      'link': 'https://www.crisistextline.org/',
      'category': 'Hotlines'
    },
    {
      'name': 'Mental Health Foundation (Philippines)',
      'description':
      'Promotes awareness and creates spaces for emotional support through programs and social media advocacy.',
      'link': 'https://www.facebook.com/mentalhealthfoundationph/',
      'category': 'Organizations'
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
    // Filter list based on category and search
    final filteredGroups = _supportGroups.where((group) {
      final matchesCategory =
          _selectedCategory == 'All' || group['category'] == _selectedCategory;
      final matchesSearch = group['name']!
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
      ),
      body: Column(
        children: [
          // 🔍 Search bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                hintText: "Search support groups...",
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

          // 🎯 Category filter
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
                DropdownMenuItem(value: 'Online Support', child: Text('Online Support')),
                DropdownMenuItem(value: 'Organizations', child: Text('Organizations')),
                DropdownMenuItem(value: 'Community Forums', child: Text('Community Forums')),
                DropdownMenuItem(value: 'Youth Support', child: Text('Youth Support')),
                DropdownMenuItem(value: 'Hotlines', child: Text('Hotlines')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
          ),

          const SizedBox(height: 10),

          // 🧑‍🤝‍🧑 Support group cards
          Expanded(
            child: filteredGroups.isEmpty
                ? const Center(
              child: Text(
                "No community support groups found.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : ListView.builder(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: filteredGroups.length,
              itemBuilder: (context, index) {
                final item = filteredGroups[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: const Icon(Icons.groups,
                        color: Colors.deepPurple, size: 30),
                    title: Text(
                      item['name']!,
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
