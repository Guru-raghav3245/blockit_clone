import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/local_storage_service.dart';
import '../services/cloud_sync_service.dart';
import '../models/freedom_session.dart';
import '../models/reels_free_time_record.dart';

class StatsProvider extends ChangeNotifier {
  int totalSessions = 0;
  int totalMinutes = 0;
  int parachutesUsed = 0;
  List<FreedomSession> sessions = [];
  
  // High-performance dynamic storage container
  List<ReelsFreeTimeRecord> reelsFreeRecords = [];

  Future<void> loadStats() async {
    await LocalStorageService.syncNativeReelsFreeTimeBuffer();

    final stats = await LocalStorageService.getStats();
    totalSessions = stats['totalSessions']!;
    totalMinutes = stats['totalMinutes']!;

    sessions = await LocalStorageService.getAllSessions();
    parachutesUsed = await LocalStorageService.getParachutesUsed();
    reelsFreeRecords = await LocalStorageService.getAllReelsFreeTimeRecords();

    notifyListeners();
  }

  Future<void> addSession(FreedomSession session) async {
    await LocalStorageService.saveSession(session);
    await loadStats();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await CloudSyncService.pushToCloud(
        user.uid,
        totalSessions,
        totalMinutes,
        parachutesUsed,
        sessions,
        reelsFreeRecords,
      );
    }
  }

  Future<void> loginAndSync(String uid) async {
    await LocalStorageService.syncNativeReelsFreeTimeBuffer();
    final cloudData = await CloudSyncService.pullFromCloud(uid);
    final localSessions = await LocalStorageService.getAllSessions();
    final localReelsRecords = await LocalStorageService.getAllReelsFreeTimeRecords();
    int currentParachutes = await LocalStorageService.getParachutesUsed();

    if (cloudData != null) {
      // 1. Synchronize standard lock sessions
      final List<dynamic> cloudSessionsRaw = cloudData['sessionsList'] ?? [];
      final cloudSessions = cloudSessionsRaw.map((e) => FreedomSession.fromJson(e)).toList();
      final Map<String, FreedomSession> mergedSessionsMap = {};
      for (var s in cloudSessions) { mergedSessionsMap[s.id] = s; }
      for (var s in localSessions) { mergedSessionsMap[s.id] = s; }
      final mergedSessionsList = mergedSessionsMap.values.toList()
        ..sort((a, b) => b.startTime.compareTo(a.startTime));

      // 2. Synchronize dynamic Reels-free duration matrices cleanly
      final List<dynamic> cloudReelsRaw = cloudData['reelsFreeTimeList'] ?? [];
      final cloudReels = cloudReelsRaw.map((e) => ReelsFreeTimeRecord.fromJson(e)).toList();
      final Map<String, ReelsFreeTimeRecord> mergedReelsMap = {};
      for (var r in cloudReels) { mergedReelsMap[r.id] = r; }
      for (var r in localReelsRecords) { mergedReelsMap[r.id] = r; }
      final mergedReelsList = mergedReelsMap.values.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      int newTotalMinutes = mergedSessionsList.fold(0, (sum, s) => sum + s.durationMinutes);
      int newTotalSessions = mergedSessionsList.length;
      int cloudParachutes = cloudData['parachutesUsed'] ?? 0;
      int newParachutes = currentParachutes > cloudParachutes ? currentParachutes : cloudParachutes;

      await LocalStorageService.overwriteAllData(
        newTotalSessions,
        newTotalMinutes,
        newParachutes,
        mergedSessionsList,
        mergedReelsList,
      );

      totalSessions = newTotalSessions;
      totalMinutes = newTotalMinutes;
      sessions = mergedSessionsList;
      parachutesUsed = newParachutes;
      reelsFreeRecords = mergedReelsList;

      await CloudSyncService.pushToCloud(
        uid,
        totalSessions,
        totalMinutes,
        parachutesUsed,
        sessions,
        reelsFreeRecords,
      );
    } else {
      await CloudSyncService.pushToCloud(
        uid,
        totalSessions,
        totalMinutes,
        parachutesUsed,
        localSessions,
        localReelsRecords,
      );
    }
    notifyListeners();
  }

  Future<void> clearLocalAndMemory() async {
    await LocalStorageService.clearAllStats();
    totalSessions = 0;
    totalMinutes = 0;
    parachutesUsed = 0;
    sessions = [];
    reelsFreeRecords = [];
    notifyListeners();
  }
}