import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = "blockit";
  static const String appTagline = "stop phone addiction";

  // Colors (Blockit style: clean white/grey + vibrant orange)
  static const Color primaryOrange = Color(0xFFFF6A00);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color surfaceColor = Colors.white;
  static const Color textPrimary = Color(0xFF1F1F1F);
  static const Color textSecondary = Color(0xFF6B7280);

  // Session durations (common presets)
  static const List<int> presetDurationsMinutes = [15, 30, 45, 60, 90, 120];

  // Parachute (emergency exit)
  static const int maxFreeParachutes = 1;

  // Storage keys
  static const String keyTotalSessions = 'total_sessions';
  static const String keyTotalMinutes = 'total_minutes_locked';
  static const String keySessionsList = 'sessions_list';
  static const String keyParachutesUsed = 'parachutes_used';
}