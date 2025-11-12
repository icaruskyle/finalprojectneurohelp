import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  bool notificationsEnabled = true;

  /// Initialize notifications and Firebase Messaging
  Future<void> initNotifications() async {
    // Initialize timezone
    tz.initializeTimeZones();

    // Android initialization
    const AndroidInitializationSettings androidInitSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const DarwinInitializationSettings iosInitSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings =
    InitializationSettings(android: androidInitSettings, iOS: iosInitSettings);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked: ${response.payload}');
      },
    );

    // Setup Firebase Messaging
    await _initializeFirebaseMessaging();
  }

  Future<void> _initializeFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Only request permission on iOS
    if (Platform.isIOS) {
      await messaging.requestPermission(alert: true, badge: true, sound: true);
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("📩 FCM Message Received: ${message.notification?.title}");

      if (message.notification != null) {
        showNotification(
          title: message.notification!.title ?? 'NeuroHelp',
          body: message.notification!.body ?? 'You have a new message.',
        );
      }
    });

    // Get device token (store in Firestore if needed)
    final token = await messaging.getToken();
    debugPrint("🔑 Firebase Messaging Token: $token");
  }

  /// Show immediate notification
  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'neurohelp_channel',
      'NeuroHelp Notifications',
      channelDescription: 'Notifications for NeuroHelp reminders and alerts',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformDetails,
      payload: 'neurohelp_payload',
    );
  }

  /// Schedule daily notification at a specific TimeOfDay
  Future<void> scheduleDailyNotification({
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    if (!notificationsEnabled) return;

    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If time already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'neurohelp_channel_daily',
      'Daily NeuroHelp Notifications',
      channelDescription: 'Daily reminders for NeuroHelp users',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      1,
      title,
      body,
      scheduledDate,
      platformDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    debugPrint("✅ Notification scheduled for: $scheduledDate");
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    debugPrint("🚫 All notifications canceled");
  }
}