import 'package:flutter/material.dart';
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


  void _showComingSoon(String featureName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Coming Soon"),
        content: Text("$featureName feature is under development."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }


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
              fontSize: 22,
              color: Colors.black,
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
                _buildHomeButton("Daily Journal"),
                _buildHomeButton("Chat with Heneuro"),
                _buildHomeButton("Mood Updates"),
                _buildHomeButton("Listen to Music"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeButton(String title) {
    return ElevatedButton(
      onPressed: () {
        _showComingSoon(title);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Center(
        child: Text(
          title,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }


  Widget _buildExplore() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: "Search...",
              prefixIcon: const Icon(Icons.search),
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          _buildExploreButton("Breathing Exercises"),
          _buildExploreButton("Mood Tracker"),
          _buildExploreButton("Relaxing Sounds"),
          _buildExploreButton("Helplines"),
        ],
      ),
    );
  }

  Widget _buildExploreButton(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          _showComingSoon(title);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(title),
      ),
    );
  }


  Widget _buildHeneuro() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          _showComingSoon("Heneuro");
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        child: const Text("Chat with Heneuro (Coming Soon)"),
      ),
    );
  }


  Widget _buildSnS() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          _showComingSoon("Sleep n Sound");
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        child: const Text("Sleep n Sound (Coming Soon)"),
      ),
    );
  }


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
            _showComingSoon(title);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor:
          isDelete ? Colors.red : Colors.deepPurple,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(title),
      ),
    );
  }


  BottomNavigationBarItem _navItem(IconData icon, String label, int index) {
    final bool isSelected = _selectedIndex == index;
    return BottomNavigationBarItem(
      icon: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.deepPurple,
        ),
      ),
      label: label,
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
        unselectedItemColor: Colors.deepPurple,
        backgroundColor: Colors.white,
        items: [
          _navItem(Icons.home, "Home", 0),
          _navItem(Icons.explore, "Explore", 1),
          _navItem(Icons.psychology, "Heneuro", 2),
          _navItem(Icons.nights_stay, "SnS", 3),
          _navItem(Icons.person, "Profile", 4),
        ],
      ),
    );
  }
}
