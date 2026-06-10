import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/freedom_session.dart';
import '../models/reels_free_time_record.dart';
import '../core/constants/app_constants.dart';

class LocalStorageService {
  static Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();

  static const String keyReelsFreeTimeList = 'reels_free_time_list';

  // ================== EXISTING SESSION METHODS ==================

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

    int totalSessions = prefs.getInt(AppConstants.keyTotalSessions) ?? 0;
    int totalMinutes = prefs.getInt(AppConstants.keyTotalMinutes) ?? 0;

    await prefs.setInt(AppConstants.keyTotalSessions, totalSessions + 1);
    await prefs.setInt(
      AppConstants.keyTotalMinutes,
      totalMinutes + session.durationMinutes,
    );
  }

  static Future<List<FreedomSession>> getAllSessions() async {
    final prefs = await _prefs;
    final String sessionsJson =
        prefs.getString(AppConstants.keySessionsList) ?? '[]';
    final List<dynamic> list = jsonDecode(sessionsJson);

    return list.map((json) => FreedomSession.fromJson(json)).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  static Future<Map<String, int>> getStats() async {
    final prefs = await _prefs;
    return {
      'totalSessions': prefs.getInt(AppConstants.keyTotalSessions) ?? 0,
      'totalMinutes': prefs.getInt(AppConstants.keyTotalMinutes) ?? 0,
    };
  }

  static Future<int> getParachutesUsed() async {
    final prefs = await _prefs;
    return prefs.getInt(AppConstants.keyParachutesUsed) ?? 0;
  }

  static Future<void> incrementParachutesUsed() async {
    final prefs = await _prefs;
    int used = prefs.getInt(AppConstants.keyParachutesUsed) ?? 0;
    await prefs.setInt(AppConstants.keyParachutesUsed, used + 1);
  }

  static Future<int> getLastSelectedDuration() async {
    final prefs = await _prefs;
    return prefs.getInt(AppConstants.keyLastSelectedDuration) ?? 15;
  }

  static Future<void> saveLastSelectedDuration(int duration) async {
    final prefs = await _prefs;
    await prefs.setInt(AppConstants.keyLastSelectedDuration, duration);
  }

  static Future<int> getLastStatsFilter() async {
    final prefs = await _prefs;
    return prefs.getInt(AppConstants.keyLastStatsFilter) ?? 1;
  }

  static Future<void> saveLastStatsFilter(int filterIndex) async {
    final prefs = await _prefs;
    await prefs.setInt(AppConstants.keyLastStatsFilter, filterIndex);
  }

  // ================== FIXED: REELS-FREE TIME METRIC CONTROLLER ==================

  static Future<void> syncNativeReelsFreeTimeBuffer() async {
    final prefs = await _prefs;
    final String rawBufferJson =
        prefs.getString('native_reels_free_time_buffer') ?? '[]';
    if (rawBufferJson == '[]') return;

    final List<dynamic> jsonList = jsonDecode(rawBufferJson);
    if (jsonList.isEmpty) return;

    final List<ReelsFreeTimeRecord> currentRecords =
        await getAllReelsFreeTimeRecords();

    for (var item in jsonList) {
      if (item is Map) {
        final int mins = item['durationMinutes'] ?? 0;
        final int ms = item['timestamp'] ?? 0;

        if (mins > 0 && ms > 0) {
          currentRecords.add(
            ReelsFreeTimeRecord(
              id: 'free_${ms}_${currentRecords.length}',
              durationMinutes: mins,
              timestamp: DateTime.fromMillisecondsSinceEpoch(ms),
            ),
          );
        }
      }
    }

    await prefs.setString(
      keyReelsFreeTimeList,
      jsonEncode(currentRecords.map((r) => r.toJson()).toList()),
    );
    await prefs.setString(
      'native_reels_free_time_buffer',
      '[]',
    ); // Wipe background buffer cache securely
  }

  static Future<List<ReelsFreeTimeRecord>> getAllReelsFreeTimeRecords() async {
    final prefs = await _prefs;
    final String recordsJson = prefs.getString(keyReelsFreeTimeList) ?? '[]';
    final List<dynamic> list = jsonDecode(recordsJson);
    return list.map((json) => ReelsFreeTimeRecord.fromJson(json)).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  static Future<void> overwriteAllData(
    int tSessions,
    int tMinutes,
    int parachutes,
    List<FreedomSession> sList,
    List<ReelsFreeTimeRecord> rList,
  ) async {
    final prefs = await _prefs;
    await prefs.setInt(AppConstants.keyTotalSessions, tSessions);
    await prefs.setInt(AppConstants.keyTotalMinutes, tMinutes);
    await prefs.setInt(AppConstants.keyParachutesUsed, parachutes);
    await prefs.setString(
      AppConstants.keySessionsList,
      jsonEncode(sList.map((s) => s.toJson()).toList()),
    );
    await prefs.setString(
      keyReelsFreeTimeList,
      jsonEncode(rList.map((r) => r.toJson()).toList()),
    );
  }

  static Future<void> clearAllStats() async {
    final prefs = await _prefs;
    await prefs.remove(AppConstants.keyTotalSessions);
    await prefs.remove(AppConstants.keyTotalMinutes);
    await prefs.remove(AppConstants.keyParachutesUsed);
    await prefs.remove(AppConstants.keySessionsList);
    await prefs.remove(keyReelsFreeTimeList);
  }
}
