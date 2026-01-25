import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
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
    // Initialize timezone database and detect device timezone
    tz_data.initializeTimeZones();
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    final tzName = tzInfo.identifier;
    tz.setLocalLocation(tz.getLocation(tzName));
    debugPrint('NotificationService: Timezone set to $tzName');

    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // macOS settings (uses same Darwin settings as iOS)
    const macOSSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: macOSSettings,
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
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      // Android 13+ notification permission
      final notifGranted = await android.requestNotificationsPermission();
      debugPrint('NotificationService: Android notification permission: $notifGranted');

      // Check exact alarm permission (Android 12+)
      final exactAlarmGranted = await android.canScheduleExactNotifications();
      debugPrint('NotificationService: Android exact alarm permission: $exactAlarmGranted');

      if (exactAlarmGranted != true) {
        debugPrint('NotificationService: Requesting exact alarm permission...');
        await android.requestExactAlarmsPermission();
      }
    }

    // iOS permission request
    final iosGranted = await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    debugPrint('NotificationService: iOS permission granted: $iosGranted');
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
    // Note: Don't cancel existing notification - scheduling with same ID replaces it,
    // and cancelling here causes a race condition where the notification never fires

    // Don't schedule if end time is in the past
    if (endTime.isBefore(DateTime.now())) {
      debugPrint('NotificationService: Not scheduling - end time is in past');
      return;
    }

    // Check if we can schedule exact notifications on Android
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final canSchedule = await android.canScheduleExactNotifications();
      debugPrint('NotificationService: Can schedule exact: $canSchedule');
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
      sound: 'notification.wav',
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
      androidScheduleMode: AndroidScheduleMode.alarmClock,
    );

    debugPrint('NotificationService: Scheduled notification for $endTime (tz: $scheduledTime)');
  }

  /// Cancel any pending timer notification
  Future<void> cancelTimerNotification() async {
    await _plugin.cancel(_timerNotificationId);
    debugPrint('Cancelled timer notification');
  }
}
