import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/stats_provider.dart';
import 'widgets/session_list.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<StatsProvider>().loadStats();
  }

  @override
  Widget build(BuildContext context) {
    final statsProvider = context.watch<StatsProvider>();
    final totalHours = (statsProvider.totalMinutes / 60).toStringAsFixed(1);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        // Colors inherited from AppTheme automatically
        automaticallyImplyLeading: false,
        title: const Text('STATS'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    value: statsProvider.totalSessions.toString(),
                    label: 'Sessions',
                    icon: Icons.repeat_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    value: totalHours,
                    label: 'Hours locked',
                    icon: Icons.timer_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    value: '${statsProvider.parachutesUsed}/1',
                    label: 'Parachutes',
                    icon: Icons.flight_takeoff_rounded,
                    accentColor: statsProvider.parachutesUsed >= 1
                        ? AppConstants.primaryOrange
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'HISTORY',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppConstants.textMuted,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: statsProvider.sessions.isEmpty
                  ? const _EmptyState()
                  : SessionList(sessions: statsProvider.sessions),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color? accentColor;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppConstants.primaryOrange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppConstants.textPrimary,
              letterSpacing: -0.5,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppConstants.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppConstants.cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.lock_clock_outlined,
              size: 32,
              color: AppConstants.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No sessions yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Start your first freedom session\nto see your progress here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppConstants.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
