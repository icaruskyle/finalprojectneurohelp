import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/personal_info_screen.dart'; // ✅ import your PersonalInfoScreen
import 'notification_service.dart';
import 'dart:async';

// 👇 Top-level background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint("Handling background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 👇 Register Firebase background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 👇 Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initNotifications();

  // 👇 Load saved notification settings
  final prefs = await SharedPreferences.getInstance();
  final notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
  final hour = prefs.getInt('dailyHour') ?? 9;
  final minute = prefs.getInt('dailyMinute') ?? 0;

  notificationService.notificationsEnabled = notificationsEnabled;

  if (notificationsEnabled) {
    // Schedule daily reminder at saved time
    notificationService.scheduleDailyNotification(
      title: 'NeuroHelp Daily Reminder 💜',
      body: 'Take a short break and check your mental health today.',
      time: TimeOfDay(hour: hour, minute: minute),
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NeuroHelp',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/personal-info': (context) => const PersonalInfoScreen(), // ✅ add route
      },
    );
  }
}
