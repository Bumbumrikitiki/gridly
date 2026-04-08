import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:gridly/multitool/project_manager/models/project_models.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationsService {
  LocalNotificationsService._();

  static final LocalNotificationsService instance =
      LocalNotificationsService._();

  static const String _channelId = 'project_manager_recurring_alerts';
  static const String _channelName = 'Alerty cykliczne';
  static const String _channelDescription =
      'Powiadomienia o cyklicznych zadaniach w Mojej budowie';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    tz.initializeTimeZones();
    try {
      final localTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimeZone));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return true;
    await initialize();

    var granted = true;

    final android =
        _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final androidGranted = await android?.requestNotificationsPermission();
    if (androidGranted != null) {
      granted = granted && androidGranted;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
      IOSFlutterLocalNotificationsPlugin
    >();
    final iosGranted = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    if (iosGranted != null) {
      granted = granted && iosGranted;
    }

    final mac = _plugin.resolvePlatformSpecificImplementation<
      MacOSFlutterLocalNotificationsPlugin
    >();
    final macGranted = await mac?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    if (macGranted != null) {
      granted = granted && macGranted;
    }

    return granted;
  }

  Future<void> replaceAllRecurringNotifications(
    List<ConstructionProject> projects, {
    bool requestPermission = false,
  }) async {
    if (kIsWeb) return;
    await initialize();

    if (requestPermission) {
      final permissionGranted = await requestPermissions();
      if (!permissionGranted) {
        return;
      }
    }

    await _plugin.cancelAll();

    for (final project in projects) {
      for (final recurring in project.recurringAlerts) {
        await _scheduleRecurring(project, recurring);
      }
    }
  }

  Future<void> _scheduleRecurring(
    ConstructionProject project,
    RecurringProjectAlert recurring,
  ) async {
    if (!recurring.isActive || recurring.intervalDays <= 0) return;

    var nextOccurrence = recurring.nextOccurrenceAt;
    final now = DateTime.now();
    while (!recurring
        .copyWith(nextOccurrenceAt: nextOccurrence)
        .nextTriggerAt
        .isAfter(now)) {
      nextOccurrence = nextOccurrence.add(Duration(days: recurring.intervalDays));
    }

    final id = _notificationId(project.projectId, recurring.id);
    final scheduleDate = tz.TZDateTime.from(
      recurring.copyWith(nextOccurrenceAt: nextOccurrence).nextTriggerAt,
      tz.local,
    );

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id,
      'Gridly: ${recurring.title}',
      recurring.message,
      scheduleDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'project:${project.projectId};recurring:${recurring.id}',
    );
  }

  int _notificationId(String projectId, String recurringId) {
    final raw = '$projectId:$recurringId';
    var hash = 0;
    for (final code in raw.codeUnits) {
      hash = ((hash * 31) + code) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }
}
