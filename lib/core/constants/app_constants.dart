import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = "blockit";
  static const String appTagline = "stop phone addiction";

  // Colors — BlockIt style: clean white/grey/black + vibrant orange
  static const Color primaryOrange = Color(0xFFFF6A00);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Colors.white;
  static const Color textPrimary = Color(0xFF0D0D0D);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color borderColor = Color(0xFFEEEEEE);
  static const Color successGreen = Color(0xFF2E7D32);

  // Session durations
  static const List<int> presetDurationsMinutes = [15, 30, 45, 60, 90, 120];

  // Parachute
  static const int maxFreeParachutes = 1;

  // Storage keys
  static const String keyTotalSessions = 'total_sessions';
  static const String keyTotalMinutes = 'total_minutes_locked';
  static const String keySessionsList = 'sessions_list';
  static const String keyParachutesUsed = 'parachutes_used';
}