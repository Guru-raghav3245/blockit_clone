import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/session_provider.dart';
import '../../core/constants/app_constants.dart';

class ActiveSessionScreen extends StatelessWidget {
  const ActiveSessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionProvider = context.watch<SessionProvider>();
    final remaining = sessionProvider.remainingSeconds;

    // Calculate time breakdown
    final hours = remaining ~/ 3600;
    final minutes = (remaining % 3600) ~/ 60;
    final seconds = remaining % 60;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {},
      child: Scaffold(
        backgroundColor: Colors
            .black, // Absolute black for OLED battery saving & anti-distraction
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),

              // ─── HARSH TRUTH HEADER ───
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

              // ─── BRUTALIST VERTICAL TIMER ───
              // Hours (Only appears if >= 1 hour)
              if (hours > 0) ...[
                _buildTimeBlock(hours.toString().padLeft(2, '0'), Colors.white),
              ],

              // Minutes (Stark White)
              _buildTimeBlock(minutes.toString().padLeft(2, '0'), Colors.white),

              // Seconds (Muted Grey to reduce anxiety)
              _buildTimeBlock(
                seconds.toString().padLeft(2, '0'),
                const Color(0xFF333333),
              ),

              const Spacer(),

              // ─── HOLD TO EJECT BUTTON ───
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 40,
                ),
                child: _HoldToEjectButton(
                  onEject: () {
                    sessionProvider.emergencyStop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for the massive brutalist text blocks
  Widget _buildTimeBlock(String value, Color color) {
    return Text(
      value,
      style: TextStyle(
        fontSize: 160,
        fontWeight: FontWeight.w900,
        color: color,
        height: 0.9, // Tight line height makes them stack like a solid wall
        letterSpacing: -8.0,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

// ─── CUSTOM "HOLD TO EJECT" FRICTION BUTTON ───

class _HoldToEjectButton extends StatefulWidget {
  final VoidCallback onEject;

  const _HoldToEjectButton({required this.onEject});

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
    // 3 Seconds of psychological friction
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _controller.addListener(() {
      setState(() {});
      // Trigger eject exact moment the bar fills
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
      // Press and hold mechanics
      onTapDown: (_) {
        if (!_isEjected) _controller.forward();
      },
      onTapUp: (_) {
        if (!_isEjected) _controller.reverse();
      },
      onTapCancel: () {
        if (!_isEjected) _controller.reverse();
      },
      child: Container(
        height: 64,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF151515), // Very dark charcoal
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFF2A2A2A), width: 1.5),
        ),
        child: Stack(
          children: [
            // The filling orange bar
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

            // Text and Icon overlay
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.flight_takeoff_rounded,
                    // Changes to white as the orange background fills behind it
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
