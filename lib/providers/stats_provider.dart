import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
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

  Future<void> addSession(FreedomSession session) async {
    await LocalStorageService.saveSession(session);
    await loadStats();   // This refreshes parachutesUsed
  }
}