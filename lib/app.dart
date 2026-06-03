import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/session_provider.dart';
import 'providers/stats_provider.dart';
import 'features/splash/splash_screen.dart'; // Import statement added here

class BlockitApp extends StatelessWidget {
  const BlockitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProvider(create: (_) => StatsProvider()),
      ],
      child: MaterialApp(
        title: 'blockit',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(), // Changed from HomeScreen() to SplashScreen()
      ),
    );
  }
}