import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:home_widget/home_widget.dart';
import 'core/theme/app_theme.dart';
import 'providers/session_provider.dart';
import 'providers/stats_provider.dart';
import 'features/splash/splash_screen.dart';
import 'core/utils/platform_channel_helper.dart';

// Global navigator key to safely execute automated route transitions from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        builder: (context, child) {
          // Wrap navigation frame with a permanent widget click observer
          return WidgetLaunchObserver(child: child!);
        },
        home: const SplashScreen(),
      ),
    );
  }
}

/// Persistent root layout observer that captures home screen widget actions
/// across both cold and warm application lifecycles accurately.
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
      if (mounted) {
        final sessionProvider = context.read<SessionProvider>();

        // 1. Check launch parameters for completely terminated application processes (Cold Start)
        HomeWidget.initiallyLaunchedFromHomeWidget().then((uri) {
          if (uri != null) _handleWidgetUri(uri, sessionProvider);
        });

        // 2. Active event stream listener to process background application wakeups (Warm Start)
        HomeWidget.widgetClicked.listen((uri) {
          if (uri != null) _handleWidgetUri(uri, sessionProvider);
        });
      }
    });
  }

  void _handleWidgetUri(Uri uri, SessionProvider sessionProvider) async {
    if (uri.host == 'start') {
      final duration =
          int.tryParse(uri.queryParameters['duration'] ?? '') ?? 15;

      // Defer execution slightly to let running splash sequences and core animations settle
      await Future.delayed(const Duration(milliseconds: 1800));

      if (!mounted) return;
      final targetContext = navigatorKey.currentContext ?? context;

      // Automatically instantiate focus lock sequence
      final result = await sessionProvider.startSession(
        duration,
        targetContext,
      );

      // Handle structural permission failures or error contexts globally
      if (result == SessionStartResult.accessibilityDenied) {
        _showGlobalPermissionDialog(targetContext);
      } else if (result == SessionStartResult.lockTaskFailed) {
        ScaffoldMessenger.of(targetContext).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not start focus lock. Enable Device Admin in Settings and try again.',
            ),
          ),
        );
      }
    }
  }

  void _showGlobalPermissionDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Permission Required',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'To block distractions effectively, blockit needs Accessibility Service permission. Please enable "Blockit Accessibility" in the settings.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEED2C2),
              foregroundColor: const Color(0xFF151211),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              PlatformChannelHelper.openAccessibilitySettings();
            },
            child: const Text(
              'Open Settings',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
