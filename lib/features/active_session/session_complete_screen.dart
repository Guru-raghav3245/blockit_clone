import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/stats_provider.dart';

class SessionCompleteScreen extends StatelessWidget {
  final int sessionDuration;

  const SessionCompleteScreen({super.key, required this.sessionDuration});

  @override
  Widget build(BuildContext context) {
    final statsProvider = context.watch<StatsProvider>();

    // Calculate today's total accumulated time
    final today = DateTime.now();
    int todayMinutes = 0;
    for (var s in statsProvider.sessions) {
      if (s.startTime.year == today.year &&
          s.startTime.month == today.month &&
          s.startTime.day == today.day) {
        todayMinutes += s.durationMinutes;
      }
    }

    return PopScope(
      canPop: false, // Force them to use the checkmark button
      onPopInvokedWithResult: (didPop, result) async {},
      child: Scaffold(
        backgroundColor: Colors.black, // Deep black background
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // TOP LOGO
                const Text(
                  AppConstants.appName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: Colors.white,
                  ),
                ),

                const Spacer(),

                // CONGRATULATIONS CARD
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: double.infinity,
                    color: AppConstants.cardColor,
                    child: Stack(
                      children: [
                        // Abstract Background Ring 1
                        Positioned(
                          right: -30,
                          top: -20,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppConstants.primaryOrange,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        // Abstract Background Ring 2
                        Positioned(
                          left: -40,
                          bottom: 20,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppConstants.primaryOrange,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        // Abstract Dark Square
                        Positioned(
                          bottom: 30,
                          right: 120,
                          child: Transform.rotate(
                            angle: 0.2,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppConstants.borderColor,
                                  width: 4,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Card Content
                        Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Congratulations',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'You completed a $sessionDuration minute session',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 48),

                              // Share Button
                              GestureDetector(
                                onTap: () {
                                  Share.share(
                                    'I just reclaimed $sessionDuration minutes of my time using blockit! 🚀',
                                    subject: 'blockit focus session',
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.share_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Share',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // GIANT DISMISS BUTTON (Checkmark)
                GestureDetector(
                  onTap: () {
                    // Return to the home screen
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: Container(
                    width: double.infinity,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(36), // Pill shape
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.black,
                      size: 32,
                    ),
                  ),
                ),

                const Spacer(),

                // BOTTOM SUMMARY
                Text(
                  'Today, you accumulated $todayMinutes\nminutes with no distractions',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
