import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService instance = NotificationService._();

  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _timerNotificationId = 0;
  static const String _channelId = 'goaly_timer';
  static const String _channelName = 'Timer Notifications';
  static const String _channelDescription =
      'Notifications when your Pomodoro timer completes';

  /// Initialize the notification plugin and request permissions
  Future<void> init() async {
    // Initialize timezone
    tz_data.initializeTimeZones();

    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create Android notification channel
    await _createAndroidChannel();

    // Request permissions (Android 13+)
    await _requestPermissions();
  }

  Future<void> _createAndroidChannel() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _requestPermissions() async {
    // Android 13+ permission request
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // iOS permission request (handled by DarwinInitializationSettings but can be explicit)
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  void _onNotificationTapped(NotificationResponse response) {
    // App will be brought to foreground automatically
    // Additional handling can be added here if needed
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Schedule a notification for when the timer ends
  Future<void> scheduleTimerNotification({
    required DateTime endTime,
    required String title,
    required String body,
  }) async {
    // Cancel any existing timer notification first
    await cancelTimerNotification();

    // Don't schedule if end time is in the past
    if (endTime.isBefore(DateTime.now())) {
      return;
    }

    final scheduledTime = tz.TZDateTime.from(endTime, tz.local);

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      _timerNotificationId,
      title,
      body,
      scheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    debugPrint('Scheduled notification for $endTime');
  }

  /// Cancel any pending timer notification
  Future<void> cancelTimerNotification() async {
    await _plugin.cancel(_timerNotificationId);
    debugPrint('Cancelled timer notification');
  }
}
