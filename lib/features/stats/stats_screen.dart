import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/stats_provider.dart';
import '../../models/freedom_session.dart';
import '../../services/local_storage_service.dart';
import 'widgets/session_list.dart';

class StatsScreen extends StatefulWidget {
  final int currentTab;

  const StatsScreen({super.key, required this.currentTab});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _selectedFilterIndex = 1; // 0: Day, 1: Week, 2: Month
  int? _touchedBarIndex;

  @override
  void initState() {
    super.initState();
    context.read<StatsProvider>().loadStats();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    final savedFilter = await LocalStorageService.getLastStatsFilter();
    if (mounted) {
      setState(() {
        _selectedFilterIndex = savedFilter;
      });
    }
  }

  // ─── STAT CALCULATIONS ──────────────────────────────────────────────────

  int _getDisciplineScore(StatsProvider stats) {
    if (stats.totalSessions == 0) return 100;
    final int successful = stats.totalSessions - stats.parachutesUsed;
    return ((successful / stats.totalSessions) * 100).clamp(0, 100).toInt();
  }

  int _getLongestBlock(List<FreedomSession> sessions) {
    if (sessions.isEmpty) return 0;
    return sessions
        .map((s) => s.durationMinutes)
        .reduce((a, b) => a > b ? a : b);
  }

  String _getPrimeTime(List<FreedomSession> sessions) {
    if (sessions.isEmpty) return "Not enough data";
    int morning = 0, afternoon = 0, night = 0;
    for (var s in sessions) {
      final hour = s.startTime.hour;
      if (hour >= 5 && hour < 12)
        morning++;
      else if (hour >= 12 && hour < 18)
        afternoon++;
      else
        night++;
    }
    if (morning >= afternoon && morning >= night) return "Morning Bird";
    if (afternoon >= morning && afternoon >= night) return "Afternoon Focus";
    return "Night Owl";
  }

  int _calculateStreak(List<FreedomSession> sessions) {
    if (sessions.isEmpty) return 0;

    final activeDays = sessions
        .map((s) {
          return DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
        })
        .toSet()
        .toList();

    activeDays.sort((a, b) => b.compareTo(a));

    int streak = 0;
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    DateTime currentDate = today;

    if (!activeDays.contains(today) &&
        !activeDays.contains(today.subtract(const Duration(days: 1)))) {
      return 0;
    }

    if (activeDays.contains(today)) {
      currentDate = today;
    } else {
      currentDate = today.subtract(const Duration(days: 1));
    }

    for (var day in activeDays) {
      if (day.isAtSameMomentAs(currentDate)) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else if (day.isBefore(currentDate)) {
        break;
      }
    }
    return streak;
  }

  // ─── DYNAMIC CHART DATA GEN ─────────────────────────────────────────────

  List<_ChartBarData> _getChartData(StatsProvider stats) {
    final now = DateTime.now();
    List<_ChartBarData> data = [];

    if (_selectedFilterIndex == 0) {
      List<double> values = List.filled(6, 0.0);
      for (var s in stats.sessions) {
        if (s.startTime.day == now.day &&
            s.startTime.month == now.month &&
            s.startTime.year == now.year) {
          int block = s.startTime.hour ~/ 4; // 0-5
          values[block] += s.durationMinutes;
        }
      }
      int currentBlock = now.hour ~/ 4;
      final labels = ['12A', '4A', '8A', '12P', '4P', '8P'];
      for (int i = 0; i < 6; i++) {
        data.add(
          _ChartBarData(labels[i], values[i], isCurrent: i == currentBlock),
        );
      }
    } else if (_selectedFilterIndex == 1) {
      List<double> values = List.filled(7, 0.0);

      DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      startOfWeek = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day,
      );

      for (var s in stats.sessions) {
        final sessionDate = DateTime(
          s.startTime.year,
          s.startTime.month,
          s.startTime.day,
        );
        final diff = sessionDate.difference(startOfWeek).inDays;
        if (diff >= 0 && diff < 7) {
          values[diff] += s.durationMinutes;
        }
      }

      for (int i = 0; i < 7; i++) {
        final d = startOfWeek.add(Duration(days: i));
        String letter = DateFormat('E').format(d)[0]; // M, T, W, etc.
        bool isCurrentDay =
            (d.day == now.day && d.month == now.month && d.year == now.year);

        data.add(
          _ChartBarData(
            "$letter\n${d.day}",
            values[i],
            isCurrent: isCurrentDay,
          ),
        );
      }
    } else if (_selectedFilterIndex == 2) {
      List<double> values = List.filled(4, 0.0);
      for (var s in stats.sessions) {
        if (s.startTime.month == now.month && s.startTime.year == now.year) {
          int day = s.startTime.day;
          if (day <= 7)
            values[0] += s.durationMinutes;
          else if (day <= 14)
            values[1] += s.durationMinutes;
          else if (day <= 21)
            values[2] += s.durationMinutes;
          else
            values[3] += s.durationMinutes;
        }
      }

      int currentWeekIndex = now.day <= 7
          ? 0
          : now.day <= 14
          ? 1
          : now.day <= 21
          ? 2
          : 3;

      data = [
        _ChartBarData('W1\n1-7', values[0], isCurrent: currentWeekIndex == 0),
        _ChartBarData('W2\n8-14', values[1], isCurrent: currentWeekIndex == 1),
        _ChartBarData('W3\n15-21', values[2], isCurrent: currentWeekIndex == 2),
        _ChartBarData('W4\n22+', values[3], isCurrent: currentWeekIndex == 3),
      ];
    }

    return data;
  }

  // ─── BUILDER ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final statsProvider = context.watch<StatsProvider>();

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('STATS'),
        centerTitle: true,
      ),
      body: IndexedStack(
        index: widget.currentTab,
        children: [
          _buildOverviewTab(statsProvider),
          _buildTrendsTab(statsProvider),
          _buildHistoryTab(statsProvider),
        ],
      ),
    );
  }

  // ─── TAB 0: OVERVIEW ────────────────────────────────────────────────────

  Widget _buildOverviewTab(StatsProvider stats) {
    final totalHours = (stats.totalMinutes / 60).floor();
    final remainingMins = stats.totalMinutes % 60;
    final discipline = _getDisciplineScore(stats);
    final streak = _calculateStreak(stats.sessions);
    final longestBlock = _getLongestBlock(stats.sessions);
    final primeTime = _getPrimeTime(stats.sessions);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppConstants.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppConstants.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TOTAL TIME RECLAIMED',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.textMuted,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$totalHours',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: AppConstants.primaryOrange,
                      height: 1,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6, left: 4, right: 8),
                    child: Text(
                      'h',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppConstants.primaryOrange,
                      ),
                    ),
                  ),
                  Text(
                    '$remainingMins',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: AppConstants.primaryOrange,
                      height: 1,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6, left: 4),
                    child: Text(
                      'm',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppConstants.primaryOrange,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppConstants.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppConstants.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 56,
                          height: 56,
                          child: CircularProgressIndicator(
                            value: discipline / 100,
                            strokeWidth: 6,
                            backgroundColor: AppConstants.borderColor,
                            color: AppConstants.primaryOrange,
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Text(
                          '$discipline%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppConstants.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Discipline\nScore',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textSecondary,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppConstants.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppConstants.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryOrange.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        color: AppConstants.primaryOrange,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$streak Days',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    const Text(
                      'Current Streak',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppConstants.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppConstants.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.amber,
                      size: 28,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$longestBlock m',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    const Text(
                      'Longest Block',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppConstants.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppConstants.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      primeTime.contains('Night')
                          ? Icons.nightlight_round
                          : Icons.wb_sunny_rounded,
                      color: Colors.indigoAccent.shade100,
                      size: 28,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      primeTime,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    const Text(
                      'Prime Focus',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── TAB 1: TRENDS & CHARTS ──────────────────────────────────────────────

  Widget _buildTrendsTab(StatsProvider stats) {
    final chartData = _getChartData(stats);
    final maxMinutes = chartData.isEmpty
        ? 0
        : chartData.map((d) => d.value).reduce((a, b) => a > b ? a : b);
    final chartMax = maxMinutes > 0 ? maxMinutes : 60.0;

    String headerTitle = "Today";
    if (_selectedFilterIndex == 1) headerTitle = "This Week";
    if (_selectedFilterIndex == 2) headerTitle = "This Month";

    int periodSessions = 0;
    int periodParachutes = 0;
    final now = DateTime.now();

    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    startOfWeek = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );

    for (var s in stats.sessions) {
      bool include = false;
      if (_selectedFilterIndex == 0) {
        if (s.startTime.day == now.day &&
            s.startTime.month == now.month &&
            s.startTime.year == now.year)
          include = true;
      } else if (_selectedFilterIndex == 1) {
        final sessionDate = DateTime(
          s.startTime.year,
          s.startTime.month,
          s.startTime.day,
        );
        final diff = sessionDate.difference(startOfWeek).inDays;
        if (diff >= 0 && diff < 7) include = true;
      } else if (_selectedFilterIndex == 2) {
        if (s.startTime.month == now.month && s.startTime.year == now.year)
          include = true;
      }

      if (include) {
        periodSessions++;
        if (s.usedParachute) periodParachutes++;
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppConstants.cardColor,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppConstants.borderColor),
          ),
          child: Row(
            children: [
              _buildFilterOption(0, 'Day'),
              _buildFilterOption(1, 'Week'),
              _buildFilterOption(2, 'Month'),
            ],
          ),
        ),

        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          decoration: BoxDecoration(
            color: AppConstants.cardColor,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppConstants.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                headerTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppConstants.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _touchedBarIndex != null
                    ? '${chartData[_touchedBarIndex!].value.toInt()} minutes focused'
                    : '${chartData.map((e) => e.value).fold(0.0, (a, b) => a + b).toInt()} total minutes',
                style: TextStyle(
                  fontSize: 14,
                  color: _touchedBarIndex != null
                      ? AppConstants.primaryOrange
                      : AppConstants.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                height: 220,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(chartData.length, (index) {
                    final dataPoint = chartData[index];
                    final heightFactor = dataPoint.value / chartMax;
                    final isTouched = _touchedBarIndex == index;
                    final isCurrent = dataPoint.isCurrent;

                    Color barColor;
                    if (isTouched) {
                      barColor = AppConstants.primaryOrange;
                    } else if (isCurrent) {
                      barColor = AppConstants.primaryOrange.withOpacity(0.8);
                    } else if (dataPoint.value > 0) {
                      barColor = AppConstants.primaryOrange.withOpacity(0.3);
                    } else {
                      barColor = AppConstants.borderColor;
                    }

                    Color labelColor = (isTouched || isCurrent)
                        ? AppConstants.primaryOrange
                        : AppConstants.textMuted;

                    return GestureDetector(
                      onTapDown: (_) =>
                          setState(() => _touchedBarIndex = index),
                      onTapUp: (_) => setState(() => _touchedBarIndex = null),
                      onTapCancel: () =>
                          setState(() => _touchedBarIndex = null),
                      child: Container(
                        color: Colors.transparent,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: isTouched ? 1.0 : 0.0,
                              child: Text(
                                '${dataPoint.value.toInt()}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppConstants.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              width: chartData.length > 5 ? 32 : 44,
                              height: (heightFactor * 120).clamp(4.0, 120.0),
                              decoration: BoxDecoration(
                                color: barColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              dataPoint.label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isCurrent
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: labelColor,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: AppConstants.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppConstants.borderColor),
                ),
                child: Column(
                  children: [
                    Text(
                      '$periodSessions',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Sessions',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: AppConstants.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppConstants.borderColor),
                ),
                child: Column(
                  children: [
                    Text(
                      '$periodParachutes',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppConstants.primaryOrange,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Parachutes',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterOption(int index, String label) {
    final isSelected = _selectedFilterIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilterIndex = index;
            _touchedBarIndex = null;
          });
          // SAVE CHOICE
          LocalStorageService.saveLastStatsFilter(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppConstants.borderColor : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected
                  ? AppConstants.textPrimary
                  : AppConstants.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  // ─── TAB 2: HISTORY ──────────────────────────────────────────────────────

  Widget _buildHistoryTab(StatsProvider statsProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 14),
          child: Text(
            'ALL SESSIONS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppConstants.textMuted,
              letterSpacing: 2.0,
            ),
          ),
        ),
        Expanded(
          child: statsProvider.sessions.isEmpty
              ? const _EmptyState()
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SessionList(sessions: statsProvider.sessions),
                ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }
}

class _ChartBarData {
  final String label;
  final double value;
  final bool isCurrent;

  _ChartBarData(this.label, this.value, {this.isCurrent = false});
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
