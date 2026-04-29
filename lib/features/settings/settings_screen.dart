import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/platform_channel_helper.dart';

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
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('SETTINGS'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 110),
        children: [
          const _SectionLabel(label: 'PERMISSIONS'),
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
        ],
      ),
    );
  }
}

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
        color: AppConstants.textMuted,
        letterSpacing: 2.0,
      ),
    );
  }
}

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
              color: AppConstants.cardColor,
              borderRadius: BorderRadius.circular(
                hint != null && !isActive ? 16 : 20,
              ),
              border: Border.all(
                color: isActive
                    ? AppConstants.successGreen.withOpacity(0.4)
                    : AppConstants.borderColor,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppConstants.successGreen.withOpacity(0.15)
                        : AppConstants.borderColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    size: 26,
                    color: isActive
                        ? AppConstants.successGreen
                        : AppConstants.textMuted,
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
                          color: AppConstants.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppConstants.textSecondary,
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
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppConstants.successGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppConstants.successGreen,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Enable',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppConstants.textDark,
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
            decoration: BoxDecoration(
              color: AppConstants.borderColor.withOpacity(0.4),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: const Border(
                left: BorderSide(color: AppConstants.borderColor),
                right: BorderSide(color: AppConstants.borderColor),
                bottom: BorderSide(color: AppConstants.borderColor),
              ),
            ),
            child: Text(
              hint!,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppConstants.primaryAccent,
                height: 1.5,
              ),
            ),
          ),
      ],
    );
  }
}
