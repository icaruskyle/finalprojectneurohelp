import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedMonth = 'All';
  String _selectedCategory = 'All';

  final List<Map<String, String>> _events = [
    {
      'title': 'World Mental Health Day 2025',
      'date': 'October 10, 2025',
      'description':
      'Join a global movement to raise awareness about mental health. Activities include online talks, community walks, and workshops.',
      'link': 'https://www.who.int/campaigns/world-mental-health-day',
      'month': 'October',
      'category': 'Awareness'
    },
    {
      'title': 'Mental Health Awareness Week',
      'date': 'May 12–18, 2025',
      'description':
      'A week-long awareness campaign encouraging open discussions about emotional well-being.',
      'link': 'https://www.mentalhealth.org.uk/our-work/mental-health-awareness-week',
      'month': 'May',
      'category': 'Campaign'
    },
    {
      'title': 'Self-Care Saturday Workshop',
      'date': 'March 22, 2025',
      'description':
      'Interactive online session teaching mindfulness, journaling, and healthy coping techniques.',
      'link': 'https://www.eventbrite.com/',
      'month': 'March',
      'category': 'Workshop'
    },
    {
      'title': 'Youth Mental Health Summit 2025',
      'date': 'July 18–20, 2025',
      'description':
      'A global event empowering youth advocates to innovate in mental health and digital wellness.',
      'link': 'https://www.unicef.org/mental-health',
      'month': 'July',
      'category': 'Conference'
    },
    {
      'title': 'National Suicide Prevention Awareness Month',
      'date': 'September 2025',
      'description':
      'Organizations and advocates collaborate to spread awareness and encourage help-seeking behavior.',
      'link': 'https://afsp.org/national-suicide-prevention-week',
      'month': 'September',
      'category': 'Awareness'
    },
    {
      'title': 'Community Healing Walk',
      'date': 'November 8, 2025',
      'description':
      'A community-led outdoor event that promotes connection, movement, and emotional healing.',
      'link': 'https://www.localwellness.org/events',
      'month': 'November',
      'category': 'Community'
    },
    {
      'title': 'Mindful Music & Art Fair',
      'date': 'December 13–14, 2025',
      'description':
      'A weekend of art therapy, live music, and mindfulness sessions to close the year positively.',
      'link': 'https://www.mindful.org/',
      'month': 'December',
      'category': 'Festival'
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
    // Filter based on search, month, and category
    final filteredEvents = _events.where((event) {
      final matchesMonth =
          _selectedMonth == 'All' || event['month'] == _selectedMonth;
      final matchesCategory =
          _selectedCategory == 'All' || event['category'] == _selectedCategory;
      final matchesSearch = event['title']!
          .toLowerCase()
          .contains(_searchController.text.toLowerCase());
      return matchesMonth && matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "📅 Upcoming Events",
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
                hintText: "Search events...",
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

          // 🗓️ Month Filter + Category Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                // Month Dropdown
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedMonth,
                    decoration: InputDecoration(
                      labelText: "Filter by Month",
                      prefixIcon: const Icon(Icons.calendar_today,
                          color: Colors.deepPurple),
                      filled: true,
                      fillColor: Colors.deepPurple.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All')),
                      DropdownMenuItem(value: 'March', child: Text('March')),
                      DropdownMenuItem(value: 'May', child: Text('May')),
                      DropdownMenuItem(value: 'July', child: Text('July')),
                      DropdownMenuItem(value: 'September', child: Text('September')),
                      DropdownMenuItem(value: 'October', child: Text('October')),
                      DropdownMenuItem(value: 'November', child: Text('November')),
                      DropdownMenuItem(value: 'December', child: Text('December')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedMonth = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                // Category Dropdown
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: "Category",
                      prefixIcon:
                      const Icon(Icons.category, color: Colors.deepPurple),
                      filled: true,
                      fillColor: Colors.deepPurple.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All')),
                      DropdownMenuItem(value: 'Awareness', child: Text('Awareness')),
                      DropdownMenuItem(value: 'Campaign', child: Text('Campaign')),
                      DropdownMenuItem(value: 'Workshop', child: Text('Workshop')),
                      DropdownMenuItem(value: 'Conference', child: Text('Conference')),
                      DropdownMenuItem(value: 'Community', child: Text('Community')),
                      DropdownMenuItem(value: 'Festival', child: Text('Festival')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 📋 Events List
          Expanded(
            child: filteredEvents.isEmpty
                ? const Center(
              child: Text(
                "No upcoming events found.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              itemCount: filteredEvents.length,
              itemBuilder: (context, index) {
                final item = filteredEvents[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: const Icon(Icons.event_available,
                        color: Colors.deepPurple, size: 30),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['date']!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            item['description']!,
                            style: const TextStyle(fontSize: 15),
                          ),
                        ],
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
