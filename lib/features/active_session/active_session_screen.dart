import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/stats_provider.dart';
import '../../core/constants/app_constants.dart';

class ActiveSessionScreen extends StatelessWidget {
  const ActiveSessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionProvider = context.watch<SessionProvider>();
    final statsProvider = context.watch<StatsProvider>();
    final bool canUseParachute = statsProvider.parachutesUsed < 1;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        // Swallow all back gestures during a session
      },
      child: Scaffold(
        backgroundColor: AppConstants.textPrimary, // near-black
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                // ── Top label ─────────────────────────────────────────
                const SizedBox(height: 56),
                const Text(
                  'SESSION ACTIVE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF666666),
                    letterSpacing: 2.5,
                  ),
                ),

                const Spacer(),

                // ── Big countdown ──────────────────────────────────────
                Text(
                  sessionProvider.formattedTime,
                  style: const TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.w200,
                    color: Colors.white,
                    letterSpacing: -4,
                    height: 1,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'remaining',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF666666),
                    letterSpacing: 0.5,
                  ),
                ),

                const Spacer(),

                // ── Divider ────────────────────────────────────────────
                Container(
                  width: 40,
                  height: 1,
                  color: const Color(0xFF333333),
                ),

                const SizedBox(height: 32),

                // ── Parachute section ──────────────────────────────────
                if (canUseParachute)
                  _ParachuteButton(
                    onTap: () => _showParachuteDialog(context, sessionProvider),
                  )
                else
                  const Text(
                    'Parachute already used',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF555555),
                      letterSpacing: 0.3,
                    ),
                  ),

                const SizedBox(height: 52),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showParachuteDialog(
      BuildContext context, SessionProvider sessionProvider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppConstants.primaryOrange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.flight_takeoff_rounded,
                    color: AppConstants.primaryOrange, size: 24),
              ),
              const SizedBox(height: 20),
              const Text(
                'Use your parachute?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This will end your session early.\nYou only get one — use it wisely.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF888888),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF888888),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        sessionProvider.emergencyStop(context);
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppConstants.primaryOrange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Eject',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParachuteButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ParachuteButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flight_takeoff_rounded,
                color: AppConstants.primaryOrange, size: 18),
            const SizedBox(width: 10),
            const Text(
              'USE PARACHUTE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppConstants.primaryOrange,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}