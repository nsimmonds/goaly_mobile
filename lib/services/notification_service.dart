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
    if (kDebugMode) {
      debugPrint('NotificationService: Timezone set to $tzName');
    }

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

  Future<bool> _requestPermissions() async {
    bool granted = false;

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      // Android 13+ notification permission
      final notifGranted = await android.requestNotificationsPermission();
      if (kDebugMode) {
        debugPrint('NotificationService: Android notification permission: $notifGranted');
      }

      // Check exact alarm permission (Android 12+)
      final exactAlarmGranted = await android.canScheduleExactNotifications();
      if (kDebugMode) {
        debugPrint('NotificationService: Android exact alarm permission: $exactAlarmGranted');
      }

      if (exactAlarmGranted != true) {
        if (kDebugMode) {
          debugPrint('NotificationService: Requesting exact alarm permission...');
        }
        await android.requestExactAlarmsPermission();
      }

      // Android permission granted if both notification and exact alarm are granted
      granted = (notifGranted ?? false) && (exactAlarmGranted ?? false);
    }

    // iOS permission request
    final ios = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final iosGranted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      if (kDebugMode) {
        debugPrint('NotificationService: iOS permission granted: $iosGranted');
      }
      granted = iosGranted ?? false;
    }

    // macOS permission request
    final macOS = _plugin.resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>();
    if (macOS != null) {
      final macOSGranted = await macOS.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      if (kDebugMode) {
        debugPrint('NotificationService: macOS permission granted: $macOSGranted');
      }
      granted = macOSGranted ?? false;
    }

    return granted;
  }

  /// Check if notification permissions are currently granted
  Future<bool> checkPermissionStatus() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      final notifGranted = await android.areNotificationsEnabled();
      final exactAlarmGranted = await android.canScheduleExactNotifications();
      return (notifGranted ?? false) && (exactAlarmGranted ?? false);
    }

    // iOS check
    final ios = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final settings = await ios.checkPermissions();
      return settings?.isEnabled ?? false;
    }

    // macOS check
    final macOS = _plugin.resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>();
    if (macOS != null) {
      final settings = await macOS.checkPermissions();
      return settings?.isEnabled ?? false;
    }

    // Default to true for platforms without specific checks (e.g., Windows, Linux)
    return true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // App will be brought to foreground automatically
    // Additional handling can be added here if needed
    if (kDebugMode) {
      debugPrint('Notification tapped: ${response.payload}');
    }
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
      if (kDebugMode) {
        debugPrint('NotificationService: Not scheduling - end time is in past');
      }
      return;
    }

    // Check if we can schedule exact notifications on Android
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final canSchedule = await android.canScheduleExactNotifications();
      if (kDebugMode) {
        debugPrint('NotificationService: Can schedule exact: $canSchedule');
      }
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

    if (kDebugMode) {
      debugPrint('NotificationService: Scheduled notification for $endTime (tz: $scheduledTime)');
    }
  }

  /// Cancel any pending timer notification
  Future<void> cancelTimerNotification() async {
    await _plugin.cancel(_timerNotificationId);
    if (kDebugMode) {
      debugPrint('Cancelled timer notification');
    }
  }
}
