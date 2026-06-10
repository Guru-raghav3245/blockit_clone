import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/stats_provider.dart';
import '../../models/freedom_session.dart';
import '../../models/reels_free_time_record.dart';
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
  int _activeMetricIndex =
      0; // 0: Full Focus Lock Time, 1: Clean Reels-Free Time
  int? _touchedBarIndex;

  late PageController _pageController;
  int _currentPageIndex = 10000;
  final int _virtualCenter = 10000;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _virtualCenter);
    context.read<StatsProvider>().loadStats();
    _loadUserPreferences();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserPreferences() async {
    final savedFilter = await LocalStorageService.getLastStatsFilter();
    if (mounted) {
      setState(() {
        _selectedFilterIndex = savedFilter;
      });
    }
  }

  int _getLongestBlock(List<FreedomSession> sessions) {
    final cleanSessions = sessions.where((s) => !s.usedParachute);
    if (cleanSessions.isEmpty) return 0;
    return cleanSessions
        .map((s) => s.durationMinutes)
        .reduce((a, b) => a > b ? a : b);
  }

  String _getPrimeTime(List<FreedomSession> sessions) {
    final cleanSessions = sessions.where((s) => !s.usedParachute);
    if (cleanSessions.isEmpty) return "Not enough data";

    int morningMinutes = 0, afternoonMinutes = 0, nightMinutes = 0;
    for (var s in cleanSessions) {
      final hour = s.startTime.hour;
      if (hour >= 5 && hour < 12)
        morningMinutes += s.durationMinutes;
      else if (hour >= 12 && hour < 18)
        afternoonMinutes += s.durationMinutes;
      else
        nightMinutes += s.durationMinutes;
    }
    if (morningMinutes == 0 && afternoonMinutes == 0 && nightMinutes == 0)
      return "No Focus Time";
    if (morningMinutes >= afternoonMinutes && morningMinutes >= nightMinutes)
      return "Morning Bird";
    if (afternoonMinutes >= morningMinutes && afternoonMinutes >= nightMinutes)
      return "Afternoon Focus";
    return "Night Owl";
  }

  int _calculateStreak(List<FreedomSession> sessions) {
    if (sessions.isEmpty) return 0;
    final validSessions = sessions.where(
      (s) => !s.usedParachute && s.durationMinutes > 0,
    );
    if (validSessions.isEmpty) return 0;

    final activeDays = validSessions
        .map(
          (s) => DateTime(s.startTime.year, s.startTime.month, s.startTime.day),
        )
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
        !activeDays.contains(today.subtract(const Duration(days: 1))))
      return 0;
    currentDate = activeDays.contains(today)
        ? today
        : today.subtract(const Duration(days: 1));

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

  DateTime _getTargetDateForPage(int pageIndex) {
    final int offset = pageIndex - _virtualCenter;
    final now = DateTime.now();
    if (_selectedFilterIndex == 0)
      return DateTime(now.year, now.month, now.day).add(Duration(days: offset));
    if (_selectedFilterIndex == 1)
      return DateTime(
        now.year,
        now.month,
        now.day,
      ).add(Duration(days: offset * 7));
    return DateTime(now.year, now.month + offset, 1);
  }

  List<_ChartBarData> _getChartDataForPage(
    DateTime targetDate,
    Map<String, List<FreedomSession>> cleanSessionsByDay,
    Map<String, List<FreedomSession>> cleanSessionsByMonth,
    Map<String, List<ReelsFreeTimeRecord>> reelsFreeByDay,
    Map<String, List<ReelsFreeTimeRecord>> reelsFreeByMonth,
  ) {
    final now = DateTime.now();
    List<_ChartBarData> data = [];

    if (_selectedFilterIndex == 0) {
      List<double> values = List.filled(6, 0.0);
      final dayKey =
          "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";

      if (_activeMetricIndex == 0) {
        final daySessions = cleanSessionsByDay[dayKey] ?? [];
        for (var s in daySessions) {
          values[s.startTime.hour ~/ 4] += s.durationMinutes;
        }
      } else {
        final dayRecords = reelsFreeByDay[dayKey] ?? [];
        for (var r in dayRecords) {
          values[r.timestamp.hour ~/ 4] += r.durationMinutes;
        }
      }

      int currentBlock = now.hour ~/ 4;
      bool isToday =
          targetDate.day == now.day &&
          targetDate.month == now.month &&
          targetDate.year == now.year;
      final labels = ['12A', '4A', '8A', '12P', '4P', '8P'];
      for (int i = 0; i < 6; i++) {
        data.add(
          _ChartBarData(
            labels[i],
            values[i],
            isCurrent: isToday && (i == currentBlock),
          ),
        );
      }
    } else if (_selectedFilterIndex == 1) {
      List<double> values = List.filled(7, 0.0);
      DateTime startOfWeek = targetDate.subtract(
        Duration(days: targetDate.weekday - 1),
      );
      startOfWeek = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day,
      );

      for (int i = 0; i < 7; i++) {
        final d = startOfWeek.add(Duration(days: i));
        final dayKey =
            "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

        if (_activeMetricIndex == 0) {
          final daySessions = cleanSessionsByDay[dayKey] ?? [];
          for (var s in daySessions) {
            values[i] += s.durationMinutes;
          }
        } else {
          final dayRecords = reelsFreeByDay[dayKey] ?? [];
          for (var r in dayRecords) {
            values[i] += r.durationMinutes;
          }
        }
      }

      for (int i = 0; i < 7; i++) {
        final d = startOfWeek.add(Duration(days: i));
        bool isCurrentDay =
            (d.day == now.day && d.month == now.month && d.year == now.year);
        data.add(
          _ChartBarData(
            "${DateFormat('E').format(d)[0]}\n${d.day}",
            values[i],
            isCurrent: isCurrentDay,
          ),
        );
      }
    } else {
      List<double> values = List.filled(4, 0.0);
      final monthKey =
          "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}";

      if (_activeMetricIndex == 0) {
        final monthSessions = cleanSessionsByMonth[monthKey] ?? [];
        for (var s in monthSessions) {
          int day = s.startTime.day;
          int wIdx = day <= 7
              ? 0
              : day <= 14
              ? 1
              : day <= 21
              ? 2
              : 3;
          values[wIdx] += s.durationMinutes;
        }
      } else {
        final monthRecords = reelsFreeByMonth[monthKey] ?? [];
        for (var r in monthRecords) {
          int day = r.timestamp.day;
          int wIdx = day <= 7
              ? 0
              : day <= 14
              ? 1
              : day <= 21
              ? 2
              : 3;
          values[wIdx] += r.durationMinutes;
        }
      }

      int currentWeekIndex = now.day <= 7
          ? 0
          : now.day <= 14
          ? 1
          : now.day <= 21
          ? 2
          : 3;
      bool isCurrentMonth =
          targetDate.month == now.month && targetDate.year == now.year;

      data = [
        _ChartBarData(
          'W1\n1-7',
          values[0],
          isCurrent: isCurrentMonth && (currentWeekIndex == 0),
        ),
        _ChartBarData(
          'W2\n8-14',
          values[1],
          isCurrent: isCurrentMonth && (currentWeekIndex == 1),
        ),
        _ChartBarData(
          'W3\n15-21',
          values[2],
          isCurrent: isCurrentMonth && (currentWeekIndex == 2),
        ),
        _ChartBarData(
          'W4\n22+',
          values[3],
          isCurrent: isCurrentMonth && (currentWeekIndex == 3),
        ),
      ];
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final statsProvider = context.watch<StatsProvider>();

    final Map<String, List<FreedomSession>> cleanSessionsByDay = {};
    final Map<String, List<FreedomSession>> cleanSessionsByMonth = {};
    for (var s in statsProvider.sessions) {
      if (!s.usedParachute) {
        final dKey =
            "${s.startTime.year}-${s.startTime.month.toString().padLeft(2, '0')}-${s.startTime.day.toString().padLeft(2, '0')}";
        final mKey =
            "${s.startTime.year}-${s.startTime.month.toString().padLeft(2, '0')}";
        cleanSessionsByDay.putIfAbsent(dKey, () => []).add(s);
        cleanSessionsByMonth.putIfAbsent(mKey, () => []).add(s);
      }
    }

    final Map<String, List<ReelsFreeTimeRecord>> reelsFreeByDay = {};
    final Map<String, List<ReelsFreeTimeRecord>> reelsFreeByMonth = {};
    for (var r in statsProvider.reelsFreeRecords) {
      final dKey =
          "${r.timestamp.year}-${r.timestamp.month.toString().padLeft(2, '0')}-${r.timestamp.day.toString().padLeft(2, '0')}";
      final mKey =
          "${r.timestamp.year}-${r.timestamp.month.toString().padLeft(2, '0')}";
      reelsFreeByDay.putIfAbsent(dKey, () => []).add(r);
      reelsFreeByMonth.putIfAbsent(mKey, () => []).add(r);
    }

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
          _buildTrendsTab(
            cleanSessionsByDay,
            cleanSessionsByMonth,
            reelsFreeByDay,
            reelsFreeByMonth,
          ),
          _buildHistoryTab(statsProvider),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(StatsProvider stats) {
    final cleanSessions = stats.sessions.where((s) => !s.usedParachute);
    final totalCleanMinutes = cleanSessions.fold<int>(
      0,
      (sum, s) => sum + s.durationMinutes,
    );
    final totalHours = (totalCleanMinutes / 60).floor();
    final remainingMins = totalCleanMinutes % 60;

    final totalReelsFreeMins = stats.reelsFreeRecords.fold<int>(
      0,
      (sum, r) => sum + r.durationMinutes,
    );
    final reelsHours = (totalReelsFreeMins / 60).floor();
    final reelsMins = totalReelsFreeMins % 60;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        _SectionCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TOTAL TIME RECLAIMED (PHONE LOCK)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.textMuted,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$totalHours',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: AppConstants.primaryAccent,
                      height: 1,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4, left: 2, right: 6),
                    child: Text(
                      'h',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppConstants.primaryAccent,
                      ),
                    ),
                  ),
                  Text(
                    '$remainingMins',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: AppConstants.primaryAccent,
                      height: 1,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4, left: 2),
                    child: Text(
                      'm',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppConstants.primaryAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TOTAL REELS-FREE INSTAGRAM ATTENTION TIME',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.textMuted,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$reelsHours',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4, left: 2, right: 6),
                    child: Text(
                      'h',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                  ),
                  Text(
                    '$reelsMins',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4, left: 2),
                    child: Text(
                      'm',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              _IconBadge(
                icon: Icons.local_fire_department_rounded,
                color: AppConstants.primaryAccent,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_calculateStreak(stats.sessions)} days',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppConstants.textPrimary,
                        height: 1.0,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Current Streak (Full Focus)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendsTab(
    Map<String, List<FreedomSession>> cleanSessionsByDay,
    Map<String, List<FreedomSession>> cleanSessionsByMonth,
    Map<String, List<ReelsFreeTimeRecord>> reelsFreeByDay,
    Map<String, List<ReelsFreeTimeRecord>> reelsFreeByMonth,
  ) {
    final DateTime activeTargetDate = _getTargetDateForPage(_currentPageIndex);
    int activeSumMinutes = 0;

    if (_selectedFilterIndex == 0) {
      final dKey =
          "${activeTargetDate.year}-${activeTargetDate.month.toString().padLeft(2, '0')}-${activeTargetDate.day.toString().padLeft(2, '0')}";
      if (_activeMetricIndex == 0) {
        activeSumMinutes = (cleanSessionsByDay[dKey] ?? []).fold(
          0,
          (sum, s) => sum + s.durationMinutes,
        );
      } else {
        activeSumMinutes = (reelsFreeByDay[dKey] ?? []).fold(
          0,
          (sum, r) => sum + r.durationMinutes,
        );
      }
    } else if (_selectedFilterIndex == 1) {
      DateTime weekStart = activeTargetDate.subtract(
        Duration(days: activeTargetDate.weekday - 1),
      );
      for (int i = 0; i < 7; i++) {
        final d = weekStart.add(Duration(days: i));
        final dKey =
            "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
        activeSumMinutes += _activeMetricIndex == 0
            ? (cleanSessionsByDay[dKey] ?? []).fold(
                0,
                (sum, s) => sum + s.durationMinutes,
              )
            : (reelsFreeByDay[dKey] ?? []).fold(
                0,
                (sum, r) => sum + r.durationMinutes,
              );
      }
    } else {
      final mKey =
          "${activeTargetDate.year}-${activeTargetDate.month.toString().padLeft(2, '0')}";
      activeSumMinutes = _activeMetricIndex == 0
          ? (cleanSessionsByMonth[mKey] ?? []).fold(
              0,
              (sum, s) => sum + s.durationMinutes,
            )
          : (reelsFreeByMonth[mKey] ?? []).fold(
              0,
              (sum, r) => sum + r.durationMinutes,
            );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        // Filter Switcher Pills row
        _SectionCard(
          padding: const EdgeInsets.all(4),
          radius: 999,
          child: Row(
            children: [
              _buildFilterOption(0, 'Day'),
              _buildFilterOption(1, 'Week'),
              _buildFilterOption(2, 'Month'),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // NEW: Dual Analytics Source Metric Toggle Row Selection Panel
        Row(
          children: [
            _buildMetricToggleOption(0, "Focus Lock"),
            const SizedBox(width: 8),
            _buildMetricToggleOption(1, "Reels-Free Time"),
          ],
        ),
        const SizedBox(height: 16),

        SizedBox(
          height: 310,
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentPageIndex = index;
                _touchedBarIndex = null;
              });
            },
            itemBuilder: (context, index) {
              final int pageOffset = index - _virtualCenter;
              final DateTime targetDate = _getTargetDateForPage(index);
              final chartData = _getChartDataForPage(
                targetDate,
                cleanSessionsByDay,
                cleanSessionsByMonth,
                reelsFreeByDay,
                reelsFreeByMonth,
              );

              final maxMinutes = chartData.isEmpty
                  ? 0
                  : chartData
                        .map((d) => d.value)
                        .reduce((a, b) => a > b ? a : b);
              final chartMax = maxMinutes > 0 ? maxMinutes : 60.0;

              String headerTitle = "";
              if (_selectedFilterIndex == 0) {
                headerTitle = pageOffset == 0
                    ? "Today"
                    : pageOffset == -1
                    ? "Yesterday"
                    : DateFormat('MMM dd, yyyy').format(targetDate);
              } else if (_selectedFilterIndex == 1) {
                DateTime start = targetDate.subtract(
                  Duration(days: targetDate.weekday - 1),
                );
                DateTime end = start.add(const Duration(days: 6));
                headerTitle = pageOffset == 0
                    ? "This Week"
                    : pageOffset == -1
                    ? "Last Week"
                    : "${DateFormat('MMM dd').format(start)} - ${DateFormat('MMM dd').format(end)}";
              } else {
                headerTitle = pageOffset == 0
                    ? "This Month"
                    : pageOffset == -1
                    ? "Last Month"
                    : DateFormat('MMMM yyyy').format(targetDate);
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: _SectionCard(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  radius: 28,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.chevron_left_rounded,
                              color: AppConstants.textMuted,
                              size: 20,
                            ),
                            onPressed: () => _pageController.previousPage(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                            ),
                          ),
                          Text(
                            headerTitle,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppConstants.textPrimary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.chevron_right_rounded,
                              color: AppConstants.textMuted,
                              size: 20,
                            ),
                            onPressed: pageOffset == 0
                                ? null
                                : () => _pageController.nextPage(
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeInOut,
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text(
                          _touchedBarIndex != null
                              ? '${chartData[_touchedBarIndex!].value.toInt()} mins'
                              : '${chartData.map((e) => e.value).fold(0.0, (a, b) => a + b).toInt()} total mins',
                          style: TextStyle(
                            fontSize: 14,
                            color: _touchedBarIndex != null
                                ? AppConstants.primaryAccent
                                : AppConstants.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        height: 180,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(chartData.length, (barIndex) {
                            final dataPoint = chartData[barIndex];
                            final heightFactor = dataPoint.value / chartMax;
                            final isTouched = _touchedBarIndex == barIndex;
                            final isCurrent = dataPoint.isCurrent;

                            Color barColor = isTouched
                                ? AppConstants.primaryAccent
                                : isCurrent
                                ? AppConstants.primaryAccent.withOpacity(0.8)
                                : dataPoint.value > 0
                                ? (_activeMetricIndex == 0
                                      ? AppConstants.primaryAccent.withOpacity(
                                          0.3,
                                        )
                                      : Colors.white24)
                                : AppConstants.borderColor;

                            return _ChartBar(
                              label: dataPoint.label,
                              value: dataPoint.value.toInt(),
                              barColor: barColor,
                              labelColor: (isTouched || isCurrent)
                                  ? AppConstants.primaryAccent
                                  : AppConstants.textMuted,
                              isTouched: isTouched,
                              isCurrent: isCurrent,
                              width: chartData.length > 5 ? 28 : 42,
                              height: (heightFactor * 100).clamp(4.0, 100.0),
                              onPressStart: () {
                                HapticFeedback.selectionClick();
                                setState(() => _touchedBarIndex = barIndex);
                              },
                              onPressEnd: () =>
                                  setState(() => _touchedBarIndex = null),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _activeMetricIndex == 0
                    ? "RECLAIMED FOCUS TIME"
                    : "CLEAN ATTENTION TIME",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textMuted,
                ),
              ),
              Text(
                "${(activeSumMinutes / 60).floor()}h ${activeSumMinutes % 60}m",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppConstants.primaryAccent,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricToggleOption(int targetIndex, String title) {
    final isSelected = _activeMetricIndex == targetIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _activeMetricIndex = targetIndex;
          _touchedBarIndex = null;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppConstants.cardColor : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? AppConstants.primaryAccent.withOpacity(0.4)
                  : AppConstants.borderColor,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isSelected
                  ? AppConstants.primaryAccent
                  : AppConstants.textMuted,
            ),
          ),
        ),
      ),
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
            _currentPageIndex = _virtualCenter;
          });
          _pageController.jumpToPage(_virtualCenter);
          LocalStorageService.saveLastStatsFilter(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppConstants.primaryAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isSelected
                  ? AppConstants.textDark
                  : AppConstants.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab(StatsProvider statsProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 14),
          child: Text(
            'ALL FOCUS SESSIONS',
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

class _SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  const _SectionCard({
    required this.child,
    required this.padding,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: child,
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 32),
    );
  }
}

class _ChartBar extends StatelessWidget {
  final String label;
  final int value;
  final double width;
  final double height;
  final Color barColor;
  final Color labelColor;
  final bool isTouched;
  final bool isCurrent;
  final VoidCallback onPressStart;
  final VoidCallback onPressEnd;

  const _ChartBar({
    required this.label,
    required this.value,
    required this.width,
    required this.height,
    required this.barColor,
    required this.labelColor,
    required this.isTouched,
    required this.isCurrent,
    required this.onPressStart,
    required this.onPressEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTapDown: (_) => onPressStart(),
        onTapUp: (_) => onPressEnd(),
        onTapCancel: onPressEnd,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isTouched ? 1.0 : 0.0,
                child: Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppConstants.textPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                  color: labelColor,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
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
