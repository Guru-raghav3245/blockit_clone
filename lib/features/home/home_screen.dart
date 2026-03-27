import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/session_provider.dart';
import '../../core/utils/platform_channel_helper.dart';
import 'widgets/analog_wheel_picker.dart';
import 'widgets/start_session_button.dart';
import '../settings/settings_screen.dart';
import '../stats/stats_screen.dart';

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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkStatuses();
  }

  Future<void> _checkStatuses() async {
    final admin = await PlatformChannelHelper.isDeviceAdminActive();
    final accessibility = await PlatformChannelHelper.isAccessibilityServiceEnabled();
    if (mounted) {
      setState(() {
        _isDeviceAdminActive = admin;
        _isAccessibilityEnabled = accessibility;
      });
    }
  }

  bool get _isFullySetup => _isDeviceAdminActive && _isAccessibilityEnabled;

  @override
  Widget build(BuildContext context) {
    final sessionProvider = context.watch<SessionProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'blockit',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1.0,
                    ),
                  ),
                  Row(
                    children: [
                      _TopBarButton(
                        icon: Icons.bar_chart_rounded,
                        onTap: () => Navigator.push(
                            context, MaterialPageRoute(builder: (_) => const StatsScreen())),
                      ),
                      const SizedBox(width: 12),
                      _TopBarButton(
                        icon: Icons.settings_outlined,
                        onTap: () async {
                          await Navigator.push(
                              context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                          _checkStatuses();
                        },
                        showDot: !_isFullySetup,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (!_isFullySetup)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: _SetupBanner(
                  isDeviceAdminActive: _isDeviceAdminActive,
                  isAccessibilityEnabled: _isAccessibilityEnabled,
                  onTap: () async {
                    await Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()));
                    _checkStatuses();
                  },
                ),
              ),

            const Spacer(),

            // Large Timer Display
            Text(
              '$_selectedDuration',
              style: const TextStyle(
                fontSize: 110,
                fontWeight: FontWeight.w300,
                color: Colors.white,
                height: 1.0,
                letterSpacing: -8,
              ),
            ),
            const Text(
              'MINUTES',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 3.5,
                color: Colors.white54,
              ),
            ),

            const SizedBox(height: 32),

            // Analog Wheel Picker
            AnalogWheelPicker(
              selectedMinutes: _selectedDuration,
              onDurationChanged: (minutes) => setState(() => _selectedDuration = minutes),
            ),

            const Spacer(),

            // Start Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: StartSessionButton(
                onPressed: () async {
                  final success = await sessionProvider.startSession(
                      _selectedDuration, context);
                  if (!success && mounted) {
                    final accessOk = await PlatformChannelHelper.isAccessibilityServiceEnabled();
                    if (accessOk) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Activate Device Admin in Settings first'),
                          backgroundColor: Color(0xFF1A1A1A),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                isLoading: sessionProvider.isLocking,
              ),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

// Top Bar Button
class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool showDot;

  const _TopBarButton({required this.icon, required this.onTap, this.showDot = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Icon(icon, size: 22, color: Colors.white),
          ),
          if (showDot)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppConstants.primaryOrange,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Setup Banner
class _SetupBanner extends StatelessWidget {
  final bool isDeviceAdminActive;
  final bool isAccessibilityEnabled;
  final VoidCallback onTap;

  const _SetupBanner({
    required this.isDeviceAdminActive,
    required this.isAccessibilityEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> missing = [];
    if (!isDeviceAdminActive) missing.add('Device Admin');
    if (!isAccessibilityEnabled) missing.add('Accessibility');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0).withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppConstants.primaryOrange.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppConstants.primaryOrange, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${missing.join(' & ')} not set up — tap to fix',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppConstants.primaryOrange, size: 20),
          ],
        ),
      ),
    );
  }
}