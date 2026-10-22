import 'dart:io' show Platform;
import 'dart:ui' show Color;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../database/hive_helper.dart';
import '../models/hive_models/routine_entry.dart';

class RoutineAlarmService {
  RoutineAlarmService._();

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  // ── Channel 1: সাধারণ নোটিফিকেশন (মোবাইলের ডিফল্ট নোটিফিকেশন টোন বাজবে) ───────
  static const String notificationChannelId = 'maktaba_notifications_v2';
  static const String notificationChannelName = 'বিজ্ঞপ্তি ও নোটিফিকেশন';
  static const String notificationChannelDesc =
      'নতুন কিতাব রিকোয়েস্ট ও অনুমোদন সংক্রান্ত নোটিফিকেশন';

  // ── Channel 2: রুটিন ও রিমাইন্ডার এলার্ম (এলার্ম টোন বাজবে) ───────────────────
  static const String reminderAlarmChannelId = 'maktaba_reminder_alarm_v5';
  static const String reminderAlarmChannelName = 'ক্লাস রুটিন ও রিমাইন্ডার এলার্ম';
  static const String reminderAlarmChannelDesc =
      'মাদরাসার ক্লাস ও মুতালায়া রিমাইন্ডারের জন্য এলার্ম';

  // 6.6 seconds pattern: 1s vibrate, 400ms pause x 5 times (matches routine_alarm sound duration)
  static final Int64List _alarmVibrationPattern = Int64List.fromList([
    0,
    1000,
    400,
    1000,
    400,
    1000,
    400,
    1000,
    400,
    1000,
  ]);

  /// Initialize local notifications and timezone
  static Future<void> initialize() async {
    if (kIsWeb) return;
    if (_isInitialized) return;

    try {
      // 1. Initialize Timezones
      tz.initializeTimeZones();
      try {
        // Default to Asia/Dhaka or local
        tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));
      } catch (_) {
        // Fallback to UTC if timezone name not found
      }

      // 2. Android Initialization Settings
      const androidSettings =
          AndroidInitializationSettings('@drawable/ic_notification');

      const initSettings = InitializationSettings(
        android: androidSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('Notification clicked: ${details.payload}');
        },
      );

      // 3. Create Notification Channels on Android
      if (!kIsWeb && Platform.isAndroid) {
        final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

        if (androidPlugin != null) {
          // Delete old legacy channels so Android cleans up old mute/mismatched configurations
          try {
            await androidPlugin.deleteNotificationChannel('routine_alarm_channel_v4');
            await androidPlugin.deleteNotificationChannel('routine_alarm_channel_v3');
            await androidPlugin.deleteNotificationChannel('routine_alarm_channel_v2');
            await androidPlugin.deleteNotificationChannel('routine_alarm_channel');
          } catch (_) {}

          // Channel 1: General Notifications (মোবাইলে ব্যবহারকারীর যে নোটিফিকেশন টোন সেট করা, সেটিই বাজবে)
          const generalChannel = AndroidNotificationChannel(
            notificationChannelId,
            notificationChannelName,
            description: notificationChannelDesc,
            importance: Importance.max,
            playSound: true,
            // sound: null means Android will use Settings.System.DEFAULT_NOTIFICATION_URI
            enableVibration: true,
            enableLights: true,
            audioAttributesUsage: AudioAttributesUsage.notification,
          );
          await androidPlugin.createNotificationChannel(generalChannel);

          // Channel 2: Reminder & Routine Alarm (এলার্ম টোন বাজবে)
          final reminderChannel = AndroidNotificationChannel(
            reminderAlarmChannelId,
            reminderAlarmChannelName,
            description: reminderAlarmChannelDesc,
            importance: Importance.max,
            playSound: true,
            sound: const RawResourceAndroidNotificationSound('routine_alarm'),
            enableVibration: true,
            vibrationPattern: _alarmVibrationPattern,
            enableLights: true,
            audioAttributesUsage: AudioAttributesUsage.alarm,
          );
          await androidPlugin.createNotificationChannel(reminderChannel);

          // Request permissions for Android 13+ and exact alarms
          await androidPlugin.requestNotificationsPermission();
          await androidPlugin.requestExactAlarmsPermission();
        }
      }

      _isInitialized = true;
      debugPrint('✅ RoutineAlarmService initialized successfully.');
    } catch (e) {
      debugPrint('⚠️ Error initializing RoutineAlarmService: $e');
    }
  }

  /// Generates a unique 32-bit positive integer ID for notification
  static int _generateNotificationId(String routineId, int dayOfWeek, bool isNightBefore) {
    final base = (routineId.hashCode & 0x03FFFFFF);
    final typeOffset = isNightBefore ? 50 : 0;
    return (base * 100) + (dayOfWeek * 10) + typeOffset;
  }

  /// Schedule all alarms for a single routine entry (Reminders - plays alarm tone)
  static Future<void> scheduleRoutine(RoutineEntry routine) async {
    if (kIsWeb) return;
    if (!_isInitialized) await initialize();

    try {
      // First cancel existing alarms for this routine
      await cancelRoutine(routine.id);

      // Check if routine has any reminder configured
      final hasPreClassAlarm = routine.reminderMinutes != null && routine.reminderMinutes! > 0;
      final hasNightBefore = routine.nightBeforeAlarm;

      if (!hasPreClassAlarm && !hasNightBefore) {
        return;
      }

      final startParts = routine.startTime.split(':');
      if (startParts.length < 2) return;
      final startHour = int.tryParse(startParts[0]) ?? 8;
      final startMinute = int.tryParse(startParts[1]) ?? 0;

      for (final dayOfWeek in routine.daysOfWeek) {
        // 1. Schedule Pre-Class Alarm (e.g. 5, 10, 15, 30 min before class)
        if (hasPreClassAlarm) {
          final reminderMins = routine.reminderMinutes!;
          final classTotalMinutes = (startHour * 60) + startMinute;
          var alarmTotalMinutes = classTotalMinutes - reminderMins;
          var alarmDay = dayOfWeek;

          if (alarmTotalMinutes < 0) {
            alarmTotalMinutes += 24 * 60;
            alarmDay = (dayOfWeek == 1) ? 7 : dayOfWeek - 1;
          }

          final alarmHour = alarmTotalMinutes ~/ 60;
          final alarmMinute = alarmTotalMinutes % 60;

          final scheduledDate = _nextInstanceOfDayAndTime(alarmDay, alarmHour, alarmMinute);
          final notifId = _generateNotificationId(routine.id, dayOfWeek, false);

          final roomText = (routine.roomNumber != null && routine.roomNumber!.trim().isNotEmpty)
              ? ' (রুম: ${routine.roomNumber})'
              : '';

          final title = '🔔 ক্লাসের প্রস্তুতি: ${routine.subjectName}';
          final body = 'আপনার ${routine.className} শ্রেণীতে "${routine.subjectName}" কিতাবের ক্লাস শুরু হতে $reminderMins মিনিট বাকি$roomText।';

          await _notifications.zonedSchedule(
            notifId,
            title,
            body,
            scheduledDate,
            NotificationDetails(
              android: AndroidNotificationDetails(
                reminderAlarmChannelId,
                reminderAlarmChannelName,
                channelDescription: reminderAlarmChannelDesc,
                importance: Importance.max,
                priority: Priority.max,
                playSound: true,
                sound: const RawResourceAndroidNotificationSound('routine_alarm'),
                icon: 'ic_notification',
                largeIcon: const DrawableResourceAndroidBitmap(
                    '@drawable/ic_notification_large'),
                color: const Color(0xFF1F9E5C),
                enableVibration: true,
                vibrationPattern: _alarmVibrationPattern,
                fullScreenIntent: true,
                category: AndroidNotificationCategory.alarm,
                audioAttributesUsage: AudioAttributesUsage.alarm,
                styleInformation: BigTextStyleInformation(body, contentTitle: title),
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );

          debugPrint('⏰ Scheduled pre-class alarm for ${routine.subjectName} on day $alarmDay at $alarmHour:$alarmMinute (ID: $notifId)');
        }

        // 2. Schedule Night-Before Alarm (e.g. at 21:00 on the day before class)
        if (hasNightBefore) {
          final nightTimeStr = routine.nightBeforeAlarmTime ?? '21:00';
          final nightParts = nightTimeStr.split(':');
          final nightHour = int.tryParse(nightParts[0]) ?? 21;
          final nightMinute = (nightParts.length > 1) ? (int.tryParse(nightParts[1]) ?? 0) : 0;

          final nightDay = (dayOfWeek == 1) ? 7 : dayOfWeek - 1;

          final scheduledDate = _nextInstanceOfDayAndTime(nightDay, nightHour, nightMinute);
          final notifId = _generateNotificationId(routine.id, dayOfWeek, true);

          const title = '📖 আগামীকালের মুতালায়া ও প্রস্তুতি';
          final body = 'আগামীকাল ${routine.startTime} টায় ${routine.className} শ্রেণীতে "${routine.subjectName}" কিতাবের দরস আছে, মুতালায়া করুন।';

          await _notifications.zonedSchedule(
            notifId,
            title,
            body,
            scheduledDate,
            NotificationDetails(
              android: AndroidNotificationDetails(
                reminderAlarmChannelId,
                reminderAlarmChannelName,
                channelDescription: reminderAlarmChannelDesc,
                importance: Importance.max,
                priority: Priority.max,
                playSound: true,
                sound: const RawResourceAndroidNotificationSound('routine_alarm'),
                icon: 'ic_notification',
                largeIcon: const DrawableResourceAndroidBitmap(
                    '@drawable/ic_notification_large'),
                color: const Color(0xFF1F9E5C),
                enableVibration: true,
                vibrationPattern: _alarmVibrationPattern,
                fullScreenIntent: true,
                category: AndroidNotificationCategory.alarm,
                audioAttributesUsage: AudioAttributesUsage.alarm,
                styleInformation: BigTextStyleInformation(body, contentTitle: title),
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );

          debugPrint('🌙 Scheduled night-before alarm for ${routine.subjectName} on day $nightDay at $nightHour:$nightMinute (ID: $notifId)');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error scheduling routine alarm: $e');
    }
  }

  /// Cancels all scheduled alarms for a given routine
  static Future<void> cancelRoutine(String routineId) async {
    if (kIsWeb) return;
    try {
      for (int day = 1; day <= 7; day++) {
        final preClassId = _generateNotificationId(routineId, day, false);
        final nightBeforeId = _generateNotificationId(routineId, day, true);
        await _notifications.cancel(preClassId);
        await _notifications.cancel(nightBeforeId);
      }
      debugPrint('🚫 Cancelled alarms for routine ID: $routineId');
    } catch (e) {
      debugPrint('⚠️ Error cancelling routine alarms: $e');
    }
  }

  /// Reschedule alarms for all routines currently saved in Hive
  static Future<void> rescheduleAll() async {
    if (kIsWeb) return;
    if (!_isInitialized) await initialize();

    try {
      await _notifications.cancelAll();
      final routines = HiveHelper.routineBox.values.toList();
      for (final routine in routines) {
        await scheduleRoutine(routine);
      }
      debugPrint('🔄 Rescheduled alarms for ${routines.length} routines.');
    } catch (e) {
      debugPrint('⚠️ Error rescheduling all routines: $e');
    }
  }

  /// Calculates the next occurrence of a specific weekday (1..7) and hour:minute
  static tz.TZDateTime _nextInstanceOfDayAndTime(int dayOfWeek, int hour, int minute) {
    tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    while (scheduledDate.weekday != dayOfWeek || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// Displays notification using the user's mobile notification tone
  /// when an admin approves a teacher's book request.
  static Future<void> showBookApprovedNotification({
    required String bookTitle,
    required String trxId,
  }) async {
    if (kIsWeb) return;
    if (!_isInitialized) await initialize();

    try {
      final notifId = trxId.hashCode.abs() % 100000;
      const title = '✅ কিতাব রিকোয়েস্ট অনুমোদিত হয়েছে!';
      final body =
          'আপনার অনুরোধ করা কিতাব "$bookTitle" অ্যাডমিন অনুমোদন করেছেন। লাইব্রেরি থেকে কিতাবটি সংগ্রহ করুন।';

      await _notifications.show(
        notifId,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            notificationChannelId,
            notificationChannelName,
            channelDescription: notificationChannelDesc,
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            // sound: null ensures the user's mobile notification tone rings!
            icon: 'ic_notification',
            largeIcon: const DrawableResourceAndroidBitmap(
                '@drawable/ic_notification_large'),
            color: const Color(0xFF1F9E5C),
            enableVibration: true,
            enableLights: true,
            audioAttributesUsage: AudioAttributesUsage.notification,
            styleInformation: BigTextStyleInformation(body, contentTitle: title),
          ),
        ),
      );
      debugPrint('🔔 Triggered book approval notification for: $bookTitle (ID: $notifId)');
    } catch (e) {
      debugPrint('⚠️ Error showing book approved notification: $e');
    }
  }

  /// Displays notification using the user's mobile notification tone
  /// when a teacher requests a book (for Admin device).
  static Future<void> showBookRequestedNotification({
    required String teacherName,
    required String bookTitle,
    required String trxId,
  }) async {
    if (kIsWeb) return;
    if (!_isInitialized) await initialize();

    try {
      final notifId = trxId.hashCode.abs() % 100000;
      const title = '🔔 নতুন কিতাব রিকোয়েস্ট এসেছে!';
      final body = '$teacherName "$bookTitle" কিতাবটি নেয়ার জন্য রিকোয়েস্ট পাঠিয়েছেন।';

      await _notifications.show(
        notifId,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            notificationChannelId,
            notificationChannelName,
            channelDescription: notificationChannelDesc,
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            // sound: null ensures the user's mobile notification tone rings!
            icon: 'ic_notification',
            largeIcon: const DrawableResourceAndroidBitmap(
                '@drawable/ic_notification_large'),
            color: const Color(0xFF1F9E5C),
            enableVibration: true,
            enableLights: true,
            audioAttributesUsage: AudioAttributesUsage.notification,
            styleInformation: BigTextStyleInformation(body, contentTitle: title),
          ),
        ),
      );
      debugPrint('🔔 Triggered book requested notification for: $bookTitle (ID: $notifId)');
    } catch (e) {
      debugPrint('⚠️ Error showing book requested notification: $e');
    }
  }

  /// Plays test reminder alarm immediately so the user can test the alarm tone
  static Future<void> testAlarmSound() async {
    if (kIsWeb) return;
    if (!_isInitialized) await initialize();

    try {
      await _notifications.show(
        99999,
        '⏰ ক্লাস রুটিন ও রিমাইন্ডার অ্যালার্ম (টেস্ট)',
        'ক্লাস শুরু অথবা মুতালায়া রিমাইন্ডারে এই অ্যালার্ম টোন বাজবে।',
        NotificationDetails(
          android: AndroidNotificationDetails(
            reminderAlarmChannelId,
            reminderAlarmChannelName,
            channelDescription: reminderAlarmChannelDesc,
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            sound: const RawResourceAndroidNotificationSound('routine_alarm'),
            icon: 'ic_notification',
            largeIcon: const DrawableResourceAndroidBitmap(
                '@drawable/ic_notification_large'),
            color: const Color(0xFF1F9E5C),
            enableVibration: true,
            vibrationPattern: _alarmVibrationPattern,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            audioAttributesUsage: AudioAttributesUsage.alarm,
            styleInformation: const BigTextStyleInformation(
              'ক্লাস শুরু অথবা মুতালায়া রিমাইন্ডারে এই অ্যালার্ম টোন বাজবে।',
              contentTitle: '⏰ ক্লাস রুটিন ও রিমাইন্ডার অ্যালার্ম (টেস্ট)',
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('⚠️ Error testing alarm sound: $e');
    }
  }
}
