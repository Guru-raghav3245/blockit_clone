import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppConstants.primaryAccent,
      brightness: Brightness.dark,
      primary: AppConstants.primaryAccent,
      surface: AppConstants.surfaceColor,
      background: AppConstants.backgroundColor,
      onBackground: AppConstants.textPrimary,
    ),
    scaffoldBackgroundColor: AppConstants.backgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppConstants.backgroundColor,
      foregroundColor: AppConstants.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      titleTextStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.0,
        color: AppConstants.textMuted,
      ),
    ),
  );
}
