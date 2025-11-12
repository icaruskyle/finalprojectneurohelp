import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EventsScreen extends StatefulWidget {
  final bool isDarkMode;
  const EventsScreen({super.key, required this.isDarkMode});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedMonth = 'All';
  String _selectedCategory = 'All';

  final List<Map<String, String>> _events = [
    // ... your events list (unchanged)
  ];

  final Map<String, Color> _categoryColors = {
    'Awareness': Colors.pinkAccent,
    'Campaign': Colors.orange,
    'Workshop': Colors.blue,
    'Conference': Colors.teal,
    'Community': Colors.green,
    'Festival': Colors.purple,
    'All': Colors.deepPurple,
  };

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;

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
        title: const Text("📅 Upcoming Events", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: isDark ? Colors.white : Colors.deepPurple),
                hintText: "Search events...",
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

          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedMonth,
                    decoration: InputDecoration(
                      labelText: "Filter by Month",
                      prefixIcon: Icon(Icons.calendar_today, color: isDark ? Colors.white : Colors.deepPurple),
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : Colors.deepPurple.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
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
                    onChanged: (value) => setState(() => _selectedMonth = value!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: "Category",
                      prefixIcon: Icon(Icons.category, color: isDark ? Colors.white : Colors.deepPurple),
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : Colors.deepPurple.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    items: _categoryColors.keys
                        .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedCategory = value!),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Event List
          Expanded(
            child: filteredEvents.isEmpty
                ? Center(
              child: Text("No upcoming events found.",
                  style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : Colors.grey)),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: filteredEvents.length,
              itemBuilder: (context, index) {
                final item = filteredEvents[index];
                final catColor = _categoryColors[item['category']] ?? Colors.deepPurple;

                return Card(
                  color: isDark ? Colors.grey[850] : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Icon(Icons.event_available, size: 30, color: catColor),
                    title: Text(item['title']!,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: catColor)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['date']!, style: TextStyle(fontSize: 14, color: isDark ? Colors.white60 : Colors.black54)),
                          const SizedBox(height: 5),
                          Text(item['description']!, style: TextStyle(fontSize: 15, color: isDark ? Colors.white70 : Colors.black87)),
                        ],
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
      ),
    );
  }
}
