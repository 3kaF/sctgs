import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/widgets/verdict_tag.dart';
import '../local/models.dart';

/// Layanan penyimpanan lokal (`SharedPreferences` + JSON cache) agar semua perubahan
/// tugas, kartu, progres SM-2, catatan, dan pengaturan tetap bertahan ketika aplikasi ditutup/dibuka ulang.
class LocalStorageService {
  const LocalStorageService._();

  static const String _keyThemeMode = 'ts_theme_mode';
  static const String _keyDyslexiaFont = 'ts_dyslexia_font';
  static const String _keyAccessNav = 'ts_access_nav';
  static const String _keySessionLimit = 'ts_session_limit';
  static const String _keyReminderTime = 'ts_reminder_time';
  static const String _keyNotesJson = 'ts_notes_json';
  static const String _keyCardProgressJson = 'ts_card_progress_json';
  static const String _keyTaskOverridesJson = 'ts_task_overrides_json';

  static Future<void> saveSettings({
    required String themeModeName,
    required bool dyslexiaFont,
    required bool showAccessNav,
    required int sessionLimit,
    required String reminderTime,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyThemeMode, themeModeName);
      await prefs.setBool(_keyDyslexiaFont, dyslexiaFont);
      await prefs.setBool(_keyAccessNav, showAccessNav);
      await prefs.setInt(_keySessionLimit, sessionLimit);
      await prefs.setString(_keyReminderTime, reminderTime);
    } catch (_) {
      // Abaikan bila dijalankan di lingkungan test tanpa plugin native
    }
  }

  static Future<void> saveNotes(List<NoteModel> notes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = notes
          .map(
            (n) => {
              'id': n.id,
              'subjectId': n.subjectId,
              'subjectName': n.subjectName,
              'subjectColorKey': n.subjectColorKey,
              'taskId': n.taskId,
              'cardId': n.cardId,
              'taskTitle': n.taskTitle,
              'body': n.body,
              'showInFeed': n.showInFeed,
              'updatedAt': n.updatedAt.toIso8601String(),
            },
          )
          .toList();
      await prefs.setString(_keyNotesJson, jsonEncode(list));
    } catch (_) {}
  }

  static Future<void> saveCardProgress(List<StudyCardModel> cards) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = <String, dynamic>{
        for (final c in cards)
          c.id: {
            'seenCount': c.seenCount,
            'lapses': c.lapses,
            'lastGrade': c.lastGrade,
            'ease': c.ease,
            'intervalDays': c.intervalDays,
            'nextReviewAt': c.nextReviewAt?.toIso8601String(),
            'isStarred': c.isStarred,
            'reported': c.reported,
          },
      };
      await prefs.setString(_keyCardProgressJson, jsonEncode(map));
    } catch (_) {}
  }

  static Future<void> saveTaskOverride(
    String taskId,
    TaskVerdict verdict,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyTaskOverridesJson);
      final Map<String, dynamic> current = raw != null
          ? (jsonDecode(raw) as Map<String, dynamic>)
          : <String, dynamic>{};
      current[taskId] = verdict.code;
      await prefs.setString(_keyTaskOverridesJson, jsonEncode(current));
    } catch (_) {}
  }

  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyNotesJson);
      await prefs.remove(_keyCardProgressJson);
      await prefs.remove(_keyTaskOverridesJson);
    } catch (_) {}
  }
}
