import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/session_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/platform_channel_helper.dart';
import '../../models/app_notification.dart';

class ActiveSessionScreen extends StatefulWidget {
  const ActiveSessionScreen({super.key});

  @override
  State<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends State<ActiveSessionScreen> {
  Timer? _inactivityTimer;
  StreamSubscription<Map<String, dynamic>>? _batterySubscription;
  StreamSubscription<Map<dynamic, dynamic>>? _notificationSubscription;
  bool _isDimmed = false;
  int _batteryPercentage = -1;
  bool _isCharging = false;
  late SessionProvider _sessionProvider;

  final List<AppNotification> _notifications = [];
  bool _showNotifications = false;

  @override
  void initState() {
    super.initState();
    _sessionProvider = context.read<SessionProvider>();
    _resetInactivityTimer();
    _listenToBatteryChanges();
    _listenToNotifications();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sessionProvider.onUndimRequested = _undim;
    });
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _batterySubscription?.cancel();
    _notificationSubscription?.cancel();
    _sessionProvider.onUndimRequested = null;
    super.dispose();
  }

  void _undim() {
    if (mounted) setState(() => _isDimmed = false);
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    if (_isDimmed) setState(() => _isDimmed = false);
    _inactivityTimer = Timer(const Duration(seconds: 10), _dimScreen);
  }

  void _dimScreen() {
    setState(() => _isDimmed = true);
  }

  // ================== FIXED: LISTEN TO BROADCASTS FOR INSTANT UPDATES ==================
  void _listenToBatteryChanges() {
    _batterySubscription = PlatformChannelHelper.watchBatteryInfo().listen((info) {
      if (mounted) {
        setState(() {
          _batteryPercentage = info['level'] ?? -1;
          _isCharging = info['isCharging'] ?? false;
        });
      }
    });
  }

  // ================== LIVE NOTIFICATION FEED ==================
  void _listenToNotifications() {
    _notificationSubscription = PlatformChannelHelper.watchNotifications().listen(
      (event) {
        if (!mounted) return;
        final type = event['type'] as String?;
        if (type == 'posted') {
          final notif = AppNotification.fromMap(event);
          setState(() {
            _notifications.removeWhere((n) => n.key == notif.key);
            _notifications.insert(0, notif);
          });
        } else if (type == 'removed') {
          final key = event['key'] as String?;
          if (key != null) {
            setState(() => _notifications.removeWhere((n) => n.key == key));
          }
        } else if (type == 'sessionEnded') {
          if (mounted) setState(() => _notifications.clear());
        }
      },
      onError: (_) {},
    );
  }

  void _onUserInteraction(PointerEvent event) {
    _resetInactivityTimer();
  }

  @override
  Widget build(BuildContext context) {
    final sessionProvider = context.watch<SessionProvider>();
    final remaining = sessionProvider.remainingSeconds;
    final hours = remaining ~/ 3600;
    final minutes = (remaining % 3600) ~/ 60;
    final seconds = remaining % 60;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    // Format start time safely if available
    String startTimeText = '--:--';
    if (sessionProvider.sessionStartTime != null) {
      startTimeText = DateFormat(
        'hh:mm:ss a',
      ).format(sessionProvider.sessionStartTime!);
    }

    final String liveWallTime = DateFormat('hh:mm a').format(DateTime.now());
    final String batteryText = _batteryPercentage >= 0 ? '$_batteryPercentage%' : '--%';

    return Listener(
      onPointerDown: _onUserInteraction,
      onPointerMove: _onUserInteraction,
      onPointerUp: _onUserInteraction,
      behavior: HitTestBehavior.translucent,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 800),
        opacity: _isDimmed ? 0.05 : 1.0,
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {},
          child: Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              child: Stack(
                children: [
                  Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Hardware Device Status Top Bar Widget Panel
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time_filled_rounded, color: Color(0xFF444444), size: 14),
                            const SizedBox(width: 6),
                            Text(
                              liveWallTime,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF666666),
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              batteryText,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF666666),
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(width: 6),
                            // DYNAMICALLY TOGGLED AND TINTED CHARGING STATES
                            Icon(
                              _isCharging ? Icons.battery_charging_full_rounded : Icons.battery_std_rounded, 
                              color: _isCharging ? AppConstants.primaryAccent : const Color(0xFF444444), 
                              size: 14
                            ),
                            const SizedBox(width: 14),
                            // Notification feed toggle
                            GestureDetector(
                              onTap: () {
                                _resetInactivityTimer();
                                setState(() {
                                  _showNotifications = !_showNotifications;
                                });
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _showNotifications
                                        ? Icons.notifications_active_rounded
                                        : Icons.notifications_rounded,
                                    color: _notifications.isNotEmpty
                                        ? AppConstants.primaryAccent
                                        : const Color(0xFF444444),
                                    size: 16,
                                  ),
                                  if (_notifications.isNotEmpty) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppConstants.primaryAccent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${_notifications.length}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: AppConstants.textDark,
                                          height: 1.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: isLandscape ? 10 : 30),
                  const Text(
                    'SESSION ACTIVE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF444444),
                      letterSpacing: 4.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'PUT THE PHONE DOWN',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF666666),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Start Time Validation Display
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151515),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF2A2A2A),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'STARTED AT: $startTimeText',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.primaryAccent,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  const Spacer(),
                  // Responsive Timer Layout
                  if (isLandscape)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (hours > 0) ...[
                          _buildTimeBlock(
                            hours.toString().padLeft(2, '0'),
                            Colors.white,
                            true,
                          ),
                          _buildSeparator(),
                        ],
                        _buildTimeBlock(
                          minutes.toString().padLeft(2, '0'),
                          Colors.white,
                          true,
                        ),
                        _buildSeparator(),
                        _buildTimeBlock(
                          seconds.toString().padLeft(2, '0'),
                          Colors.white,
                          true,
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        if (hours > 0)
                          _buildTimeBlock(
                            hours.toString().padLeft(2, '0'),
                            Colors.white,
                            false,
                          ),
                        _buildTimeBlock(
                          minutes.toString().padLeft(2, '0'),
                          Colors.white,
                          false,
                        ),
                        _buildTimeBlock(
                          seconds.toString().padLeft(2, '0'),
                          Colors.white,
                          false,
                        ),
                      ],
                    ),
                  const Spacer(),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: isLandscape ? 10 : 40,
                    ),
                    child: _HoldToEjectButton(
                      onEject: () {
                        sessionProvider.emergencyStop(context);
                      },
                      onInteraction: _resetInactivityTimer,
                    ),
                  ),
                ],
              ),
              if (_showNotifications) _buildNotificationPanel(),
            ],
          ),
        ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationPanel() {
    if (_notifications.isEmpty) {
      return Positioned(
        top: 56,
        left: 16,
        right: 16,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1B1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF332D2D)),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.notifications_off_rounded,
                color: Color(0xFF666666),
                size: 18,
              ),
              SizedBox(width: 12),
              Text(
                'No notifications yet',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF888888),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Positioned(
      top: 56,
      left: 12,
      right: 12,
      child: Container(
        height: 260,
        decoration: BoxDecoration(
          color: const Color(0xFF1B1817),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF332D2D)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'NOTIFICATIONS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF888888),
                      letterSpacing: 2.0,
                    ),
                  ),
                  Text(
                    '${_notifications.length} new',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.primaryAccent,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFF2A2625),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: _notifications.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  return _NotificationCard(notification: _notifications[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeBlock(String value, Color color, bool isLandscape) {
    return Text(
      value,
      style: TextStyle(
        fontSize: isLandscape ? 100 : 160,
        fontWeight: FontWeight.w900,
        color: color,
        height: 0.9,
        letterSpacing: -8.0,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }

  Widget _buildSeparator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 16),
      child: Text(
        ':',
        style: TextStyle(
          fontSize: 70,
          fontWeight: FontWeight.w900,
          color: Colors.white54,
        ),
      ),
    );
  }
}

class _HoldToEjectButton extends StatefulWidget {
  final VoidCallback onEject;
  final VoidCallback onInteraction;

  const _HoldToEjectButton({
    required this.onEject,
    required this.onInteraction,
  });

  @override
  State<_HoldToEjectButton> createState() => _HoldToEjectButtonState();
}

class _HoldToEjectButtonState extends State<_HoldToEjectButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isEjected = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _controller.addListener(() {
      setState(() {});
      if (_controller.isCompleted && !_isEjected) {
        _isEjected = true;
        widget.onEject();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        widget.onInteraction();
        if (!_isEjected) _controller.forward();
      },
      onTapUp: (_) {
        widget.onInteraction();
        if (!_isEjected) _controller.reverse();
      },
      onTapCancel: () {
        if (!_isEjected) _controller.reverse();
      },
      child: Container(
        height: 64,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFF2A2A2A), width: 1.5),
        ),
        child: Stack(
          children: [
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _controller.value,
              child: Container(
                decoration: BoxDecoration(
                  color: AppConstants.primaryAccent,
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
            ),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.flight_takeoff_rounded,
                    color: _controller.value > 0.4
                        ? AppConstants.textDark
                        : AppConstants.primaryAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _controller.isCompleted ? 'EJECTING...' : 'HOLD TO EJECT',
                    style: TextStyle(
                      color: _controller.value > 0.4
                          ? AppConstants.textDark
                          : const Color(0xFF777777),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF24201F),
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(
            color: AppConstants.primaryAccent.withOpacity(0.6),
            width: 3,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AppIcon(iconBase64: notification.iconBase64),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        notification.appName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppConstants.primaryAccent,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('h:mm a').format(notification.postTime),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF777777),
                      ),
                    ),
                  ],
                ),
                if (notification.title.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    notification.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
                if (notification.text.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    notification.text,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  final String? iconBase64;

  const _AppIcon({this.iconBase64});

  @override
  Widget build(BuildContext context) {
    Widget icon;
    if (iconBase64 != null && iconBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(iconBase64!);
        icon = Image.memory(
          bytes,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => _fallbackIcon(),
        );
      } catch (_) {
        icon = _fallbackIcon();
      }
    } else {
      icon = _fallbackIcon();
    }

    return Container(
      width: 36,
      height: 36,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1716),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF332D2D)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: icon,
      ),
    );
  }

  Widget _fallbackIcon() {
    return const Icon(
      Icons.notifications_rounded,
      color: AppConstants.primaryAccent,
      size: 18,
    );
  }
}