import 'package:flutter/material.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text("Explore"),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: _buildExplore(background, textColor, context),
    );
  }

  Widget _buildExplore(Color background, Color textColor, BuildContext context) {
    return Container(
      color: background,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildListCard(
            Icons.article,
            "Latest Articles",
            "Read about mental health and wellness.",
            Colors.deepPurple,
            context,
          ),
          _buildListCard(
            Icons.event,
            "Upcoming Events",
            "Check upcoming awareness activities.",
            Colors.purpleAccent,
            context,
          ),
          _buildListCard(
            Icons.volunteer_activism,
            "Community Support",
            "Join discussions and support groups.",
            Colors.deepPurpleAccent,
            context,
          ),
        ],
      ),
    );
  }

  Widget _buildListCard(
      IconData icon,
      String title,
      String subtitle,
      Color color,
      BuildContext context,
      ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor =
    isDark ? Colors.deepPurple.shade900 : Colors.deepPurple.shade50;

    return Card(
      color: cardColor,
      elevation: 4,
      shadowColor: Colors.deepPurple.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          radius: 28,
          child: Icon(icon, color: color, size: 30),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.deepPurple,
            fontSize: 18,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black87,
            fontSize: 14,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.deepPurple),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Opening $title... (Coming Soon!)"),
              backgroundColor: Colors.deepPurple,
            ),
          );
        },
      ),
    );
  }
}
