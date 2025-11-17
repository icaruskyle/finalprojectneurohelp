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

  /// Initialize all notifications
  Future<void> initNotifications() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidInit =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initSettings =
    InitializationSettings(android: androidInit, iOS: iosInit);

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint("🔔 Notification tapped: ${response.payload}");
      },
    );

    await _initializeFirebaseMessaging();
  }

  /// Firebase Messaging Setup
  Future<void> _initializeFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    if (Platform.isIOS) {
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        showNotification(
          title: message.notification!.title ?? "NeuroHelp",
          body: message.notification!.body ?? "You have a new alert",
        );
      }
    });

    final token = await messaging.getToken();
    debugPrint("📱 Device FCM Token: $token");
  }

  /// Show Immediate Notification
  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'neurohelp_channel',
      'NeuroHelp Notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const platformDetails = NotificationDetails(android: androidDetails);

    // Use a quasi-unique id based on current time to avoid collisions
    final int id = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
      payload: "neurohelp_payload",
    );
  }

  /// Schedule daily notification at user-selected time
  Future<void> scheduleDailyNotification({
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    if (!notificationsEnabled) return;

    await cancelDailyNotification();

    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduleDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduleDate.isBefore(now)) {
      scheduleDate = scheduleDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'neurohelp_daily',
      'Daily Reminder',
      importance: Importance.high,
      priority: Priority.high,
    );

    const platformDetails = NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      100, // Daily Notification ID
      title,
      body,
      scheduleDate,
      platformDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    debugPrint("⏰ Daily notification scheduled at $scheduleDate");
  }

  /// Schedule hourly mood notification (repeats every hour)
  ///
  /// NOTE:
  /// - flutter_local_notifications does not provide a `DateTimeComponents` value
  ///   that repeats *every hour* via zonedSchedule. For hourly repeats we use
  ///   `periodicallyShow(RepeatInterval.hourly)`, which starts shortly after
  ///   calling this function (it does not schedule to start exactly at the
  ///   next full hour). If you need "start at next full hour" behavior you'll
  ///   need a background scheduling plugin (e.g., workmanager) or a combination
  ///   of a one-shot zonedSchedule + periodic scheduling via platform-specific code.
  Future<void> scheduleHourlyMoodNotification() async {
    if (!notificationsEnabled) return;

    await cancelHourlyNotification();

    const androidDetails = AndroidNotificationDetails(
      'neurohelp_hourly',
      'Hourly Mood Check',
      importance: Importance.high,
      priority: Priority.high,
    );

    const platformDetails = NotificationDetails(android: androidDetails);

    // Use periodicallyShow for hourly repeats
    await _flutterLocalNotificationsPlugin.periodicallyShow(
      200, // Hourly Notification ID
      "How's your mood?",
      "Please update your mood for this hour.",
      RepeatInterval.hourly,
      platformDetails,
      androidAllowWhileIdle: true,
      payload: "neurohelp_hourly",
    );

    debugPrint("⏳ Hourly mood check scheduled (RepeatInterval.hourly)");
  }

  /// Cancel ONLY daily notifications
  Future<void> cancelDailyNotification() async {
    await _flutterLocalNotificationsPlugin.cancel(100);
    debugPrint("🗑️ Daily notification canceled (id:100)");
  }

  /// Cancel ONLY hourly notifications
  Future<void> cancelHourlyNotification() async {
    await _flutterLocalNotificationsPlugin.cancel(200);
    debugPrint("🗑️ Hourly notification canceled (id:200)");
  }

  /// Cancel ALL notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    debugPrint("🚫 ALL notifications cancelled");
  }
}
