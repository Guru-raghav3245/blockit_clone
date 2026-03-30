import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/session_provider.dart';
import '../../core/constants/app_constants.dart';
import '../settings/settings_screen.dart';
import '../stats/stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedDuration = 15;
  int _currentIndex = 0;
  late FixedExtentScrollController _wheelController;

  @override
  void initState() {
    super.initState();
    _wheelController = FixedExtentScrollController(
      initialItem: _selectedDuration - 1,
    );
  }

  @override
  void dispose() {
    _wheelController.dispose();
    super.dispose();
  }

  Color get _accentColor {
    if (_selectedDuration < 30) return const Color(0xFFDCD0C7);
    if (_selectedDuration < 60) return const Color(0xFFEED2C2);
    if (_selectedDuration < 120) return const Color(0xFFE49F80);
    return const Color(0xFFD85C3A);
  }

  String get _difficultyLabel {
    if (_selectedDuration < 30) return "Easy";
    if (_selectedDuration < 60) return "Intermediate";
    if (_selectedDuration < 120) return "Hard";
    return "Extreme";
  }

  void _updateDuration(int newDuration) {
    setState(() => _selectedDuration = newDuration);
    if (_wheelController.hasClients &&
        _wheelController.selectedItem != (newDuration - 1)) {
      _wheelController.animateToItem(
        newDuration - 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionProvider = context.watch<SessionProvider>();

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                _buildHomeContent(sessionProvider),
                const StatsScreen(),
                const SettingsScreen(),
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
                  _buildFloatingNavPill(),
                  if (_currentIndex == 0) _buildPlayButton(sessionProvider),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent(SessionProvider sessionProvider) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildTopBar(),
            const SizedBox(height: 16),
            Expanded(flex: 4, child: _buildBigDisplayCard()),
            const SizedBox(height: 12),
            Expanded(
              flex: 5,
              child: Row(
                children: [
                  Expanded(flex: 13, child: _buildAsymmetricGrid()),
                  const SizedBox(width: 12),
                  Expanded(flex: 4, child: _buildThumbwheel()),
                ],
              ),
            ),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingNavPill() {
    return Container(
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildNavItem(0, Icons.timer_rounded),
          const SizedBox(width: 4),
          _buildNavItem(1, Icons.show_chart_rounded),
          const SizedBox(width: 4),
          _buildNavItem(2, Icons.settings_rounded),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? _accentColor : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.black : AppConstants.textMuted,
          size: 26,
        ),
      ),
    );
  }

  Widget _buildPlayButton(SessionProvider sessionProvider) {
    return GestureDetector(
      onTap: () async {
        if (!sessionProvider.isLocking) {
          await sessionProvider.startSession(_selectedDuration, context);
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
        child: sessionProvider.isLocking
            ? const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.black,
                    strokeWidth: 3,
                  ),
                ),
              )
            : const Icon(
                Icons.play_arrow_rounded,
                color: Colors.black,
                size: 36,
              ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(width: 40),
        Text(
          AppConstants.appName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            color: AppConstants.textPrimary,
          ),
        ),
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: AppConstants.textPrimary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person, color: Colors.black, size: 20),
        ),
      ],
    );
  }

  Widget _buildBigDisplayCard() {
    final hours = (_selectedDuration ~/ 60).toString().padLeft(2, '0');
    final minutes = (_selectedDuration % 60).toString().padLeft(2, '0');
    double alignY = 1.0 - ((_selectedDuration / 180).clamp(0.0, 1.0) * 2.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    fontSize: 100,
                    fontWeight: FontWeight.w900,
                    color: _accentColor,
                    height: 0.85,
                    letterSpacing: -4,
                  ),
                  child: Text(hours),
                ),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    fontSize: 100,
                    fontWeight: FontWeight.w900,
                    color: _accentColor,
                    height: 0.85,
                    letterSpacing: -4,
                  ),
                  child: Text(minutes),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 140,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(13, (index) {
                      int markerMinute = (12 - index) * 15;
                      bool isLong = markerMinute % 60 == 0;
                      bool isActive = markerMinute <= _selectedDuration;
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
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
                        _difficultyLabel,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
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

  Widget _buildAsymmetricGrid() {
    return Column(
      children: [
        Expanded(
          flex: 1,
          child: Row(
            children: [
              Expanded(child: _presetCard(15, "15\nMinutes")),
              const SizedBox(width: 10),
              Expanded(child: _presetCard(30, "30\nMinutes")),
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
                    Expanded(child: _presetCard(60, "1\nHour")),
                    const SizedBox(height: 10),
                    Expanded(child: _presetCard(120, "2\nHours")),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _presetCard(180, "3\nHours")),
            ],
          ),
        ),
      ],
    );
  }

  Widget _presetCard(int minutes, String label) {
    final isSelected = _selectedDuration == minutes;
    return GestureDetector(
      onTap: () {
        if (_currentIndex != 0) setState(() => _currentIndex = 0);
        _updateDuration(minutes);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? _accentColor : AppConstants.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.black : AppConstants.textPrimary,
              height: 1.1,
              letterSpacing: -0.5,
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
                    setState(() => _selectedDuration = index + 1);
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    builder: (context, index) {
                      bool isOrangeIndicator = (index + 1) % 15 == 0;
                      return Center(
                        child: Container(
                          width: isOrangeIndicator ? 28 : 16,
                          height: 3,
                          decoration: BoxDecoration(
                            color: isOrangeIndicator
                                ? AppConstants.primaryOrange
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
                  if (_selectedDuration < 180)
                    _updateDuration(_selectedDuration + 1);
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
                  if (_selectedDuration > 1)
                    _updateDuration(_selectedDuration - 1);
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
}
