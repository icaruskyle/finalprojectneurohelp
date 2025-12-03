import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projects/screens/login_screen.dart';
import 'personal_info_screen.dart';
import 'account_settings_screen.dart';
import 'data_privacy_screen.dart';
import 'change_password_screen.dart';
import 'terms_conditions_screen.dart';
import 'feedback_screen.dart';
import 'account_delete.dart';

class ProfileTab extends StatefulWidget {
  final String username;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const ProfileTab({
    super.key,
    required this.username,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  String? _selectedAvatar;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedAvatar = prefs.getString('selectedAvatar');
    });
  }

  Future<void> _selectAvatar(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedAvatar', path);
    setState(() => _selectedAvatar = path);
    Navigator.pop(context);
  }

  void _showAvatarPicker(BuildContext context) {
    final avatarPaths = [
      'assets/avatars/avatar_1.png',
      'assets/avatars/avatar_2.png',
      'assets/avatars/avatar_3.png',
      'assets/avatars/avatar_4.png',
      'assets/avatars/avatar_5.png',
      'assets/avatars/avatar_6.png',
      'assets/avatars/avatar_7.png',
      'assets/avatars/avatar_8.png',
      'assets/avatars/avatar_9.png',
      'assets/avatars/avatar_10.png',
      'assets/avatars/avatar_11.png',
      'assets/avatars/avatar_12.png',
      'assets/avatars/avatar_13.png',
      'assets/avatars/avatar_14.png',
      'assets/avatars/avatar_15.png',
      'assets/avatars/avatar_16.png',
      'assets/avatars/avatar_17.png',
      'assets/avatars/avatar_18.png',
      'assets/avatars/avatar_19.png',
      'assets/avatars/avatar_20.png',
      'assets/avatars/avatar_21.png',
      'assets/avatars/avatar_22.png',
      'assets/avatars/avatar_23.png',
      'assets/avatars/avatar_24.png',
      'assets/avatars/avatar_25.png',
      'assets/avatars/avatar_26.png',
      'assets/avatars/avatar_27.png',
      'assets/avatars/avatar_28.png',
      'assets/avatars/avatar_29.png',
      'assets/avatars/avatar_30.png',
    ];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Choose Your Avatar'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            itemCount: avatarPaths.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final avatar = avatarPaths[index];
              return GestureDetector(
                onTap: () => _selectAvatar(avatar),
                child: ClipOval(
                  child: Image.asset(
                    avatar,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover, // FIX: No more zoom
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = widget.isDarkMode ? Colors.deepPurpleAccent : Colors.deepPurple;
    final Color textPrimary = widget.isDarkMode ? Colors.white : Colors.deepPurple.shade900;
    final Color cardColor = widget.isDarkMode ? Colors.grey[850]! : Colors.white;
    final Color background = widget.isDarkMode ? Colors.black : Colors.white;

    return Container(
      color: background,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GestureDetector(
            onTap: () => _showAvatarPicker(context),
            child: CircleAvatar(
              radius: 55,
              backgroundColor: accent,
              child: _selectedAvatar == null
                  ? const Icon(Icons.person, size: 50, color: Colors.white)
                  : ClipOval(
                child: Image.asset(
                  _selectedAvatar!,
                  width: 110,
                  height: 110,
                  fit: BoxFit.cover, // FIX: Clean circular crop
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              widget.username,
              style: TextStyle(
                color: textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildProfileTile(context, Icons.info, "Personal Information",
              const PersonalInfoScreen(), cardColor, textPrimary, accent),
          _buildProfileTile(context, Icons.settings, "Account Settings",
              const AccountSettingsScreen(), cardColor, textPrimary, accent),
          _buildProfileTile(context, Icons.privacy_tip, "Data Privacy",
              const DataPrivacyScreen(), cardColor, textPrimary, accent),
          _buildProfileTile(context, Icons.lock, "Change Password",
              const ChangePasswordScreen(), cardColor, textPrimary, accent),
          _buildProfileTile(context, Icons.article, "Terms & Conditions",
              const TermsConditionsScreen(), cardColor, textPrimary, accent),
          _buildProfileTile(context, Icons.feedback, "Feedback",
              const FeedbackScreen(), cardColor, textPrimary, accent),
          _buildProfileTile(context, Icons.logout, "Logout", null, cardColor,
              textPrimary, accent,
              isLogout: true),
          _buildProfileTile(context, Icons.delete_forever, "Delete Account",
              null, cardColor, textPrimary, accent,
              isDelete: true),
        ],
      ),
    );
  }

  Widget _buildProfileTile(
      BuildContext context,
      IconData icon,
      String title,
      Widget? screen,
      Color cardColor,
      Color textPrimary,
      Color accent, {
        bool isLogout = false,
        bool isDelete = false,
      }) {
    return Card(
      color: cardColor,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDelete ? Colors.redAccent : accent,
          size: 28,
        ),
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
            AccountDeleteHelper.confirmAndDeleteAccount(context);
          } else if (screen != null) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
          }
        },
      ),
    );
  }
}
