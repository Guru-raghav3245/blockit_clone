import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/stats_provider.dart';

class ActiveSessionScreen extends StatefulWidget {
  const ActiveSessionScreen({super.key});

  @override
  State<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends State<ActiveSessionScreen> {
  @override
  Widget build(BuildContext context) {
    final sessionProvider = context.watch<SessionProvider>();
    final statsProvider = context.watch<StatsProvider>();

    final bool canUseParachute = statsProvider.parachutesUsed < 1;

    return PopScope(
      canPop: false, // Stronger prevention
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // Ignore all back gestures while session is active
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 120,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'FREEDOM SESSION',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your phone is locked',
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                  const SizedBox(height: 60),

                  // Big Countdown
                  Text(
                    sessionProvider.formattedTime,
                    style: const TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                      letterSpacing: -4,
                    ),
                  ),

                  const SizedBox(height: 100),

                  // Parachute Section
                  if (canUseParachute)
                    TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => AlertDialog(
                            backgroundColor: Colors.grey[900],
                            title: const Text(
                              'Use Parachute?',
                              style: TextStyle(color: Colors.white),
                            ),
                            content: const Text(
                              'This will end your freedom session early.\n\n'
                              'You have 1 free parachute.',
                              style: TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  sessionProvider.emergencyStop(context);
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  'Use Parachute',
                                  style: TextStyle(color: Colors.orange),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.flight_takeoff,
                        color: Colors.orange,
                      ),
                      label: const Text(
                        'USE PARACHUTE',
                        style: TextStyle(color: Colors.orange, fontSize: 16),
                      ),
                    )
                  else
                    const Text(
                      'You have already used your free parachute',
                      style: TextStyle(color: Colors.orange, fontSize: 15),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
