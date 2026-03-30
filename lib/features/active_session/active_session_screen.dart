import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/session_provider.dart';
import '../../core/constants/app_constants.dart';

class ActiveSessionScreen extends StatelessWidget {
  const ActiveSessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionProvider = context.watch<SessionProvider>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {},
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const SizedBox(height: 60),
                const Text(
                  'SESSION ACTIVE',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF666666),
                    letterSpacing: 3.0,
                  ),
                ),

                const Spacer(),

                Text(
                  sessionProvider.formattedTime,
                  style: const TextStyle(
                    fontSize: 110,
                    fontWeight: FontWeight.w200,
                    color: Colors.white,
                    letterSpacing: -6,
                    height: 1.0,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),

                const Text(
                  'remaining',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                    letterSpacing: 1.0,
                  ),
                ),

                const Spacer(),

                Container(width: 50, height: 1, color: const Color(0xFF333333)),

                const SizedBox(height: 48),

                // Button is now always available
                _ParachuteButton(
                  onTap: () => _showParachuteDialog(context, sessionProvider),
                ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showParachuteDialog(
    BuildContext context,
    SessionProvider sessionProvider,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppConstants.primaryOrange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.flight_takeoff_rounded,
                  color: AppConstants.primaryOrange,
                  size: 28,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Use your parachute?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'This will end your session early.', // Removed the "You only get one" text
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        sessionProvider.emergencyStop(context);
                      },
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppConstants.primaryOrange,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Eject',
                          style: TextStyle(
                            fontSize: 15,
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
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppConstants.primaryOrange.withOpacity(0.4),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.flight_takeoff_rounded,
              color: AppConstants.primaryOrange,
              size: 20,
            ),
            SizedBox(width: 12),
            Text(
              'USE PARACHUTE',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppConstants.primaryOrange,
                letterSpacing: 1.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
