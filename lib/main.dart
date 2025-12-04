import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'notification_service.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/personal_info_screen.dart';
import 'screens/dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'screens/theme_notifier.dart'; // NEW: create this file

/// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint("Handling background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase Init
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Background messages
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Notifications
  await NotificationService().initNotifications();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(), // PROVIDER for dark mode
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeNotifier>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NeuroHelp',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
      themeMode: theme.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const AuthWrapper(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
        '/personal-info': (_) => const PersonalInfoScreen(),
        '/dashboard': (_) => DashboardScreen(
          username: FirebaseAuth.instance.currentUser?.displayName ??
              FirebaseAuth.instance.currentUser?.email ??
              "User",
        ),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  User? _user;
  bool _isLoading = true;
  String _username = "User";

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  void _checkCurrentUser() async {
    await Future.delayed(const Duration(seconds: 1)); // simulate loading

    _user = FirebaseAuth.instance.currentUser;

    if (_user != null) {
      final prefs = await SharedPreferences.getInstance();
      _username = prefs.getString('username') ??
          _user!.displayName ??
          _user!.email ??
          "User";
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_user != null) {
      return DashboardScreen(username: _username);
    } else {
      return const WelcomeScreen();
    }
  }
}
