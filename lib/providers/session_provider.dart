import 'package:flutter/material.dart';
import 'dart:async';
import '../core/utils/platform_channel_helper.dart';
import '../models/freedom_session.dart';
import 'stats_provider.dart';
import 'package:provider/provider.dart';
import '../features/active_session/active_session_screen.dart';
import '../features/active_session/session_complete_screen.dart';

class SessionProvider extends ChangeNotifier {
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isSessionActive = false;
  bool _isLocking = false;
  int _currentSessionDuration = 0;

  int get remainingSeconds => _remainingSeconds;
  bool get isSessionActive => _isSessionActive;
  bool get isLocking => _isLocking;
  
  Future<bool> startSession(int durationMinutes, BuildContext context) async {
    if (_isSessionActive) return false;
    final bool accessibilityEnabled =
        await PlatformChannelHelper.isAccessibilityServiceEnabled();
    if (!accessibilityEnabled) return false;

    _isLocking = true;
    notifyListeners();

    final success = await PlatformChannelHelper.startLockTask();
    if (success) {
      _currentSessionDuration = durationMinutes;
      _remainingSeconds = durationMinutes * 60;
      _isSessionActive = true;
      _isLocking = false;
      notifyListeners();

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ActiveSessionScreen()),
      );
      _startTimer(context);
      return true;
    }
    _isLocking = false;
    notifyListeners();
    return false;
  }

  void _startTimer(BuildContext context) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _endSession(context);
      }
    });
  }

  void _endSession(BuildContext context) async {
    _timer?.cancel();
    final actualDuration = _currentSessionDuration;

    _isSessionActive = false;
    _remainingSeconds = 0;
    _currentSessionDuration = 0;

    await context.read<StatsProvider>().addSession(
      FreedomSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        durationMinutes: actualDuration,
        startTime: DateTime.now().subtract(Duration(minutes: actualDuration)),
        usedParachute: false,
      ),
    );

    // 1. Physically turn on the screen
    await PlatformChannelHelper.wakeScreen();

    // 2. Show the success screen immediately
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              SessionCompleteScreen(sessionDuration: actualDuration),
        ),
      );
    }

    // 3. Stop the lock task mode
    await PlatformChannelHelper.stopLockTask();
    notifyListeners();
  }

  Future<void> emergencyStop(BuildContext context) async {
    _timer?.cancel();
    final actualDuration = _currentSessionDuration;
    _isSessionActive = false;
    _remainingSeconds = 0;

    await context.read<StatsProvider>().addSession(
      FreedomSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        durationMinutes: actualDuration,
        startTime: DateTime.now().subtract(Duration(minutes: actualDuration)),
        usedParachute: true,
      ),
    );

    await PlatformChannelHelper.stopLockTask();
    notifyListeners();
    Navigator.popUntil(context, (route) => route.isFirst);
  }
}
