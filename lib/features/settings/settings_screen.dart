import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/platform_channel_helper.dart';
import '../../providers/stats_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  bool _isDeviceAdminActive = false;
  bool _isAccessibilityEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkStatuses();
    context.read<StatsProvider>().loadStats();
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

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatsProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: const Icon(Icons.arrow_back_rounded,
                size: 20, color: Colors.white),
          ),
        ),
        title: const Text(
          'SETTINGS',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white70,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        children: [
          // ── Section: Permissions ────────────────────────────────────
          _SectionLabel(label: 'PERMISSIONS'),
          const SizedBox(height: 16),

          _PermissionTile(
            icon: Icons.security_rounded,
            title: 'Device Admin',
            subtitle: 'Required for Lock Task mode',
            isActive: _isDeviceAdminActive,
            onTap: _isDeviceAdminActive
                ? null
                : () async {
                    await PlatformChannelHelper.startLockTask();
                    await _checkStatuses();
                  },
          ),

          const SizedBox(height: 12),

          _PermissionTile(
            icon: Icons.accessibility_new_rounded,
            title: 'Accessibility Service',
            subtitle: 'Blocks swipe-to-exit gestures',
            isActive: _isAccessibilityEnabled,
            onTap: _isAccessibilityEnabled
                ? null
                : () async {
                    await PlatformChannelHelper.openAccessibilitySettings();
                  },
            hint: _isAccessibilityEnabled
                ? null
                : 'Find "Blockit Accessibility" in the list and enable it',
          ),

          const SizedBox(height: 40),

          // ── Section: Parachute ──────────────────────────────────────
          _SectionLabel(label: 'PARACHUTE'),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppConstants.primaryOrange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.flight_takeoff_rounded,
                      color: AppConstants.primaryOrange, size: 26),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Emergency exit',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You get one free parachute per session',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Usage badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: stats.parachutesUsed >= 1
                        ? AppConstants.primaryOrange.withOpacity(0.15)
                        : const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${stats.parachutesUsed}/1',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: stats.parachutesUsed >= 1
                          ? AppConstants.primaryOrange
                          : Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (stats.parachutesUsed >= 1) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: AppConstants.primaryOrange),
                  const SizedBox(width: 8),
                  const Text(
                    'Free parachute has been used.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppConstants.primaryOrange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Colors.white54,
        letterSpacing: 2.0,
      ),
    );
  }
}

// ── Permission Tile ───────────────────────────────────────────────────────────
class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isActive;
  final VoidCallback? onTap;
  final String? hint;

  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isActive,
    this.onTap,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(
                  hint != null && !isActive ? 16 : 20),
              border: Border.all(
                color: isActive
                    ? const Color(0xFF2E7D32).withOpacity(0.3)
                    : const Color(0xFF2A2A2A),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF2E7D32).withOpacity(0.15)
                        : const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    size: 26,
                    color: isActive
                        ? const Color(0xFF4CAF50)
                        : Colors.white70,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryOrange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Enable',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (hint != null && !isActive)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            decoration: const BoxDecoration(
              color: Color(0xFF2A2A2A),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border(
                left: BorderSide(color: Color(0xFF3A3A3A)),
                right: BorderSide(color: Color(0xFF3A3A3A)),
                bottom: BorderSide(color: Color(0xFF3A3A3A)),
              ),
            ),
            child: Text(
              hint!,
              style: TextStyle(
                fontSize: 13.5,
                color: AppConstants.primaryOrange,
                height: 1.5,
              ),
            ),
          ),
      ],
    );
  }
}