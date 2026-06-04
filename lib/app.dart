import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:home_widget/home_widget.dart';
import 'core/theme/app_theme.dart';
import 'providers/session_provider.dart';
import 'providers/stats_provider.dart';
import 'features/splash/splash_screen.dart';

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
        builder: (context, child) {
          return WidgetLaunchObserver(child: child!);
        },
        home: const SplashScreen(),
      ),
    );
  }
}

class WidgetLaunchObserver extends StatefulWidget {
  final Widget child;
  const WidgetLaunchObserver({super.key, required this.child});

  @override
  State<WidgetLaunchObserver> createState() => _WidgetLaunchObserverState();
}

class _WidgetLaunchObserverState extends State<WidgetLaunchObserver> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sessionProvider = context.read<SessionProvider>();

      // 1. Intercept cold start launches
      HomeWidget.initiallyLaunchedFromHomeWidget().then((uri) {
        if (uri != null) _handleWidgetUri(uri, sessionProvider);
      });

      // 2. Intercept warm background updates
      HomeWidget.widgetClicked.listen((uri) {
        if (uri != null) _handleWidgetUri(uri, sessionProvider);
      });
    });
  }

  void _handleWidgetUri(Uri uri, SessionProvider sessionProvider) {
    if (uri.host == 'start') {
      final duration =
          int.tryParse(uri.queryParameters['duration'] ?? '') ?? 15;

      if (sessionProvider.isSessionActive) return;

      // Always populate the pending state to let the active UI framework consume it reactively
      sessionProvider.setPendingWidgetDuration(duration);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
