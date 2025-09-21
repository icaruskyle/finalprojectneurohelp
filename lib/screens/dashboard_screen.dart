import 'package:flutter/material.dart';
import 'daily_journal_screen.dart';
import 'mood_updates_screen.dart';
import 'music_screen.dart';
import 'welcome_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String username;
  const DashboardScreen({super.key, required this.username});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // 🔹 Home Tab
  Widget _buildHome() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          Text(
            "Welcome to NeuroHelp,\n${widget.username}",
            style: const TextStyle(
              fontSize: 24,
              color: Colors.deepPurple,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildHomeButton("Daily Journal", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DailyJournalScreen(),
                    ),
                  );
                }),
                _buildHomeButton("Chat with Heneuro", () {
                  setState(() {
                    _selectedIndex = 2; // go to Heneuro tab
                  });
                }),
                _buildHomeButton("Mood Updates", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MoodUpdatesScreen(),
                    ),
                  );
                }),
                _buildHomeButton("Listen to Music", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MusicScreen(),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeButton(String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade50,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.deepPurple,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  // 🔹 Explore Tab
  Widget _buildExplore() {
    return const Center(
      child: Text("Explore Coming Soon",
          style: TextStyle(fontSize: 20, color: Colors.deepPurple)),
    );
  }

  // 🔹 Heneuro Tab
  Widget _buildHeneuro() {
    return const Center(
      child: Text("Chat with Heneuro Coming Soon",
          style: TextStyle(fontSize: 20, color: Colors.deepPurple)),
    );
  }

  // 🔹 SnS Tab
  Widget _buildSnS() {
    return const Center(
      child: Text("Sleep n Sound Coming Soon",
          style: TextStyle(fontSize: 20, color: Colors.deepPurple)),
    );
  }

  // 🔹 Profile Tab
  Widget _buildProfile() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Your Account",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 20),
          _buildProfileButton("Personal Information"),
          _buildProfileButton("Account Settings"),
          _buildProfileButton("Data Privacy"),
          _buildProfileButton("Change Password"),
          _buildProfileButton("Terms and Conditions"),
          _buildProfileButton("Feedback"),
          _buildProfileButton("Logout", isLogout: true),
          _buildProfileButton("Delete Account", isDelete: true),
        ],
      ),
    );
  }

  Widget _buildProfileButton(String title,
      {bool isLogout = false, bool isDelete = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          if (isLogout) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (route) => false,
            );
          } else if (isDelete) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Account Deleted (placeholder)")),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("$title coming soon")),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor:
          isDelete ? Colors.red : (isLogout ? Colors.deepPurple : Colors.white),
          foregroundColor:
          isDelete ? Colors.white : (isLogout ? Colors.white : Colors.deepPurple),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isDelete || isLogout
                ? BorderSide.none
                : const BorderSide(color: Colors.deepPurple, width: 1.2),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHome(),
      _buildExplore(),
      _buildHeneuro(),
      _buildSnS(),
      _buildProfile(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        backgroundColor: Colors.deepPurple,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: "Explore"),
          BottomNavigationBarItem(
              icon: Icon(Icons.psychology), label: "Heneuro"),
          BottomNavigationBarItem(icon: Icon(Icons.nights_stay), label: "SnS"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
