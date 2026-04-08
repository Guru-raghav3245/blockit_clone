import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/local_storage_service.dart';
import '../services/cloud_sync_service.dart';
import '../models/freedom_session.dart';

class StatsProvider extends ChangeNotifier {
  int totalSessions = 0;
  int totalMinutes = 0;
  List<FreedomSession> sessions = [];
  int parachutesUsed = 0;

  Future<void> loadStats() async {
    final stats = await LocalStorageService.getStats();
    totalSessions = stats['totalSessions']!;
    totalMinutes = stats['totalMinutes']!;

    sessions = await LocalStorageService.getAllSessions();
    parachutesUsed = await LocalStorageService.getParachutesUsed();

    notifyListeners();
  }

  // Overridden to save locally, refresh memory, AND push to cloud if logged in.
  Future<void> addSession(FreedomSession session) async {
    // 1. Save to device
    await LocalStorageService.saveSession(session);
    
    // 2. Refresh RAM
    await loadStats(); 
    
    // 3. Backup to Cloud
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await CloudSyncService.pushToCloud(
        user.uid,
        totalSessions,
        totalMinutes,
        parachutesUsed,
        sessions,
      );
    }
  }

  // ─── CLOUD SYNC LOGIC ───────────────────────────────────────────────────

  Future<void> loginAndSync(String uid) async {
    // 1. Pull the data from the cloud
    final cloudData = await CloudSyncService.pullFromCloud(uid);

    // 2. Get current local data
    final localSessions = await LocalStorageService.getAllSessions();
    int currentParachutes = await LocalStorageService.getParachutesUsed();

    if (cloudData != null) {
      // 3a. User has cloud data. We must MERGE it with local data so nothing is lost.
      final List<dynamic> cloudSessionsRaw = cloudData['sessionsList'] ?? [];
      final cloudSessions = cloudSessionsRaw.map((e) => FreedomSession.fromJson(e)).toList();

      // Use a Map to prevent duplicate sessions (session ID is the key)
      final Map<String, FreedomSession> mergedMap = {};
      
      // Add all cloud sessions
      for (var s in cloudSessions) {
        mergedMap[s.id] = s;
      }
      // Add all local sessions (If there's a duplicate ID, local overwrites cloud)
      for (var s in localSessions) {
        mergedMap[s.id] = s; 
      }

      final mergedList = mergedMap.values.toList();
      mergedList.sort((a, b) => b.startTime.compareTo(a.startTime)); // Re-sort newest first

      // Recalculate true totals based on the merged list
      int newTotalMinutes = mergedList.fold(0, (sum, s) => sum + s.durationMinutes);
      int newTotalSessions = mergedList.length;

      // Parachutes (Take whichever is higher to be safe)
      int cloudParachutes = cloudData['parachutesUsed'] ?? 0;
      int newParachutes = currentParachutes > cloudParachutes ? currentParachutes : cloudParachutes;

      // Save the merged perfection back to local storage
      await LocalStorageService.overwriteAllData(newTotalSessions, newTotalMinutes, newParachutes, mergedList);

      // Update provider memory
      totalSessions = newTotalSessions;
      totalMinutes = newTotalMinutes;
      sessions = mergedList;
      parachutesUsed = newParachutes;

      // Push the unified merged data back to the cloud
      await CloudSyncService.pushToCloud(uid, totalSessions, totalMinutes, parachutesUsed, sessions);

    } else {
      // 3b. First time logging in (No cloud data). Just push whatever is on the device up!
      await CloudSyncService.pushToCloud(uid, totalSessions, totalMinutes, parachutesUsed, localSessions);
    }
    
    notifyListeners();
  }

  Future<void> clearLocalAndMemory() async {
    await LocalStorageService.clearAllStats();
    totalSessions = 0;
    totalMinutes = 0;
    parachutesUsed = 0;
    sessions = [];
    notifyListeners();
  }
}