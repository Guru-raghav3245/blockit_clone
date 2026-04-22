import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = "blockit";
  static const String appTagline = "stop phone addiction";

  // Updated Colors — Replicating the Original Peach/Warm Charcoal Scheme
  static const Color primaryAccent = Color(
    0xFFEED2C2,
  ); // Soft Peach from screenshots
  static const Color backgroundColor = Color(0xFF151211);
  static const Color cardColor = Color(0xFF1E1B1A);
  static const Color surfaceColor = Color(0xFF1E1B1A);
  static const Color borderColor = Color(0xFF332D2D);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textMuted = Colors.white54;
  static const Color textDark = Color(
    0xFF151211,
  ); // Dark text for light backgrounds

  static const Color successGreen = Color(0xFF4CAF50);

  // Storage keys
  static const String keyTotalSessions = 'total_sessions';
  static const String keyTotalMinutes = 'total_minutes_locked';
  static const String keySessionsList = 'sessions_list';
  static const String keyParachutesUsed = 'parachutes_used';
  static const String keyLastSelectedDuration = 'last_selected_duration';
  static const String keyLastStatsFilter = 'last_stats_filter';
}
