import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blockit_clone/core/constants/app_constants.dart';
import 'package:blockit_clone/providers/session_provider.dart';
import 'widgets/analog_wheel_picker.dart';
import 'widgets/start_session_button.dart';
import 'package:blockit_clone/features/settings/settings_screen.dart';
import 'package:blockit_clone/features/stats/stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedDuration = 30;

  @override
  Widget build(BuildContext context) {
    final sessionProvider = context.watch<SessionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('blockit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StatsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Header
              Text(
                'How long do you want to be free?',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 28,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                'Phone will be completely locked',
                style: TextStyle(
                  fontSize: 16,
                  color: AppConstants.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 50),

              // Analog Wheel Picker
              AnalogWheelPicker(
                selectedMinutes: _selectedDuration,
                onDurationChanged: (minutes) {
                  setState(() => _selectedDuration = minutes);
                },
              ),

              const SizedBox(height: 20),

              // Selected time display
              Text(
                '$_selectedDuration minutes',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.primaryOrange,
                ),
              ),

              const Spacer(),

              // Start Button
              StartSessionButton(
                onPressed: () async {
                  final success = await sessionProvider.startSession(
                    _selectedDuration,
                    context,
                  );

                  if (!success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please activate Device Admin first in Settings'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
                isLoading: sessionProvider.isLocking,
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}