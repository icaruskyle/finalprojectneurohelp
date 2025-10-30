import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../notification_service.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  bool _notificationsEnabled = true;
  TimeOfDay _dailyTime = const TimeOfDay(hour: 9, minute: 0); // default 9:00 AM

  final NotificationService _notificationService = NotificationService();

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

      _notificationService.notificationsEnabled = _notificationsEnabled;

      if (_notificationsEnabled) {
        _scheduleDailyNotification();
      } else {
        _notificationService.cancelAllNotifications();
      }
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = value;
      _notificationService.notificationsEnabled = value;
    });
    await prefs.setBool('notificationsEnabled', value);

    if (value) {
      _scheduleDailyNotification();
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
      setState(() {
        _dailyTime = picked;
      });
      await prefs.setInt('dailyHour', picked.hour);
      await prefs.setInt('dailyMinute', picked.minute);

      if (_notificationsEnabled) {
        _scheduleDailyNotification();
      }
    }
  }

  void _scheduleDailyNotification() {
    _notificationService.scheduleDailyNotification(
      title: 'NeuroHelp Daily Reminder 💜',
      body: 'Take a short break and check your mental health today.',
      time: _dailyTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Account Settings"),
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
              // 🔔 Notifications toggle
              SwitchListTile(
                secondary: const Icon(Icons.notifications, color: Colors.deepPurple),
                title: const Text("Notifications"),
                subtitle: Text(
                  _notificationsEnabled
                      ? "Daily reminder at ${_dailyTime.format(context)}"
                      : "Notifications are off",
                ),
                value: _notificationsEnabled,
                onChanged: _toggleNotifications,
              ),
              if (_notificationsEnabled)
                ListTile(
                  leading: const Icon(Icons.access_time, color: Colors.deepPurple),
                  title: const Text("Set Daily Reminder Time"),
                  subtitle: Text(_dailyTime.format(context)),
                  trailing: const Icon(Icons.edit),
                  onTap: _pickTime,
                ),

              const Divider(),

              // 🔒 Security / 2FA
              const ListTile(
                leading: Icon(Icons.security, color: Colors.deepPurple),
                title: Text("Security"),
                subtitle: Text("Two-factor authentication and login alerts"),
                trailing: Icon(Icons.arrow_forward_ios),
              ),

              const Divider(),

              // 🌐 Language
              const ListTile(
                leading: Icon(Icons.language, color: Colors.deepPurple),
                title: Text("Language"),
                subtitle: Text("Change app language"),
                trailing: Icon(Icons.arrow_forward_ios),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
