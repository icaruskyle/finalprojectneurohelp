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
import 'heneuro_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'theme_notifier.dart'; // path depends on your project structure
import 'dart:io';

class DashboardScreen extends StatefulWidget {
  final String username;
  const DashboardScreen({super.key, required this.username});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
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

  // ------------------ Colors ------------------
  Color primary(bool isDarkMode) => Colors.deepPurple;
  Color background(bool isDarkMode) => isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
  Color cardColor(bool isDarkMode) => isDarkMode ? const Color(0xFF2C2C2E) : Colors.white;
  Color textPrimary(bool isDarkMode) => isDarkMode ? Colors.white : Colors.deepPurple.shade900;
  Color textSecondary(bool isDarkMode) => isDarkMode ? Colors.white70 : Colors.black87;
  Color accent(bool isDarkMode) => isDarkMode ? Colors.purpleAccent : Colors.deepPurple;

  // ---------------- HOME TAB ----------------
  Widget _buildHome(bool isDarkMode) {
    return Container(
      color: background(isDarkMode),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: primary(isDarkMode).withOpacity(0.2),
                child: _userAvatar == null
                    ? Icon(Icons.person, color: accent(isDarkMode), size: 35)
                    : ClipOval(
                  child: _userAvatar!.contains("assets")
                      ? Image.asset(
                    _userAvatar!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  )
                      : Image.file(
                    File(_userAvatar!),
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Welcome back,", style: TextStyle(color: textSecondary(isDarkMode), fontSize: 16)),
                  Text(widget.username,
                      style: TextStyle(
                          color: textPrimary(isDarkMode),
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 25),
          Text("Choose a feature to begin:", style: TextStyle(color: textSecondary(isDarkMode), fontSize: 16)),
          const SizedBox(height: 25),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildAnimatedCard("Daily Journal", "assets/images/diary.png", () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => DailyJournalScreen()));
                }, isDarkMode),
                _buildAnimatedCard("Chat with Heneuro", "assets/images/chat.png", () {
                  _onItemTapped(2);
                }, isDarkMode),
                _buildAnimatedCard("Mood Updates", "assets/images/mood.png", () {
                  final String uid = FirebaseAuth.instance.currentUser!.uid;
                  Navigator.push(context, MaterialPageRoute(builder: (_) => MoodUpdatesScreen(uid: uid)));
                }, isDarkMode),
                _buildAnimatedCard("Listen to Music", "assets/images/music.png", () {
                  final String uid = FirebaseAuth.instance.currentUser!.uid;
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => MusicScreen(uid: uid, isDarkMode: isDarkMode)));
                }, isDarkMode),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedCard(String title, String image, VoidCallback onTap, bool isDarkMode) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      splashColor: Colors.white24,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [Colors.deepPurple.shade700, Colors.purpleAccent.shade200]
                : [Colors.deepPurple, Colors.deepPurpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(image, height: 90, width: 90),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ---------------- EXPLORE TAB ----------------
  Widget _buildExplore(bool isDarkMode) {
    return Container(
      color: background(isDarkMode),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildListCard(Icons.article, "Latest Articles", "Read about mental health and wellness.", () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => ArticlesScreen(isDarkMode: isDarkMode)));
          }, isDarkMode),
          _buildListCard(Icons.event, "Upcoming Events", "Check upcoming awareness activities.", () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => EventsScreen(isDarkMode: isDarkMode)));
          }, isDarkMode),
          _buildListCard(Icons.volunteer_activism, "Community Support", "Join discussions and support groups.", () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => CommunitySupportScreen(isDarkMode: isDarkMode)));
          }, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildListCard(IconData icon, String title, String subtitle, VoidCallback onTap, bool isDarkMode) {
    return Card(
      color: cardColor(isDarkMode),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 4,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(backgroundColor: accent(isDarkMode).withOpacity(0.2), radius: 28, child: Icon(icon, color: accent(isDarkMode), size: 30)),
        title: Text(title, style: TextStyle(color: textPrimary(isDarkMode), fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Text(subtitle, style: TextStyle(color: textSecondary(isDarkMode), fontSize: 14)),
        trailing: Icon(Icons.arrow_forward_ios, size: 18, color: accent(isDarkMode).withOpacity(0.8)),
        onTap: onTap,
      ),
    );
  }

  // ---------------- OTHERS TAB ----------------
  Widget _buildJournalMood(bool isDarkMode) {
    return Container(
      color: background(isDarkMode),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Wellness, Journal & Mood", style: TextStyle(color: textPrimary(isDarkMode), fontWeight: FontWeight.bold, fontSize: 22)),
          const SizedBox(height: 20),
          _buildFeatureCard("Daily Journal", Icons.book, "Write your thoughts and reflect daily.", () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => DailyJournalScreen()));
          }, isDarkMode),
          _buildFeatureCard("Mood Tracker", Icons.mood, "Track your mood and emotions regularly.", () {
            final String uid = FirebaseAuth.instance.currentUser!.uid;
            Navigator.push(context, MaterialPageRoute(builder: (_) => MoodUpdatesScreen(uid: uid)));
          }, isDarkMode),
          _buildFeatureCard("Self-Help Resources", Icons.self_improvement, "Access helpful guides, tips, and self-care materials.", () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SelfHelpScreen()));
          }, isDarkMode),
          _buildFeatureCard("Emergency Contacts", Icons.contacts, "Quickly reach your emergency support contacts.", () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyContactsScreen()));
          }, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(String title, IconData icon, String subtitle, VoidCallback onTap, bool isDarkMode) {
    return Card(
      color: cardColor(isDarkMode),
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, size: 35, color: accent(isDarkMode)),
        title: Text(title, style: TextStyle(color: textPrimary(isDarkMode), fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(color: textSecondary(isDarkMode))),
        trailing: Icon(Icons.arrow_forward_ios, size: 18, color: accent(isDarkMode).withOpacity(0.8)),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDarkMode = themeNotifier.isDarkMode;

    final pages = [
      _buildHome(isDarkMode),
      _buildExplore(isDarkMode),
      HeneuroTab(isDarkMode: isDarkMode),
      _buildJournalMood(isDarkMode),
      ProfileTab(
        username: widget.username,
        isDarkMode: isDarkMode,
        onToggleTheme: (value) => themeNotifier.toggleTheme(value),
      )
    ];

    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Exit App"),
            content: const Text("Do you want to close NeuroHelp?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Exit")),
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
              gradient: LinearGradient(colors: [Colors.deepPurple, Colors.purpleAccent], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: () => themeNotifier.toggleTheme(!isDarkMode),
            ),
          ],
        ),
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) async {
            setState(() => _selectedIndex = index);
            await _loadUserAvatar(); // <-- updates avatar immediately
          },
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
            BottomNavigationBarItem(icon: Icon(Icons.psychology), label: "Heneuro"),
            BottomNavigationBarItem(icon: Icon(Icons.note_alt), label: "Others"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      ),
    );
  }
}
