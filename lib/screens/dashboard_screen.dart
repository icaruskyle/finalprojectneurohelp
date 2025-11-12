import 'package:flutter/material.dart';
import 'daily_journal_screen.dart';
import 'mood_updates_screen.dart';
import 'music_screen.dart';
import 'self_help_screen.dart';
import 'emergency_contacts_screen.dart';
import 'articles_screen.dart';
import 'events_screen.dart';
import 'community_support_screen.dart';
import 'profile_tab.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ai_service.dart';
import 'heneuro_tab.dart'; // ✅ import for AI chat tab

class DashboardScreen extends StatefulWidget {
  final String username;
  const DashboardScreen({super.key, required this.username});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  bool _isDarkMode = false;

  String? _userAvatar;

  @override
  void initState() {
    super.initState();
    _loadUserAvatar();
  }

  Future<void> _loadUserAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userAvatar = prefs.getString('selectedAvatar');
    });
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    _pageController.jumpToPage(index);
  }

  void _toggleDarkMode() {
    setState(() => _isDarkMode = !_isDarkMode);
  }

  // ---------- THEME COLORS ----------
  Color get primary => Colors.deepPurple;
  Color get background => _isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
  Color get cardColor => _isDarkMode ? const Color(0xFF2C2C2E) : Colors.white;
  Color get textPrimary =>
      _isDarkMode ? Colors.white : Colors.deepPurple.shade900;
  Color get textSecondary => _isDarkMode ? Colors.white70 : Colors.black87;
  Color get accent => _isDarkMode ? Colors.purpleAccent : Colors.deepPurple;

  // ---------- HOME TAB ----------
  Widget _buildHome() {
    return Container(
      color: background,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  setState(() {
                    _selectedIndex = 4; // Go to Profile tab
                  });
                },
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: primary.withOpacity(0.2),
                  backgroundImage:
                  _userAvatar != null ? AssetImage(_userAvatar!) : null,
                  child: _userAvatar == null
                      ? Icon(Icons.person, color: accent, size: 35)
                      : null,
                ),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Welcome back,",
                      style: TextStyle(color: textSecondary, fontSize: 16)),
                  Text(
                    widget.username,
                    style: TextStyle(
                        color: textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 25),
          Text("Choose a feature to begin:",
              style: TextStyle(color: textSecondary, fontSize: 16)),
          const SizedBox(height: 25),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildAnimatedCard("Daily Journal", "assets/images/diary.png",
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DailyJournalScreen(), // ✅ fixed
                        ),
                      );
                    }),
                _buildAnimatedCard(
                    "Chat with Heneuro", "assets/images/chat.png", () {
                  _onItemTapped(2); // open AI tab
                }),
                _buildAnimatedCard("Mood Updates", "assets/images/mood.png", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          MoodUpdatesScreen(uid: widget.username), // ✅ fixed
                    ),
                  );
                }),
                _buildAnimatedCard(
                  "Listen to Music",
                  "assets/images/music.png",
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MusicScreen(isDarkMode: _isDarkMode),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedCard(String title, String image, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      splashColor: Colors.white24,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isDarkMode
                ? [Colors.deepPurple.shade700, Colors.purpleAccent.shade200]
                : [Colors.deepPurple, Colors.deepPurpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(image, height: 90, width: 90),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- EXPLORE TAB ----------
  Widget _buildExplore() {
    return Container(
      color: background,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildListCard(Icons.article, "Latest Articles",
              "Read about mental health and wellness.", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ArticlesScreen(isDarkMode: _isDarkMode),
                  ),
                );
              }),
          _buildListCard(Icons.event, "Upcoming Events",
              "Check upcoming awareness activities.", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EventsScreen(isDarkMode: _isDarkMode),
                  ),
                );
              }),
          _buildListCard(Icons.volunteer_activism, "Community Support",
              "Join discussions and support groups.", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CommunitySupportScreen(isDarkMode: _isDarkMode),
                  ),
                );
              }),
        ],
      ),
    );
  }

  Widget _buildListCard(
      IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 4,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: accent.withOpacity(0.2),
          radius: 28,
          child: Icon(icon, color: accent, size: 30),
        ),
        title: Text(title,
            style: TextStyle(
                color: textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle:
        Text(subtitle, style: TextStyle(color: textSecondary, fontSize: 14)),
        trailing: Icon(Icons.arrow_forward_ios,
            size: 18, color: accent.withOpacity(0.8)),
        onTap: onTap,
      ),
    );
  }

  // ---------- OTHERS TAB ----------
  Widget _buildJournalMood() {
    return Container(
      color: background,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Wellness, Journal & Mood",
              style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 22)),
          const SizedBox(height: 20),
          _buildFeatureCard("Daily Journal", Icons.book,
              "Write your thoughts and reflect daily.", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => DailyJournalScreen()), // ✅ fixed
                );
              }),
          _buildFeatureCard("Mood Tracker", Icons.mood,
              "Track your mood and emotions regularly.", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          MoodUpdatesScreen(uid: widget.username)), // ✅ fixed
                );
              }),
          _buildFeatureCard("Self-Help Resources", Icons.self_improvement,
              "Access helpful guides, tips, and self-care materials.", () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SelfHelpScreen()));
              }),
          _buildFeatureCard("Emergency Contacts", Icons.contacts,
              "Quickly reach your emergency support contacts.", () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const EmergencyContactsScreen()));
              }),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
      String title, IconData icon, String subtitle, VoidCallback onTap) {
    return Card(
      color: cardColor,
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, size: 35, color: accent),
        title: Text(title,
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(color: textSecondary)),
        trailing: Icon(Icons.arrow_forward_ios,
            size: 18, color: accent.withOpacity(0.8)),
        onTap: onTap,
      ),
    );
  }

  // ---------- BUILD ----------
  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHome(),
      _buildExplore(),
      HeneuroTab(isDarkMode: _isDarkMode), // ✅ new AI tab
      _buildJournalMood(),
      ProfileTab(
        username: widget.username,
        isDarkMode: _isDarkMode,
        onToggleTheme: _toggleDarkMode,
      ),
    ];

    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Exit App"),
            content: const Text("Do you want to close NeuroHelp?"),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancel")),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Exit")),
            ],
          ),
        );
        return shouldExit ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text("NeuroHelp"),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.purpleAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: _toggleDarkMode,
            ),
          ],
        ),
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) => setState(() => _selectedIndex = index),
          children: pages,
        ),
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
            BottomNavigationBarItem(
                icon: Icon(Icons.note_alt), label: "Others"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      ),
    );
  }
}
