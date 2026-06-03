import 'package:flutter/material.dart';
import 'dart:async';
import '../core/utils/platform_channel_helper.dart';
import '../models/freedom_session.dart';
import 'stats_provider.dart';
import 'package:provider/provider.dart';
import '../features/active_session/active_session_screen.dart';
import '../features/active_session/session_complete_screen.dart';

enum SessionStartResult {
  success,
  accessibilityDenied,
  alreadyActive,
  lockTaskFailed,
}

class SessionProvider extends ChangeNotifier {
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isSessionActive = false;
  bool _isLocking = false;
  int _currentSessionDuration = 0;

  // New absolute time trackers to fix background clock throttling
  DateTime? _sessionStartTime;
  DateTime? _sessionEndTime;

  // Callback registered by ActiveSessionScreen to un-dim before session ends
  VoidCallback? onUndimRequested;

  int get remainingSeconds => _remainingSeconds;
  bool get isSessionActive => _isSessionActive;
  bool get isLocking => _isLocking;
  DateTime? get sessionStartTime => _sessionStartTime; // Public getter for UI

  Future<SessionStartResult> startSession(
    int durationMinutes,
    BuildContext context,
  ) async {
    if (_isSessionActive) return SessionStartResult.alreadyActive;

    final bool accessibilityEnabled =
        await PlatformChannelHelper.isAccessibilityServiceEnabled();

    if (!accessibilityEnabled) {
      return SessionStartResult.accessibilityDenied;
    }

    _isLocking = true;
    notifyListeners();

    final success = await PlatformChannelHelper.startLockTask();
    if (success) {
      _currentSessionDuration = durationMinutes;
      _sessionStartTime = DateTime.now();
      _sessionEndTime = _sessionStartTime!.add(
        Duration(minutes: durationMinutes),
      );
      _remainingSeconds = durationMinutes * 60;
      _isSessionActive = true;
      _isLocking = false;
      notifyListeners();

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ActiveSessionScreen()),
      );
      _startTimer(context);
      return SessionStartResult.success;
    }

    _isLocking = false;
    notifyListeners();
    return SessionStartResult.lockTaskFailed;
  }

  void _startTimer(BuildContext context) {
    _timer?.cancel();
    // Run an evaluation step based on real-world system times
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isSessionActive && _sessionEndTime != null) {
        final now = DateTime.now();
        if (now.isBefore(_sessionEndTime!)) {
          // Calculate exact real remaining time regardless of any background CPU lag
          _remainingSeconds = _sessionEndTime!.difference(now).inSeconds;
          notifyListeners();
        } else {
          _endSession(context);
        }
      }
    });
  }

  void _endSession(BuildContext context) async {
    _timer?.cancel();
    final actualDuration = _currentSessionDuration;

    _isSessionActive = false;
    _remainingSeconds = 0;
    _currentSessionDuration = 0;
    final savedStartTime =
        _sessionStartTime ??
        DateTime.now().subtract(Duration(minutes: actualDuration));
    _sessionStartTime = null;
    _sessionEndTime = null;

    // Un-dim the screen first before doing anything else
    onUndimRequested?.call();

    await context.read<StatsProvider>().addSession(
      FreedomSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        durationMinutes: actualDuration,
        startTime: savedStartTime,
        usedParachute: false,
      ),
    );

    await PlatformChannelHelper.wakeScreen();

    // Small delay to let the wake + un-dim fully render before navigating
    await Future.delayed(const Duration(milliseconds: 500));

    await PlatformChannelHelper.stopLockTask();

    // Another brief pause to ensure lock task is released before pushing
    await Future.delayed(const Duration(milliseconds: 200));

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              SessionCompleteScreen(sessionDuration: actualDuration),
        ),
      );
    }

    notifyListeners();
  }

  Future<void> emergencyStop(BuildContext context) async {
    _timer?.cancel();
    final actualDuration = _currentSessionDuration;
    _isSessionActive = false;
    _remainingSeconds = 0;
    _currentSessionDuration = 0;
    final savedStartTime =
        _sessionStartTime ??
        DateTime.now().subtract(Duration(minutes: actualDuration));
    _sessionStartTime = null;
    _sessionEndTime = null;

    // Un-dim before stopping
    onUndimRequested?.call();

    await context.read<StatsProvider>().addSession(
      FreedomSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        durationMinutes: actualDuration,
        startTime: savedStartTime,
        usedParachute: true,
      ),
    );

    await PlatformChannelHelper.stopLockTask();
    notifyListeners();
    Navigator.popUntil(context, (route) => route.isFirst);
  }
}
