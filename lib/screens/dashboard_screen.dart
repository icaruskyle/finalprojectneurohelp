import 'package:flutter/material.dart';
import 'daily_journal_screen.dart';
import 'mood_updates_screen.dart';
import 'music_screen.dart';
import 'welcome_screen.dart';

// ✅ new imports for the extra screens
import 'emergency_contacts_screen.dart';
import 'self_help_screen.dart';
import 'feedback_screen.dart';
import 'personal_info_screen.dart';
import 'account_settings_screen.dart';
import 'data_privacy_screen.dart';
import 'change_password_screen.dart';
import 'terms_conditions_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String username;
  const DashboardScreen({super.key, required this.username});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  // 🔹 HOME TAB
  Widget _buildHome() {
    return Container(
      color: const Color(0xFFF3E9FF), // Soft lavender background
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          Text(
            "Welcome to NeuroHelp,\n${widget.username}",
            style: const TextStyle(
              fontSize: 26,
              color: Colors.deepPurple,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Choose a feature below to get started:",
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                // 🟣 Card with image - Daily Journal
                _buildHomeCardWithImage(
                  "Daily Journal",
                  "assets/images/diary.png",
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DailyJournalScreen(),
                      ),
                    );
                  },
                ),

                // 🟣 Card with image - Chat with Heneuro
                _buildHomeCardWithImage(
                  "Chat with Heneuro",
                  "assets/images/chat.png",
                      () {
                    _onItemTapped(2);
                  },
                ),

                // 🟣 Card with image - Mood Updates
                _buildHomeCardWithImage(
                  "Mood Updates",
                  "assets/images/mood.png",
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MoodUpdatesScreen(),
                      ),
                    );
                  },
                ),

                // 🟣 Card with image - Listen to Music
                _buildHomeCardWithImage(
                  "Listen to Music",
                  "assets/images/music.png",
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MusicScreen(),
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

  // 🔹 CARD with IMAGE (for all main features)
  Widget _buildHomeCardWithImage(
      String title, String imagePath, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade200],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🖼️ Larger image display for all icons
            Image.asset(
              imagePath,
              height: 100,
              width: 100,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 EXPLORE TAB
  Widget _buildExplore() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        ListTile(
          leading: Icon(Icons.article, color: Colors.deepPurple),
          title: Text("Latest Articles"),
          subtitle: Text("Read about mental health and wellness."),
        ),
        Divider(),
        ListTile(
          leading: Icon(Icons.event, color: Colors.deepPurple),
          title: Text("Upcoming Events"),
          subtitle: Text("Check mental health awareness activities."),
        ),
        Divider(),
        ListTile(
          leading: Icon(Icons.volunteer_activism, color: Colors.deepPurple),
          title: Text("Community Support"),
          subtitle: Text("Join discussions and support groups."),
        ),
      ],
    );
  }

  // 🔹 Heneuro Tab
  Widget _buildHeneuro() {
    return const Center(
      child: Text(
        "🤖 Chat with Heneuro (AI Assistant Coming Soon)",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 20, color: Colors.deepPurple),
      ),
    );
  }

  // 🔹 Journal + Mood Tracker Tab
  Widget _buildJournalMood() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Daily Journal & Mood Tracker",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 20),
          _buildFeatureCard(
            "Daily Journal",
            Icons.book,
            "Write your thoughts and reflect daily.",
                () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DailyJournalScreen(),
                ),
              );
            },
          ),
          _buildFeatureCard(
            "Mood Tracker",
            Icons.mood,
            "Track your mood and emotions regularly.",
                () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MoodUpdatesScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
      String title, IconData icon, String subtitle, VoidCallback onTap) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, size: 35, color: Colors.deepPurple),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: onTap,
      ),
    );
  }

  // 🔹 PROFILE TAB
  Widget _buildProfile() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const CircleAvatar(
          radius: 45,
          backgroundColor: Colors.deepPurple,
          child: Icon(Icons.person, size: 50, color: Colors.white),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            widget.username,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ),
        const SizedBox(height: 30),
        _buildProfileButton(Icons.info, "Personal Information", onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PersonalInfoScreen()),
          );
        }),
        _buildProfileButton(Icons.settings, "Account Settings", onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AccountSettingsScreen()),
          );
        }),
        _buildProfileButton(Icons.privacy_tip, "Data Privacy", onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DataPrivacyScreen()),
          );
        }),
        _buildProfileButton(Icons.lock, "Change Password", onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
          );
        }),
        _buildProfileButton(Icons.article, "Terms and Conditions", onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TermsConditionsScreen()),
          );
        }),
        _buildProfileButton(Icons.contacts, "Emergency Contacts", onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EmergencyContactsScreen()),
          );
        }),
        _buildProfileButton(Icons.self_improvement, "Self-Help Resources",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SelfHelpScreen()),
              );
            }),
        _buildProfileButton(Icons.feedback, "Feedback", onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FeedbackScreen()),
          );
        }),
        _buildProfileButton(Icons.logout, "Logout", isLogout: true),
        _buildProfileButton(Icons.delete_forever, "Delete Account",
            isDelete: true),
      ],
    );
  }

  Widget _buildProfileButton(IconData icon, String title,
      {VoidCallback? onTap, bool isLogout = false, bool isDelete = false}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: isDelete ? Colors.red : Colors.deepPurple),
        title: Text(title),
        onTap: () {
          if (isLogout) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (route) => false,
            );
          } else if (isDelete) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("⚠️ Account Deleted (placeholder)")),
            );
          } else if (onTap != null) {
            onTap();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("$title coming soon")),
            );
          }
        },
      ),
    );
  }

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
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Exit"),
              ),
            ],
          ),
        );
        return shouldExit ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("NeuroHelp"),
          backgroundColor: Colors.deepPurple,
          actions: [
            IconButton(
              icon: const Icon(Icons.dark_mode),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Dark Mode toggle coming soon")),
                );
              },
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
            BottomNavigationBarItem(icon: Icon(Icons.note_alt), label: "Journal"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
        ),
        floatingActionButton: _selectedIndex == 0
            ? FloatingActionButton(
          backgroundColor: Colors.deepPurple,
          child: const Icon(Icons.add),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text("Quick action coming soon")),
            );
          },
        )
            : null,
      ),
    );
  }
}
