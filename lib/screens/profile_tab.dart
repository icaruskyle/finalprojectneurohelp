import 'package:flutter/material.dart';
import 'package:projects/screens/login_screen.dart';
import 'personal_info_screen.dart';
import 'account_settings_screen.dart';
import 'data_privacy_screen.dart';
import 'change_password_screen.dart';
import 'terms_conditions_screen.dart';
import 'feedback_screen.dart';
import 'account_delete.dart';

class ProfileTab extends StatelessWidget {
  final String username;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const ProfileTab({
    super.key,
    required this.username,
    required this.isDarkMode,
    required this.onToggleTheme
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = isDarkMode ? Colors.deepPurpleAccent : Colors.deepPurple;
    final Color textPrimary = isDarkMode ? Colors.white : Colors.deepPurple.shade900;
    final Color cardColor = isDarkMode ? Colors.grey[850]! : Colors.white;
    final Color background = isDarkMode ? Colors.black : Colors.white;

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
            child: Text(
              username,
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
