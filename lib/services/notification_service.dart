import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Notification service for transaction reminders
class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance =>
      _instance ??= NotificationService._();

  NotificationService._();

  final _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Initialize notification service
  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(settings: initSettings);

    // Request permission on Android 13+
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  /// Schedule reminder for unconfirmed transaction (10 minutes)
  Future<void> scheduleTransactionReminder({
    required String transactionId,
    required double amount,
    required bool isIncome,
  }) async {
    final id = transactionId.hashCode.abs() % 100000;
    final typeText = isIncome ? 'thu nhập' : 'chi tiêu';
    final amountText = _formatAmount(amount);

    await _notifications.zonedSchedule(
      id: id,
      title: '💰 Giao dịch cần xác nhận',
      body: 'Bạn có $typeText $amountText chưa phân loại',
      scheduledDate: tz.TZDateTime.now(
        tz.local,
      ).add(const Duration(minutes: 10)),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'transaction_reminders',
          'Nhắc nhở giao dịch',
          channelDescription: 'Thông báo nhắc xác nhận giao dịch',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: transactionId,
    );
  }

  /// Cancel reminder when transaction is confirmed
  Future<void> cancelTransactionReminder(String transactionId) async {
    final id = transactionId.hashCode.abs() % 100000;
    await _notifications.cancel(id: id);
  }

  /// Show immediate notification for pending transactions count
  Future<void> showPendingCountNotification(int count) async {
    if (count == 0) return;

    await _notifications.show(
      id: 0,
      title: '📋 Giao dịch chờ xác nhận',
      body: 'Bạn có $count giao dịch cần phân loại',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'transaction_reminders',
          'Nhắc nhở giao dịch',
          channelDescription: 'Thông báo nhắc xác nhận giao dịch',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}Tr';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
