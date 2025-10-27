import 'package:flutter/material.dart';
import 'daily_journal_screen.dart';
import 'mood_updates_screen.dart';
import 'music_screen.dart'; // ✅ Spotify-connected music screen
import 'welcome_screen.dart';
import 'emergency_contacts_screen.dart';
import 'self_help_screen.dart';
import 'feedback_screen.dart';
import 'personal_info_screen.dart';
import 'account_settings_screen.dart';
import 'data_privacy_screen.dart';
import 'change_password_screen.dart';
import 'terms_conditions_screen.dart';
import 'articles_screen.dart';
import 'events_screen.dart';
import 'community_support_screen.dart';


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


  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    _pageController.jumpToPage(index);
  }


  void _toggleDarkMode() {
    setState(() => _isDarkMode = !_isDarkMode);
  }


  // ---------- Theme Colors ----------
  Color get primary => Colors.deepPurple;
  Color get background => _isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
  Color get cardColor => _isDarkMode ? const Color(0xFF2C2C2E) : Colors.white;
  Color get textPrimary => _isDarkMode ? Colors.white : Colors.deepPurple.shade900;
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
              CircleAvatar(
                radius: 28,
                backgroundColor: primary.withOpacity(0.2),
                child: Icon(Icons.person, color: accent, size: 35),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Welcome back,", style: TextStyle(color: textSecondary, fontSize: 16)),
                  Text(
                    widget.username,
                    style: TextStyle(color: textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 25),
          Text("Choose a feature to begin:", style: TextStyle(color: textSecondary, fontSize: 16)),
          const SizedBox(height: 25),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildAnimatedCard("Daily Journal", "assets/images/diary.png", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DailyJournalScreen(username: widget.username),
                    ),
                  );
                }),
                _buildAnimatedCard("Chat with Heneuro", "assets/images/chat.png", () {
                  _onItemTapped(2);
                }),
                _buildAnimatedCard("Mood Updates", "assets/images/mood.png", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MoodUpdatesScreen(username: widget.username),
                    ),
                  );
                }),
                // ✅ Updated Spotify Music Navigation
                _buildAnimatedCard("Listen to Music", "assets/images/music.png", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MusicScreen()), // Spotify-connected
                  );
                }),
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
          _buildListCard(Icons.article, "Latest Articles", "Read about mental health and wellness.", () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ArticlesScreen()));
          }),
          _buildListCard(Icons.event, "Upcoming Events", "Check upcoming awareness activities.", () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsScreen()));
          }),
          _buildListCard(Icons.volunteer_activism, "Community Support",
              "Join discussions and support groups.", () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunitySupportScreen()));
              }),
        ],
      ),
    );
  }


  Widget _buildListCard(IconData icon, String title, String subtitle, VoidCallback onTap) {
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
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Text(subtitle, style: TextStyle(color: textSecondary, fontSize: 14)),
        trailing: Icon(Icons.arrow_forward_ios, size: 18, color: accent.withOpacity(0.8)),
        onTap: onTap,
      ),
    );
  }


  // ---------- Heneuro (AI) ----------
  Widget _buildHeneuro() {
    return Container(
      color: background,
      alignment: Alignment.center,
      child: Text(
        "🤖 Chat with Heneuro (Coming Soon)",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 20, color: textPrimary),
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
          Text(
            "Wellness, Journal & Mood",
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 22),
          ),
          const SizedBox(height: 20),
          _buildFeatureCard("Daily Journal", Icons.book, "Write your thoughts and reflect daily.", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DailyJournalScreen(username: widget.username)),
            );
          }),
          _buildFeatureCard("Mood Tracker", Icons.mood, "Track your mood and emotions regularly.", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MoodUpdatesScreen(username: widget.username)),
            );
          }),
          _buildFeatureCard("Self-Help Resources", Icons.self_improvement,
              "Access helpful guides, tips, and self-care materials.", () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SelfHelpScreen()));
              }),
          _buildFeatureCard("Emergency Contacts", Icons.contacts,
              "Quickly reach your emergency support contacts.", () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyContactsScreen()));
              }),
        ],
      ),
    );
  }


  Widget _buildFeatureCard(String title, IconData icon, String subtitle, VoidCallback onTap) {
    return Card(
      color: cardColor,
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, size: 35, color: accent),
        title: Text(title, style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(color: textSecondary)),
        trailing: Icon(Icons.arrow_forward_ios, size: 18, color: accent.withOpacity(0.8)),
        onTap: onTap,
      ),
    );
  }


  // ---------- PROFILE TAB ----------
  Widget _buildProfile() {
    return Container(
      color: background,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: accent,
            child: const Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(widget.username,
                style: TextStyle(color: textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 30),
          _buildProfileTile(Icons.info, "Personal Information", const PersonalInfoScreen()),
          _buildProfileTile(Icons.settings, "Account Settings", const AccountSettingsScreen()),
          _buildProfileTile(Icons.privacy_tip, "Data Privacy", const DataPrivacyScreen()),
          _buildProfileTile(Icons.lock, "Change Password", const ChangePasswordScreen()),
          _buildProfileTile(Icons.article, "Terms & Conditions", const TermsConditionsScreen()),
          _buildProfileTile(Icons.feedback, "Feedback", const FeedbackScreen()),
          _buildProfileTile(Icons.logout, "Logout", null, isLogout: true),
          _buildProfileTile(Icons.delete_forever, "Delete Account", null, isDelete: true),
        ],
      ),
    );
  }


  Widget _buildProfileTile(IconData icon, String title, Widget? screen,
      {bool isLogout = false, bool isDelete = false}) {
    return Card(
      color: cardColor,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: isDelete ? Colors.redAccent : accent, size: 28),
        title: Text(title, style: TextStyle(color: textPrimary)),
        onTap: () {
          if (isLogout) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (route) => false,
            );
          } else if (isDelete) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("⚠️ Account deleted (placeholder)")),
            );
          } else if (screen != null) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
          }
        },
      ),
    );
  }


  // ---------- BUILD ----------
  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHome(),
      _buildExplore(),
      _buildHeneuro(),
      _buildJournalMood(),
      _buildProfile(),
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
            BottomNavigationBarItem(icon: Icon(Icons.psychology), label: "Heneuro"),
            BottomNavigationBarItem(icon: Icon(Icons.note_alt), label: "Others"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      ),
    );
  }
}

