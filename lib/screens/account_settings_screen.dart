import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../notification_service.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  bool _notificationsEnabled = true;
  TimeOfDay _dailyTime = const TimeOfDay(hour: 9, minute: 0);
  bool _is2FAEnabled = false;
  String _selectedLanguage = 'English';

  final NotificationService _notificationService = NotificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;

      int hour = prefs.getInt('dailyHour') ?? 9;
      int minute = prefs.getInt('dailyMinute') ?? 0;
      _dailyTime = TimeOfDay(hour: hour, minute: minute);

      _is2FAEnabled = prefs.getBool('is2FAEnabled') ?? false;
      _selectedLanguage = prefs.getString('language') ?? 'English';

      _notificationService.notificationsEnabled = _notificationsEnabled;
    });

    if (_notificationsEnabled) {
      _scheduleAllNotifications();
    } else {
      _notificationService.cancelAllNotifications();
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _dailyTime,
    );

    if (picked != null && picked != _dailyTime) {
      final prefs = await SharedPreferences.getInstance();

      setState(() => _dailyTime = picked);

      await prefs.setInt('dailyHour', picked.hour);
      await prefs.setInt('dailyMinute', picked.minute);

      if (_notificationsEnabled) {
        _scheduleAllNotifications();
      }
    }
  }

  void _scheduleAllNotifications() {
    // DAILY
    _notificationService.scheduleDailyNotification(
      title: _selectedLanguage == 'Filipino'
          ? '💜 Paalala mula sa NeuroHelp'
          : 'NeuroHelp Daily Reminder 💜',
      body: _selectedLanguage == 'Filipino'
          ? 'Magpahinga at suriin ang iyong kalusugan sa pag-iisip.'
          : 'Take a moment to check your mental health today.',
      time: _dailyTime,
    );

    // HOURLY MOOD UPDATE
    _notificationService.scheduleHourlyMoodNotification();
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _notificationsEnabled = value;
      _notificationService.notificationsEnabled = value;
    });

    await prefs.setBool('notificationsEnabled', value);

    if (value) {
      // Schedule notifications
      _scheduleAllNotifications();

      // Instant local notification confirming activation
      _notificationService.showNotification(
        title: "🔔 NeuroHelp Notifications Enabled",
        body: "We will remind you hourly with mood updates and daily reminders.",
      );
    } else {
      _notificationService.cancelAllNotifications();
    }
  }

  Future<void> _changeLanguage() async {
    final prefs = await SharedPreferences.getInstance();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Select Language / Piliin ang Wika"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('English'),
                value: 'English',
                groupValue: _selectedLanguage,
                onChanged: (value) {
                  setState(() => _selectedLanguage = value!);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: const Text('Filipino'),
                value: 'Filipino',
                groupValue: _selectedLanguage,
                onChanged: (value) {
                  setState(() => _selectedLanguage = value!);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );

    await prefs.setString('language', _selectedLanguage);
  }

  Future<void> _toggle2FA(bool enable) async {
    final prefs = await SharedPreferences.getInstance();
    final user = _auth.currentUser;
    if (user == null) return;

    if (enable) {
      if (!user.emailVerified) {
        await user.sendEmailVerification();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedLanguage == 'Filipino'
                  ? '📧 I-verify muna ang iyong email bago paganahin ang 2FA.'
                  : '📧 Verify your email first before enabling 2FA.',
            ),
          ),
        );
      } else {
        setState(() => _is2FAEnabled = true);
        await prefs.setBool('is2FAEnabled', true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_selectedLanguage == 'Filipino'
                ? '✅ Email 2FA pinagana!'
                : '✅ Email 2FA enabled!'),
          ),
        );
      }
    } else {
      setState(() => _is2FAEnabled = false);
      await prefs.setBool('is2FAEnabled', false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_selectedLanguage == 'Filipino'
              ? '❌ Email 2FA pinatay.'
              : '❌ Email 2FA disabled.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedLanguage == 'Filipino'
              ? "Mga Setting ng Account"
              : "Account Settings",
        ),
        backgroundColor: Colors.purple,
      ),
      body: SingleChildScrollView(
        child: Card(
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          child: Column(
            children: [
              // 🔔 NOTIFICATIONS
              SwitchListTile(
                secondary: const Icon(Icons.notifications, color: Colors.deepPurple),
                title: Text(
                  _selectedLanguage == 'Filipino'
                      ? "Mga Abiso"
                      : "Notifications",
                ),
                subtitle: Text(
                  _notificationsEnabled
                      ? (_selectedLanguage == 'Filipino'
                      ? "Araw-araw tuwing ${_dailyTime.format(context)}"
                      : "Daily at ${_dailyTime.format(context)}")
                      : (_selectedLanguage == 'Filipino'
                      ? "Naka-off"
                      : "Disabled"),
                ),
                value: _notificationsEnabled,
                onChanged: _toggleNotifications,
              ),

              if (_notificationsEnabled)
                ListTile(
                  leading: const Icon(Icons.access_time, color: Colors.deepPurple),
                  title: Text(
                    _selectedLanguage == 'Filipino'
                        ? "Itakda ang Oras"
                        : "Set Reminder Time",
                  ),
                  subtitle: Text(_dailyTime.format(context)),
                  trailing: const Icon(Icons.edit),
                  onTap: _pickTime,
                ),

              const Divider(),

              // 🔒 2FA
              SwitchListTile(
                secondary: const Icon(Icons.security, color: Colors.deepPurple),
                title: Text(
                  _selectedLanguage == 'Filipino'
                      ? "Two-Factor Authentication (2FA)"
                      : "Two-Factor Authentication (2FA)",
                ),
                value: _is2FAEnabled,
                onChanged: _toggle2FA,
              ),

              const Divider(),

              // 🌐 Language
              ListTile(
                leading: const Icon(Icons.language, color: Colors.deepPurple),
                title: Text(
                  _selectedLanguage == 'Filipino'
                      ? "Wika"
                      : "Language",
                ),
                subtitle: Text(
                  _selectedLanguage == 'Filipino'
                      ? "Baguhin ang wika ng app"
                      : "Change app language",
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _changeLanguage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
