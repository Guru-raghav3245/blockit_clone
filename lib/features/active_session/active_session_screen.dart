import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/session_provider.dart';
import '../../core/constants/app_constants.dart';

class ActiveSessionScreen extends StatefulWidget {
  const ActiveSessionScreen({super.key});

  @override
  State<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends State<ActiveSessionScreen> {
  Timer? _inactivityTimer;
  bool _isDimmed = false;
  late SessionProvider _sessionProvider;

  @override
  void initState() {
    super.initState();
    _sessionProvider = context.read<SessionProvider>();
    _resetInactivityTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sessionProvider.onUndimRequested = _undim;
    });
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
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
            ),
          ),
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
                  color: AppConstants.primaryOrange,
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
                        ? Colors.white
                        : AppConstants.primaryOrange,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _controller.isCompleted ? 'EJECTING...' : 'HOLD TO EJECT',
                    style: TextStyle(
                      color: _controller.value > 0.4
                          ? Colors.white
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
