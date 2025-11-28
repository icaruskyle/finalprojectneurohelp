import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "📅 Upcoming Events",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("events").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data!.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();

          final filteredEvents = events.where((event) {
            final matchesMonth = _selectedMonth == 'All' || event['month'] == _selectedMonth;
            final matchesCategory = _selectedCategory == 'All' || event['category'] == _selectedCategory;
            final matchesSearch = event['title']
                .toString()
                .toLowerCase()
                .contains(_searchController.text.toLowerCase());
            return matchesMonth && matchesCategory && matchesSearch;
          }).toList();

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search,
                        color: isDark ? Colors.white : Colors.deepPurple),
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

              // Filters (responsive)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      SizedBox(
                        width: screenWidth * 0.45,
                        child: DropdownButtonFormField<String>(
                          value: _selectedMonth,
                          decoration: InputDecoration(
                            labelText: "Filter by Month",
                            prefixIcon: Icon(Icons.calendar_today,
                                color: isDark ? Colors.white : Colors.deepPurple),
                            filled: true,
                            fillColor: isDark ? Colors.grey[800] : Colors.deepPurple.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: "All", child: Text("All")),
                            DropdownMenuItem(value: "January", child: Text("January")),
                            DropdownMenuItem(value: "February", child: Text("February")),
                            DropdownMenuItem(value: "March", child: Text("March")),
                            DropdownMenuItem(value: "April", child: Text("April")),
                            DropdownMenuItem(value: "May", child: Text("May")),
                            DropdownMenuItem(value: "June", child: Text("June")),
                            DropdownMenuItem(value: "July", child: Text("July")),
                            DropdownMenuItem(value: "August", child: Text("August")),
                            DropdownMenuItem(value: "September", child: Text("September")),
                            DropdownMenuItem(value: "October", child: Text("October")),
                            DropdownMenuItem(value: "November", child: Text("November")),
                            DropdownMenuItem(value: "December", child: Text("December")),
                          ],
                          onChanged: (v) => setState(() => _selectedMonth = v!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: screenWidth * 0.45,
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: InputDecoration(
                            labelText: "Category",
                            prefixIcon: Icon(Icons.category,
                                color: isDark ? Colors.white : Colors.deepPurple),
                            filled: true,
                            fillColor: isDark ? Colors.grey[800] : Colors.deepPurple.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          items: _categoryColors.keys
                              .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedCategory = v!),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Event List
              Expanded(
                child: filteredEvents.isEmpty
                    ? const Center(child: Text("No upcoming events found."))
                    : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    final item = filteredEvents[index];
                    final catColor =
                        _categoryColors[item['category']] ?? Colors.deepPurple;

                    return Card(
                      color: isDark ? Colors.grey[850] : Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      elevation: 5,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Icon(Icons.event_available,
                              size: 30, color: catColor),
                        ),
                        title: Text(
                          item['title'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: catColor,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['date'],
                                style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87)),
                            const SizedBox(height: 5),
                            Text(
                              item['description'],
                              style: TextStyle(
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black54),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 3,
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.open_in_new, color: catColor),
                          onPressed: () => _launchURL(item['link']),
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
