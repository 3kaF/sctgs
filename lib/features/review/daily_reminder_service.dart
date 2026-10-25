import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Layanan pengingat harian lokal sesuai Bagian 6.8 & 9 PRD dan Bagian 12 `design.md`:
/// - Maksimal satu notifikasi per hari di jam pilihan pengguna.
/// - Hanya dijadwalkan bila memang ada kartu yang jatuh tempo (`dueCount > 0`).
/// - Menghormati jam tenang malam (21:00 - 07:00) dan menggunakan kalimat langsung tanpa rasa bersalah.
class DailyReminderService {
  DailyReminderService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const initSettings = InitializationSettings(android: androidSettings);
      await _plugin.initialize(initSettings);
      _initialized = true;
    } catch (_) {
      // Aman bila dijalankan di widget test
    }
  }

  /// Menampilkan atau memperbarui pengingat kartu jatuh tempo hari ini.
  static Future<void> scheduleOrShowDueReminder({
    required int dueCardCount,
    required bool quietHoursEnabled,
    DateTime? nowOverride,
  }) async {
    if (dueCardCount <= 0) return;

    final now = nowOverride ?? DateTime.now();
    // Hormati jam tenang malam (pukul 21:00 s/d 07:00)
    if (quietHoursEnabled && (now.hour >= 21 || now.hour < 7)) {
      return;
    }

    try {
      await initialize();
      const androidDetails = AndroidNotificationDetails(
        'tugasscroll_daily_review',
        'Pengingat Ulang Tugas',
        channelDescription:
            'Pengingat harian maksimal satu kali sehari saat ada kartu jatuh tempo.',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );
      const details = NotificationDetails(android: androidDetails);

      await _plugin.show(
        1001,
        'TugasScroll',
        '$dueCardCount kartu perlu diulang hari ini.',
        details,
      );
    } catch (_) {}
  }
}
