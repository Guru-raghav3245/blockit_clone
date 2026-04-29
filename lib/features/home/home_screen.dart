import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/session_provider.dart';
import '../../providers/stats_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../services/local_storage_service.dart';
import '../../services/auth_service.dart';
import '../settings/settings_screen.dart';
import '../stats/stats_screen.dart';
import '../../core/utils/platform_channel_helper.dart';
import '../active_session/active_session_screen.dart';
import '../../core/utils/app_routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ValueNotifier<int>? _duration;
  int _currentIndex = 0;
  int _statsTabIndex = 0;

  bool _isMainNavExpandedInStats = false;
  bool _isLoadingPrefs = true;

  FixedExtentScrollController? _wheelController;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    final savedDuration = await LocalStorageService.getLastSelectedDuration();
    if (mounted) {
      setState(() {
        _duration?.dispose();
        _duration = ValueNotifier(savedDuration);
        _wheelController = FixedExtentScrollController(
          initialItem: savedDuration - 1,
        );
        _isLoadingPrefs = false;
      });
    }
  }

  @override
  void dispose() {
    _wheelController?.dispose();
    _duration?.dispose();
    super.dispose();
  }

  // FORCE UNIFIED PEACH ACCENT
  Color get _accentColor => AppConstants.primaryAccent;

  String _difficultyLabelFor(int minutes) {
    if (minutes < 30) return "Easy";
    if (minutes < 60) return "Intermediate";
    if (minutes < 120) return "Hard";
    return "Extreme";
  }

  void _updateDuration(int newDuration) {
    final notifier = _duration;
    if (notifier == null) return;
    if (notifier.value == newDuration) return;
    notifier.value = newDuration;
    LocalStorageService.saveLastSelectedDuration(newDuration);

    if (_wheelController != null &&
        _wheelController!.hasClients &&
        _wheelController!.selectedItem != (newDuration - 1)) {
      _wheelController!.animateToItem(
        newDuration - 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  IconData get _activeStatsIcon {
    if (_statsTabIndex == 0) return Icons.grid_view_rounded;
    if (_statsTabIndex == 1) return Icons.insights_rounded;
    return Icons.history_rounded;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPrefs || _wheelController == null || _duration == null) {
      return const Scaffold(backgroundColor: AppConstants.backgroundColor);
    }

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                _buildHomeContent(context),
                RepaintBoundary(child: StatsScreen(currentTab: _statsTabIndex)),
                const RepaintBoundary(child: SettingsScreen()),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 10,
            child: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSize(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        child: _currentIndex == 1
                            ? Padding(
                                padding: const EdgeInsets.only(right: 12.0),
                                child: _buildStatsSubNavPill(),
                              )
                            : const SizedBox.shrink(),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        child: _buildFloatingNavPill(),
                      ),
                    ],
                  ),
                  if (_currentIndex == 0) _buildPlayButton(_duration!),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSubNavPill() {
    bool isExpanded = _currentIndex == 1 && !_isMainNavExpandedInStats;

    return GestureDetector(
      onTap: () {
        if (!isExpanded) setState(() => _isMainNavExpandedInStats = false);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: AppConstants.cardColor,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: AppConstants.borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: isExpanded
                ? [
                    _buildStatsTabItem(0, 'Overview'),
                    _buildStatsTabItem(1, 'Trends'),
                    _buildStatsTabItem(2, 'History'),
                  ]
                : [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _accentColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _activeStatsIcon,
                        color: AppConstants.textDark,
                        size: 26,
                      ),
                    ),
                  ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsTabItem(int index, String label) {
    final isSelected = _statsTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _statsTabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppConstants.textDark : AppConstants.textMuted,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingNavPill() {
    bool isExpanded = _currentIndex != 1 || _isMainNavExpandedInStats;

    return GestureDetector(
      onTap: () {
        if (!isExpanded) setState(() => _isMainNavExpandedInStats = true);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: AppConstants.cardColor,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: AppConstants.borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: isExpanded
                ? [
                    _buildNavItem(0, Icons.timer_rounded),
                    const SizedBox(width: 4),
                    _buildNavItem(1, Icons.show_chart_rounded),
                    const SizedBox(width: 4),
                    _buildNavItem(2, Icons.settings_rounded),
                  ]
                : [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _accentColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.show_chart_rounded,
                        color: AppConstants.textDark,
                        size: 26,
                      ),
                    ),
                  ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
          if (index == 1) _isMainNavExpandedInStats = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? _accentColor : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? AppConstants.textDark : AppConstants.textMuted,
          size: 26,
        ),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return SafeArea(
      bottom: false,
      child: ValueListenableBuilder<int>(
        valueListenable: _duration!,
        builder: (context, minutes, _) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: isLandscape
                ? _buildLandscapeLayout(minutes)
                : _buildPortraitLayout(minutes),
          );
        },
      ),
    );
  }

  Widget _buildPortraitLayout(int minutes) {
    return Column(
      children: [
        const SizedBox(height: 10),
        _buildTopBar(),
        const SizedBox(height: 16),
        Expanded(flex: 4, child: _buildBigDisplayCard(false, minutes)),
        const SizedBox(height: 12),
        Expanded(
          flex: 5,
          child: Row(
            children: [
              Expanded(flex: 13, child: _buildAsymmetricGrid(minutes)),
              const SizedBox(width: 12),
              Expanded(flex: 4, child: _buildThumbwheel()),
            ],
          ),
        ),
        const SizedBox(height: 90),
      ],
    );
  }

  Widget _buildLandscapeLayout(int minutes) {
    return Column(
      children: [
        const SizedBox(height: 4),
        _buildTopBar(),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 5, child: _buildBigDisplayCard(true, minutes)),
              const SizedBox(width: 12),
              Expanded(
                flex: 6,
                child: Row(
                  children: [
                    Expanded(flex: 13, child: _buildAsymmetricGrid(minutes)),
                    const SizedBox(width: 12),
                    Expanded(flex: 4, child: _buildThumbwheel()),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(width: 40),
        const Text(
          AppConstants.appName,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            color: AppConstants.textPrimary,
          ),
        ),
        StreamBuilder<User?>(
          stream: _authService.authStateChanges,
          builder: (context, snapshot) {
            final user = snapshot.data;
            final isLoggedIn = user != null;

            return GestureDetector(
              onTap: () async {
                if (isLoggedIn) {
                  _showLogoutDialog(user);
                } else {
                  final navigator = Navigator.of(context);
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const Center(
                      child: CircularProgressIndicator(
                        color: AppConstants.primaryAccent,
                      ),
                    ),
                  );
                  try {
                    final credential = await _authService.signInWithGoogle();
                    if (credential?.user != null && mounted) {
                      await context.read<StatsProvider>().loginAndSync(
                        credential!.user!.uid,
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Sync Error: $e')));
                    }
                  } finally {
                    if (navigator.canPop()) navigator.pop();
                  }
                }
              },
              child: isLoggedIn && user.photoURL != null
                  ? CircleAvatar(
                      radius: 18,
                      backgroundColor: AppConstants.borderColor,
                      backgroundImage: NetworkImage(user.photoURL!),
                    )
                  : Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppConstants.primaryAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: AppConstants.textDark,
                        size: 20,
                      ),
                    ),
            );
          },
        ),
      ],
    );
  }

  void _showLogoutDialog(User user) {
    showDialog(
      context: context,
      builder: (innerContext) => AlertDialog(
        backgroundColor: AppConstants.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          user.displayName ?? 'Account',
          style: const TextStyle(
            color: AppConstants.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Logged in as your email\n\nDo you want to log out? This will clear local data, but it is safely backed up in the cloud.',
          style: TextStyle(color: AppConstants.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(innerContext),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppConstants.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.borderColor,
              foregroundColor: AppConstants.textPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.pop(innerContext);
              final navigator = Navigator.of(context);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(
                  child: CircularProgressIndicator(
                    color: AppConstants.primaryAccent,
                  ),
                ),
              );
              try {
                await _authService.signOut();
                if (mounted) {
                  await context.read<StatsProvider>().clearLocalAndMemory();
                }
              } finally {
                if (navigator.canPop()) navigator.pop();
              }
            },
            child: const Text(
              'Log Out',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBigDisplayCard(bool isLandscape, int selectedMinutes) {
    final hours = (selectedMinutes ~/ 60).toString().padLeft(2, '0');
    final minutes = (selectedMinutes % 60).toString().padLeft(2, '0');
    double alignY =
        1.0 - ((selectedMinutes / 180).clamp(0.0, 1.0) * 2.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: EdgeInsets.all(isLandscape ? 16 : 24),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      fontSize: isLandscape ? 70 : 100,
                      fontWeight: FontWeight.w900,
                      color: _accentColor,
                      height: 0.85,
                      letterSpacing: -4,
                    ),
                    child: Text(hours),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      fontSize: isLandscape ? 70 : 100,
                      fontWeight: FontWeight.w900,
                      color: _accentColor,
                      height: 0.85,
                      letterSpacing: -4,
                    ),
                    child: Text(minutes),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: isLandscape ? 110 : 140,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(isLandscape ? 9 : 13, (index) {
                      int markerMinute =
                          (isLandscape ? 8 - index : 12 - index) * 15;
                      bool isLong = markerMinute % 60 == 0;
                      bool isActive = markerMinute <= selectedMinutes;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: isLong ? 12 : 6,
                        height: 2,
                        decoration: BoxDecoration(
                          color: isActive ? _accentColor : Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                ),
                AnimatedAlign(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  alignment: Alignment(1.0, alignY),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 18),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: EdgeInsets.symmetric(
                        horizontal: isLandscape ? 10 : 14,
                        vertical: isLandscape ? 8 : 10,
                      ),
                      decoration: BoxDecoration(
                        color: _accentColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                          topRight: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      child: Text(
                        _difficultyLabelFor(selectedMinutes),
                        style: TextStyle(
                          color: AppConstants.textDark,
                          fontWeight: FontWeight.w800,
                          fontSize: isLandscape ? 12 : 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAsymmetricGrid(int selectedMinutes) {
    return Column(
      children: [
        Expanded(
          flex: 1,
          child: Row(
            children: [
              Expanded(child: _presetCard(15, "15\nMinutes", selectedMinutes)),
              const SizedBox(width: 10),
              Expanded(child: _presetCard(30, "30\nMinutes", selectedMinutes)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Expanded(child: _presetCard(60, "1\nHour", selectedMinutes)),
                    const SizedBox(height: 10),
                    Expanded(
                      child: _presetCard(120, "2\nHours", selectedMinutes),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _presetCard(180, "3\nHours", selectedMinutes)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _presetCard(int minutes, String label, int selectedMinutes) {
    return GestureDetector(
      onTap: () {
        if (_currentIndex != 0) setState(() => _currentIndex = 0);
        _updateDuration(minutes);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selectedMinutes == minutes
              ? _accentColor
              : AppConstants.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: selectedMinutes == minutes
                    ? AppConstants.textDark
                    : AppConstants.textPrimary,
                height: 1.1,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbwheel() {
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: AppConstants.borderColor, width: 2),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ListWheelScrollView.useDelegate(
                  controller: _wheelController,
                  itemExtent: 14,
                  perspective: 0.005,
                  diameterRatio: 2.5,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (index) {
                    final newDuration = index + 1;
                    final notifier = _duration;
                    if (notifier == null) return;
                    if (notifier.value != newDuration) {
                      notifier.value = newDuration;
                      LocalStorageService.saveLastSelectedDuration(newDuration);
                    }
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    builder: (context, index) {
                      bool isAccentIndicator = (index + 1) % 15 == 0;
                      return Center(
                        child: Container(
                          width: isAccentIndicator ? 28 : 16,
                          height: 3,
                          decoration: BoxDecoration(
                            color: isAccentIndicator
                                ? AppConstants.primaryAccent
                                : Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    },
                    childCount: 180,
                  ),
                ),
                IgnorePointer(
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppConstants.backgroundColor,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 100),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                AppConstants.backgroundColor,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppConstants.borderColor, width: 2),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  if (_currentIndex != 0) setState(() => _currentIndex = 0);
                  final notifier = _duration;
                  if (notifier != null && notifier.value < 180) {
                    _updateDuration(notifier.value + 1);
                  }
                },
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
                child: const SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: AppConstants.textPrimary,
                    size: 28,
                  ),
                ),
              ),
              Container(height: 2, color: AppConstants.borderColor),
              InkWell(
                onTap: () {
                  if (_currentIndex != 0) setState(() => _currentIndex = 0);
                  final notifier = _duration;
                  if (notifier != null && notifier.value > 1) {
                    _updateDuration(notifier.value - 1);
                  }
                },
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(22),
                ),
                child: const SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppConstants.textPrimary,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayButton(ValueNotifier<int> duration) {
    return Selector<SessionProvider, bool>(
      selector: (context, provider) => provider.isLocking,
      builder: (context, isLocking, child) {
        return GestureDetector(
          onTap: () async {
            if (!isLocking) {
              HapticFeedback.lightImpact();
              final sessionProvider = context.read<SessionProvider>();
              final result = await sessionProvider.startSession(
                duration.value,
                context,
              );

              if (result == SessionStartResult.accessibilityDenied) {
                _showPermissionDialog();
                return;
              }

              if (result == SessionStartResult.alreadyActive) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('A session is already active.')),
                );
                Navigator.of(context).push(
                  AppRoutes.fadeSlide(const ActiveSessionScreen()),
                );
                return;
              }

              if (result == SessionStartResult.lockTaskFailed) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Could not start focus lock. Enable Device Admin in Settings and try again.',
                    ),
                  ),
                );
                return;
              }
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 76,
            height: 64,
            decoration: BoxDecoration(
              color: _accentColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _accentColor.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: isLocking
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: AppConstants.textDark,
                        strokeWidth: 3,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.play_arrow_rounded,
                    color: AppConstants.textDark,
                    size: 36,
                  ),
          ),
        );
      },
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Permission Required',
          style: TextStyle(
            color: AppConstants.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'To block distractions effectively, blockit needs Accessibility Service permission. Please enable "Blockit Accessibility" in the settings.',
          style: TextStyle(color: AppConstants.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppConstants.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryAccent,
              foregroundColor: AppConstants.textDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              PlatformChannelHelper.openAccessibilitySettings();
            },
            child: const Text(
              'Open Settings',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
