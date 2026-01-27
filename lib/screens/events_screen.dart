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
  String _selectedTime = 'All';
  String _selectedCategory = 'All';

  final Map<String, Color> _categoryColors = {
    'Awareness': Colors.pinkAccent,
    'Campaign': Colors.orange,
    'Workshop': Colors.blue,
    'Conference': Colors.teal,
    'Webinar': Colors.yellowAccent,
    'Community': Colors.green,
    'Festival': Colors.purple,
    'All': Colors.deepPurple,
  };

  final List<String> timeFilters = [
    "All",
    "Today",
    "This Week",
    "This Month",
    "Upcoming",
  ];

  Future<void> _launchURL(String url) async {
    if (url.isEmpty) return;

    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open link")),
      );
    }
  }

  bool matchTimeFilter(dynamic rawDate) {
    if (rawDate == null || rawDate is! Timestamp) return true;

    final eventDate = rawDate.toDate();
    final now = DateTime.now();

    switch (_selectedTime) {
      case "Today":
        return eventDate.year == now.year &&
            eventDate.month == now.month &&
            eventDate.day == now.day;

      case "This Week":
        return eventDate.isAfter(now.subtract(const Duration(days: 1))) &&
            eventDate.isBefore(now.add(const Duration(days: 7)));

      case "This Month":
        return eventDate.year == now.year &&
            eventDate.month == now.month;

      case "Upcoming":
        return eventDate.isAfter(now);

      default:
        return true;
    }
  }

  void _showEventDetails(Map<String, dynamic> event, Color color) {
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.isDarkMode ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                event["title"] ?? "No Title",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                event["description"] ?? "No Description",
                style: TextStyle(
                  color: widget.isDarkMode
                      ? Colors.grey[200]
                      : Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text("Open Link"),
                onPressed: event["link"] == null || event["link"].isEmpty
                    ? null
                    : () => _launchURL(event["link"]),
                style: ElevatedButton.styleFrom(backgroundColor: color),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text("📅 Upcoming Events"),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("events")
            .where("rawDate", isNotEqualTo: null)
            .orderBy("rawDate", descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No events available",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final events = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              "id": doc.id,
              "title": data["title"] ?? "",
              "description": data["description"] ?? "",
              "category": data["category"] ?? "All",
              "link": data["link"] ?? "",
              "rawDate": data["rawDate"],
            };
          }).toList();

          final filtered = events.where((event) {
            final matchTime = matchTimeFilter(event["rawDate"]);
            final matchCat =
                _selectedCategory == "All" ||
                    event["category"] == _selectedCategory;
            final matchSearch = event["title"]
                .toString()
                .toLowerCase()
                .contains(_searchController.text.toLowerCase());

            return matchTime && matchCat && matchSearch;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search events...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: isDark
                        ? Colors.grey[800]
                        : Colors.deepPurple.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final color = _categoryColors[item["category"]] ??
                        Colors.deepPurple;

                    return ExpansionTile(
                      backgroundColor:
                      isDark ? Colors.grey[850] : Colors.white,
                      collapsedBackgroundColor:
                      isDark ? Colors.grey[900] : Colors.white,
                      iconColor: color,
                      collapsedIconColor: color,
                      textColor: color,
                      collapsedTextColor: color,
                      leading: Icon(Icons.event, color: color),
                      title: Text(
                        item["title"],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        item["category"],
                        style: TextStyle(
                          color: isDark
                              ? Colors.grey[300]
                              : Colors.grey[700],
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Text(
                            item["description"],
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey[200]
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.info_outline),
                              label: const Text("Details"),
                              onPressed: () =>
                                  _showEventDetails(item, color),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              icon: const Icon(Icons.open_in_new),
                              label: const Text("View Link"),
                              onPressed: item["link"] == null ||
                                  item["link"].isEmpty
                                  ? null
                                  : () => _launchURL(item["link"]),
                            ),
                            const SizedBox(width: 12),
                          ],
                        ),
                      ],
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
