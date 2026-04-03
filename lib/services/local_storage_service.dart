import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/freedom_session.dart';
import '../core/constants/app_constants.dart';

class LocalStorageService {
  static Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();

  // Save a completed session
  static Future<void> saveSession(FreedomSession session) async {
    final prefs = await _prefs;
    final String sessionsJson =
        prefs.getString(AppConstants.keySessionsList) ?? '[]';
    final List<dynamic> sessionsList = jsonDecode(sessionsJson);

    sessionsList.add(session.toJson());

    await prefs.setString(
      AppConstants.keySessionsList,
      jsonEncode(sessionsList),
    );

    // Update totals
    int totalSessions = prefs.getInt(AppConstants.keyTotalSessions) ?? 0;
    int totalMinutes = prefs.getInt(AppConstants.keyTotalMinutes) ?? 0;

    await prefs.setInt(AppConstants.keyTotalSessions, totalSessions + 1);
    await prefs.setInt(
      AppConstants.keyTotalMinutes,
      totalMinutes + session.durationMinutes,
    );
  }

  // Get all sessions
  static Future<List<FreedomSession>> getAllSessions() async {
    final prefs = await _prefs;
    final String sessionsJson =
        prefs.getString(AppConstants.keySessionsList) ?? '[]';
    final List<dynamic> list = jsonDecode(sessionsJson);

    return list.map((json) => FreedomSession.fromJson(json)).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime)); // newest first
  }

  // Get stats
  static Future<Map<String, int>> getStats() async {
    final prefs = await _prefs;
    return {
      'totalSessions': prefs.getInt(AppConstants.keyTotalSessions) ?? 0,
      'totalMinutes': prefs.getInt(AppConstants.keyTotalMinutes) ?? 0,
    };
  }

  // Parachute management
  static Future<int> getParachutesUsed() async {
    final prefs = await _prefs;
    return prefs.getInt(AppConstants.keyParachutesUsed) ?? 0;
  }

  static Future<void> incrementParachutesUsed() async {
    final prefs = await _prefs;
    int used = prefs.getInt(AppConstants.keyParachutesUsed) ?? 0;
    await prefs.setInt(AppConstants.keyParachutesUsed, used + 1);
  }

  static Future<void> resetParachutes() async {
    final prefs = await _prefs;
    await prefs.setInt(AppConstants.keyParachutesUsed, 0);
  }

  // ─── NEW: USER PREFERENCES ──────────────────────────────────────────────

  static Future<int> getLastSelectedDuration() async {
    final prefs = await _prefs;
    // Default to 15 minutes if it's their first time
    return prefs.getInt(AppConstants.keyLastSelectedDuration) ?? 15;
  }

  static Future<void> saveLastSelectedDuration(int duration) async {
    final prefs = await _prefs;
    await prefs.setInt(AppConstants.keyLastSelectedDuration, duration);
  }

  static Future<int> getLastStatsFilter() async {
    final prefs = await _prefs;
    // Default to 1 (Week) view
    return prefs.getInt(AppConstants.keyLastStatsFilter) ?? 1;
  }

  static Future<void> saveLastStatsFilter(int filterIndex) async {
    final prefs = await _prefs;
    await prefs.setInt(AppConstants.keyLastStatsFilter, filterIndex);
  }
}
