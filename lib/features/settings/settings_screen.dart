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

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDeviceAdminActive = false;

  @override
  void initState() {
    super.initState();
    _checkDeviceAdminStatus();
  }

  Future<void> _checkDeviceAdminStatus() async {
    final active = await PlatformChannelHelper.isDeviceAdminActive();
    if (mounted) setState(() => _isDeviceAdminActive = active);
  }

  Future<void> _activateDeviceAdmin() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Activate Device Admin'),
        content: const Text(
          'To enable full phone lockdown:\n\n'
          '1. Tap Activate\n'
          '2. Go to Settings → Security → Device admin apps\n'
          '3. Enable "blockit_clone"',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await PlatformChannelHelper.startLockTask();
              await _checkDeviceAdminStatus();
            },
            child: const Text('Activate', style: TextStyle(color: AppConstants.primaryOrange)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isDeviceAdminActive ? Icons.verified : Icons.security,
                        color: _isDeviceAdminActive ? Colors.green : AppConstants.primaryOrange,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Device Admin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('Required for complete phone lock'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isDeviceAdminActive ? null : _activateDeviceAdmin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isDeviceAdminActive ? Colors.green : AppConstants.primaryOrange,
                      ),
                      child: Text(_isDeviceAdminActive ? 'Device Admin Active' : 'Activate Device Admin'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Parachute Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Parachute (Emergency Exit)', 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('You get 1 free parachute to exit a session early.'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Used: ', style: TextStyle(fontSize: 16)),
                      Text(
                        '${stats.parachutesUsed} / 1',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: stats.parachutesUsed >= 1 ? Colors.orange : AppConstants.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (stats.parachutesUsed >= 1)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('You have used your free parachute.', 
                          style: TextStyle(color: Colors.orange)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}