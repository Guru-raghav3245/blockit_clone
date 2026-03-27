import 'package:flutter/material.dart';
import 'dart:async';
import '../core/utils/platform_channel_helper.dart';
import '../core/constants/app_constants.dart';
import '../models/freedom_session.dart';
import 'stats_provider.dart';
import 'package:provider/provider.dart';
import '../features/active_session/active_session_screen.dart';
import '../services/local_storage_service.dart';

class SessionProvider extends ChangeNotifier {
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isSessionActive = false;
  bool _isLocking = false;
  int _currentSessionDuration = 0;

  int get remainingSeconds => _remainingSeconds;
  bool get isSessionActive => _isSessionActive;
  bool get isLocking => _isLocking;

  String get formattedTime {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<bool> startSession(int durationMinutes, BuildContext context) async {
    if (_isSessionActive) return false;

    // Check accessibility service first
    final bool accessibilityEnabled =
        await PlatformChannelHelper.isAccessibilityServiceEnabled();

    if (!accessibilityEnabled) {
      if (context.mounted) {
        await _showAccessibilityDialog(context);
      }
      return false;
    }

    _isLocking = true;
    notifyListeners();

    final success = await PlatformChannelHelper.startLockTask();

    if (success) {
      _currentSessionDuration = durationMinutes;
      _remainingSeconds = durationMinutes * 60;
      _isSessionActive = true;
      _isLocking = false;

      notifyListeners();

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ActiveSessionScreen()),
        );
      }

      _startTimer(context);
      return true;
    } else {
      _isLocking = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _showAccessibilityDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enable Accessibility Service'),
        content: const Text(
          'Blockit needs Accessibility permission to fully lock your phone '
          'and prevent swipe gestures from escaping.\n\n'
          'Tap Enable, then find "Blockit Accessibility" and turn it on.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await PlatformChannelHelper.openAccessibilitySettings();
            },
            child: const Text(
              'Enable',
              style: TextStyle(color: AppConstants.primaryOrange),
            ),
          ),
        ],
      ),
    );
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

    final session = FreedomSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      durationMinutes: actualDuration,
      startTime: DateTime.now().subtract(Duration(minutes: actualDuration)),
      usedParachute: false,
    );

    if (context.mounted) {
      await context.read<StatsProvider>().addSession(session);
    }
    await PlatformChannelHelper.stopLockTask();

    notifyListeners();

    if (context.mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  Future<void> emergencyStop(BuildContext context) async {
    _timer?.cancel();
    final actualDuration = _currentSessionDuration;

    _isSessionActive = false;
    _remainingSeconds = 0;
    _currentSessionDuration = 0;

    final session = FreedomSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      durationMinutes: actualDuration,
      startTime: DateTime.now().subtract(Duration(minutes: actualDuration)),
      usedParachute: true,
    );

    if (context.mounted) {
      await context.read<StatsProvider>().addSession(session);
    }
    await LocalStorageService.incrementParachutesUsed();
    await PlatformChannelHelper.stopLockTask();

    notifyListeners();

    if (context.mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
