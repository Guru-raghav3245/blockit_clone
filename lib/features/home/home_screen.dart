import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blockit_clone/core/constants/app_constants.dart';
import 'package:blockit_clone/providers/session_provider.dart';
import 'widgets/analog_wheel_picker.dart';
import 'widgets/start_session_button.dart';
import 'package:blockit_clone/features/settings/settings_screen.dart';
import 'package:blockit_clone/features/stats/stats_screen.dart';
import 'package:blockit_clone/core/utils/platform_channel_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedDuration = 30;
  bool _isAccessibilityEnabled = false;
  bool _isDeviceAdminActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkStatuses();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Re-check when user returns from Settings or Accessibility screen
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkStatuses();
    }
  }

  Future<void> _checkStatuses() async {
    final admin = await PlatformChannelHelper.isDeviceAdminActive();
    final accessibility =
        await PlatformChannelHelper.isAccessibilityServiceEnabled();
    if (mounted) {
      setState(() {
        _isDeviceAdminActive = admin;
        _isAccessibilityEnabled = accessibility;
      });
    }
  }

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
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              // Refresh statuses when returning from settings
              _checkStatuses();
            },
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

              // Setup warning banners
              if (!_isDeviceAdminActive || !_isAccessibilityEnabled) ...[
                const SizedBox(height: 16),
                _buildSetupBanner(context),
              ],

              const SizedBox(height: 30),

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
                    // Only show this snackbar if accessibility IS enabled
                    // but device admin failed (accessibility dialog handles the other case)
                    final accessOk =
                        await PlatformChannelHelper.isAccessibilityServiceEnabled();
                    if (accessOk) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Please activate Device Admin first in Settings'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
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

  Widget _buildSetupBanner(BuildContext context) {
    final List<String> missing = [];
    if (!_isDeviceAdminActive) missing.add('Device Admin');
    if (!_isAccessibilityEnabled) missing.add('Accessibility Service');

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
        _checkStatuses();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.orange, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Setup required: ${missing.join(' & ')} not enabled. Tap to fix →',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}