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
import 'package:firebase_auth/firebase_auth.dart';
import 'welcome_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfileTab extends StatefulWidget {
  final String username;
  final bool isDarkMode;
  final Function(bool) onToggleTheme;

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
  File? _pickedImage;

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

  void _showAvatarPicker(BuildContext context) {
    final avatarPaths = List.generate(
      30,
          (i) => 'assets/avatars/avatar_${i + 1}.png',
    );

    String? tempSelectedAvatar = _selectedAvatar;
    File? tempPickedImage = _pickedImage;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Choose Your Avatar'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final picked = await ImagePicker()
                          .pickImage(source: ImageSource.gallery);

                      if (picked != null) {
                        setStateDialog(() {
                          tempPickedImage = File(picked.path);
                          tempSelectedAvatar = null;
                        });
                      }
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Upload Photo"),
                  ),
                  const SizedBox(height: 15),

                  Expanded(
                    child: GridView.builder(
                      itemCount: avatarPaths.length,
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                      ),
                      itemBuilder: (context, index) {
                        final avatar = avatarPaths[index];
                        final isSelected = tempSelectedAvatar == avatar;

                        return GestureDetector(
                          onTap: () {
                            setStateDialog(() {
                              tempSelectedAvatar = avatar;
                              tempPickedImage = null;
                            });
                          },
                          child: Stack(
                            children: [
                              ClipOval(
                                child: Image.asset(
                                  avatar,
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              if (isSelected)
                                Positioned(
                                  top: 5,
                                  right: 5,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.green,
                                    ),
                                    padding: const EdgeInsets.all(5),
                                    child: const Icon(
                                      Icons.check,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();

                  if (tempPickedImage != null) {
                    await prefs.setString('selectedAvatar', tempPickedImage!.path);
                    setState(() {
                      _pickedImage = tempPickedImage;
                      _selectedAvatar = tempPickedImage!.path;
                    });
                  } else if (tempSelectedAvatar != null) {
                    await prefs.setString('selectedAvatar', tempSelectedAvatar!);
                    setState(() {
                      _selectedAvatar = tempSelectedAvatar;
                      _pickedImage = null;
                    });
                  }

                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white, // text/icon color
                ),
                child: const Text("Save"),
              )

            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color accent =
    widget.isDarkMode ? Colors.deepPurpleAccent : Colors.deepPurple;
    final Color textPrimary =
    widget.isDarkMode ? Colors.white : Colors.deepPurple.shade900;
    final Color cardColor =
    widget.isDarkMode ? Colors.grey[850]! : Colors.white;
    final Color background =
    widget.isDarkMode ? Colors.black : Colors.white;

    return Container(
      color: background,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: GestureDetector(
              onTap: () => _showAvatarPicker(context),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: accent,
                    backgroundImage: _pickedImage != null
                        ? FileImage(_pickedImage!)
                        : (_selectedAvatar != null
                        ? (_selectedAvatar!.contains("assets")
                        ? AssetImage(_selectedAvatar!)
                        : FileImage(File(_selectedAvatar!)))
                        : null) as ImageProvider?,
                    child: (_selectedAvatar == null && _pickedImage == null)
                        ? const Icon(Icons.person,
                        size: 60, color: Colors.white)
                        : null,
                  ),

                  // + Badge icon
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.deepPurple,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 15),

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

          const SizedBox(height: 20),

          _buildProfileTile(
            context,
            Icons.info,
            "Personal Information",
            const PersonalInfoScreen(),
            cardColor,
            textPrimary,
            accent,
          ),
          _buildProfileTile(
            context,
            Icons.settings,
            "Account Settings",
            const AccountSettingsScreen(),
            cardColor,
            textPrimary,
            accent,
          ),
          _buildProfileTile(
            context,
            Icons.privacy_tip,
            "Data Privacy",
            const DataPrivacyScreen(),
            cardColor,
            textPrimary,
            accent,
          ),
          _buildProfileTile(
            context,
            Icons.lock,
            "Change Password",
            const ChangePasswordScreen(),
            cardColor,
            textPrimary,
            accent,
          ),
          _buildProfileTile(
            context,
            Icons.article,
            "Terms & Conditions",
            const TermsConditionsScreen(),
            cardColor,
            textPrimary,
            accent,
          ),
          _buildProfileTile(
            context,
            Icons.feedback,
            "Feedback",
            const FeedbackScreen(),
            cardColor,
            textPrimary,
            accent,
          ),
          _buildProfileTile(
            context,
            Icons.logout,
            "Logout",
            null,
            cardColor,
            textPrimary,
            accent,
            isLogout: true,
          ),
          _buildProfileTile(
            context,
            Icons.delete_forever,
            "Delete Account",
            null,
            cardColor,
            textPrimary,
            accent,
            isDelete: true,
          ),
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
                content:
                const Text("Are you sure you want to logout?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();

                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('username');

                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (_) => const WelcomeScreen()),
                            (route) => false,
                      );
                    },
                    child: const Text("Logout",
                        style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          } else if (isDelete) {
            AccountDeleteHelper.confirmAndDeleteAccount(context);
          } else if (screen != null) {
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => screen));
          }
        },
      ),
    );
  }
}
