import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:projects/screens/login_screen.dart';
import 'daily_journal_screen.dart';
import 'mood_updates_screen.dart';
import 'music_screen.dart';
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

  // ---------- THEME COLORS ----------
  Color get primary => Colors.deepPurple;
  Color get background => _isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
  Color get cardColor => _isDarkMode ? const Color(0xFF2C2C2E) : Colors.white;
  Color get textPrimary => _isDarkMode ? Colors.white : Colors.deepPurple.shade900;
  Color get textSecondary => _isDarkMode ? Colors.white70 : Colors.black87;
  Color get accent => _isDarkMode ? Colors.purpleAccent : Colors.deepPurple;

  // ---------- DELETE ACCOUNT FUNCTION ----------
  Future<void> _confirmDeleteAccount() async {
    int countdown = 5;
    bool confirmed = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future.delayed(const Duration(seconds: 1), () {
              if (countdown > 0) setState(() => countdown--);
            });

            return AlertDialog(
              title: const Text("Delete Account"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "This will permanently delete your account and all your data including:\n\n"
                        "• Personal Information\n"
                        "• Daily Journal Entries\n"
                        "• Mood Updates\n"
                        "• Feedback and Settings\n\n"
                        "This action cannot be undone.",
                  ),
                  const SizedBox(height: 15),
                  Text(
                    countdown > 0
                        ? "Please wait $countdown seconds before confirming..."
                        : "You can now confirm deletion.",
                    style: TextStyle(
                      color: countdown > 0 ? Colors.redAccent : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: countdown > 0
                      ? null
                      : () {
                    confirmed = true;
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red,
                  ),
                  child: const Text("Delete Account"),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed) {
      await _reauthenticateAndDeleteUser();
    }
  }

  Future<void> _reauthenticateAndDeleteUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final firestore = FirebaseFirestore.instance;
      if (user == null) return;

      // 🔹 REAUTHENTICATE
      final providerData = user.providerData.first;
      if (providerData.providerId == 'password') {
        String? email = user.email;
        String? password;

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            final TextEditingController passController = TextEditingController();
            return AlertDialog(
              title: const Text("Reauthenticate"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Please re-enter your password for $email to continue."),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Password",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(context, passController.text),
                  child: const Text("Confirm"),
                ),
              ],
            );
          },
        ).then((value) => password = value);

        if (password == null || password!.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("❌ Reauthentication canceled")),
          );
          return;
        }

        final credential = EmailAuthProvider.credential(
          email: email!,
          password: password!,
        );
        await user.reauthenticateWithCredential(credential);
      } else if (providerData.providerId == 'google.com') {
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth?.accessToken,
          idToken: googleAuth?.idToken,
        );
        await user.reauthenticateWithCredential(credential);
      }

      // 🔹 DELETE ALL DATA CONNECTED TO USER
      final uid = user.uid;

      // Delete user document in "users" collection
      final userDoc = await firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        await firestore.collection('users').doc(uid).delete();
      }

      // 🔹 (Optional) Delete other related collections (if you have them)
      // Example: journals, moods, feedbacks, etc.
      final relatedCollections = ['journals', 'moods', 'feedbacks'];
      for (final col in relatedCollections) {
        final snapshots = await firestore
            .collection(col)
            .where('userId', isEqualTo: uid)
            .get();
        for (final doc in snapshots.docs) {
          await firestore.collection(col).doc(doc.id).delete();
        }
      }

      // 🔹 DELETE AUTH ACCOUNT
      await user.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
            Text("✅ Your account and all data were deleted successfully."),
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error deleting account: $e")),
      );
    }
  }


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
                _buildAnimatedCard("Listen to Music", "assets/images/music.png", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MusicScreen(username: widget.username)),
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

  // ---------- HENEУRO (AI) ----------
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
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text("Logout"),
                content: const Text("Are you sure you want to logout?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                      );
                    },
                    child: const Text("Logout", style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          } else if (isDelete) {
            _confirmDeleteAccount();
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
