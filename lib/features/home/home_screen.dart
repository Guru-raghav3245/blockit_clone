import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blockit_clone/core/constants/app_constants.dart';
import 'package:blockit_clone/providers/session_provider.dart';
import 'package:blockit_clone/core/utils/platform_channel_helper.dart';
import 'widgets/analog_wheel_picker.dart';
import 'widgets/start_session_button.dart';
import 'package:blockit_clone/features/settings/settings_screen.dart';
import 'package:blockit_clone/features/stats/stats_screen.dart';

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
    final accessibility =
        await PlatformChannelHelper.isAccessibilityServiceEnabled();
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
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'blockit',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppConstants.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Row(
                    children: [
                      _TopBarButton(
                        icon: Icons.bar_chart_rounded,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const StatsScreen())),
                      ),
                      const SizedBox(width: 8),
                      _TopBarButton(
                        icon: Icons.settings_outlined,
                        onTap: () async {
                          await Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) => const SettingsScreen()));
                          _checkStatuses();
                        },
                        showDot: !_isFullySetup,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Setup Banner ─────────────────────────────────────────
            if (!_isFullySetup)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: _SetupBanner(
                  isDeviceAdminActive: _isDeviceAdminActive,
                  isAccessibilityEnabled: _isAccessibilityEnabled,
                  onTap: () async {
                    await Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen()));
                    _checkStatuses();
                  },
                ),
              ),

            const Spacer(),

            // ── Subtitle label ───────────────────────────────────────
            const Text(
              'LOCK YOUR PHONE FOR',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppConstants.textSecondary,
                letterSpacing: 2.0,
              ),
            ),

            const SizedBox(height: 28),

            // ── Wheel Picker ─────────────────────────────────────────
            AnalogWheelPicker(
              selectedMinutes: _selectedDuration,
              onDurationChanged: (minutes) =>
                  setState(() => _selectedDuration = minutes),
            ),

            const SizedBox(height: 20),

            // ── Duration readout ─────────────────────────────────────
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$_selectedDuration',
                    style: const TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w800,
                      color: AppConstants.textPrimary,
                      letterSpacing: -2,
                      height: 1,
                    ),
                  ),
                  const TextSpan(
                    text: ' min',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: AppConstants.textSecondary,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // ── Start Button ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: StartSessionButton(
                onPressed: () async {
                  final success = await sessionProvider.startSession(
                      _selectedDuration, context);
                  if (!success && mounted) {
                    final accessOk = await PlatformChannelHelper
                        .isAccessibilityServiceEnabled();
                    if (accessOk) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                              'Activate Device Admin in Settings first'),
                          backgroundColor: AppConstants.textPrimary,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  }
                },
                isLoading: sessionProvider.isLocking,
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool showDot;

  const _TopBarButton(
      {required this.icon, required this.onTap, this.showDot = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppConstants.textPrimary.withOpacity(0.1)),
            ),
            child: Icon(icon, size: 20, color: AppConstants.textPrimary),
          ),
          if (showDot)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: AppConstants.primaryOrange,
                    shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
  }
}

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
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFCC80)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppConstants.primaryOrange, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${missing.join(' & ')} not set up — tap to fix',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.primaryOrange,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppConstants.primaryOrange, size: 16),
          ],
        ),
      ),
    );
  }
}