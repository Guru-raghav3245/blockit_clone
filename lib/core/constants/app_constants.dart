import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = "blockit";
  static const String appTagline = "stop phone addiction";

  // Colors — BlockIt style: Dark Warm Aesthetic
  static const Color primaryOrange = Color(0xFFFF6A00);
  static const Color backgroundColor = Color(0xFF151211);
  static const Color cardColor = Color(0xFF1E1B1A);
  static const Color surfaceColor = Color(0xFF1E1B1A);
  static const Color borderColor = Color(0xFF332D2D);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textMuted = Colors.white54;

  static const Color successGreen = Color(0xFF4CAF50);

  // Session durations
  static const List<int> presetDurationsMinutes = [15, 30, 45, 60, 90, 120];

  // Storage keys
  static const String keyTotalSessions = 'total_sessions';
  static const String keyTotalMinutes = 'total_minutes_locked';
  static const String keySessionsList = 'sessions_list';
  static const String keyParachutesUsed = 'parachutes_used';
  
  // User Preferences Storage Keys
  static const String keyLastSelectedDuration = 'last_selected_duration';
  static const String keyLastStatsFilter = 'last_stats_filter';
}