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
  late FixedExtentScrollController _wheelController;

  // Exact Background Colors from the screenshot
  final Color bgColor = const Color(0xFF151211);
  final Color cardColor = const Color(0xFF1E1B1A);
  final Color borderColor = const Color(0xFF332D2D);

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

  // ─── DYNAMIC COLOR & LABEL SYSTEM ───────────────────────────────────────────
  Color get _accentColor {
    if (_selectedDuration < 30)
      return const Color(0xFFDCD0C7); // Easy: Grey/White
    if (_selectedDuration < 60)
      return const Color(0xFFEED2C2); // Intermed: Beige
    return const Color(0xFFE49F80); // Advanced: Orange/Peach
  }

  String get _difficultyLabel {
    if (_selectedDuration < 30) return "Easy";
    if (_selectedDuration < 60) return "Intermed...";
    return "Advanced";
  }

  void _updateDuration(int newDuration) {
    setState(() => _selectedDuration = newDuration);
    // Animate wheel to match grid taps
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
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              _buildTopBar(),
              const SizedBox(height: 16),

              // TOP HALF: The Absolute Display
              Expanded(flex: 4, child: _buildBigDisplayCard()),

              const SizedBox(height: 12),

              // BOTTOM HALF: Asymmetric Grid + Thumbwheel
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

              // BOTTOM NAVIGATION
              _buildBottomNav(sessionProvider),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  // ─── UI COMPONENTS ────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(width: 40),
        const Text(
          "blockit",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            color: Colors.white,
          ),
        ),
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Colors.white,
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

    // Calculate how high the pointer should be (0.0 = bottom, 1.0 = top)
    // We invert it because Alignment(0, 1) is bottom and Alignment(0, -1) is top.
    double alignY = 1.0 - ((_selectedDuration / 180).clamp(0.0, 1.0) * 2.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: Giant Block Numbers
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

          // Right: The Absolute Scale & Pointer
          SizedBox(
            width: 110,
            child: Stack(
              children: [
                // The Dotted Line Scale
                Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(
                      15,
                      (index) => Container(
                        width: 6,
                        height: 2,
                        decoration: BoxDecoration(
                          color: index > 10 ? Colors.white54 : Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
                // The Dynamic Pointer Pill
                AnimatedAlign(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  alignment: Alignment(1.0, alignY),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 14),
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
                          fontSize: 15,
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
        // Top Row: 15 & 30
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
        // Bottom Section: Stacked (1h, 2h) next to Tall (3h)
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
      onTap: () => _updateDuration(minutes),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? _accentColor : cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.black : Colors.white,
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
        // The Scrolling Wheel
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: borderColor, width: 2),
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
                    childCount: 180, // 3 hours max
                  ),
                ),

                // Overlay Fades
                IgnorePointer(
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [bgColor, Colors.transparent],
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
                              colors: [bgColor, Colors.transparent],
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

        // Functional Arrows Container
        Container(
          width:
              double.infinity, // Matches the width of the scroll wheel above it
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Column(
            children: [
              // UP BUTTON (Increases time)
              InkWell(
                onTap: () {
                  if (_selectedDuration < 180) {
                    _updateDuration(_selectedDuration + 1);
                  }
                },
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
                child: const SizedBox(
                  width: double.infinity,
                  height: 44, // Generous tap target
                  child: Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),

              // Divider Line (matches the screenshot)
              Container(height: 2, color: borderColor),

              // DOWN BUTTON (Decreases time)
              InkWell(
                onTap: () {
                  if (_selectedDuration > 1) {
                    _updateDuration(_selectedDuration - 1);
                  }
                },
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(22),
                ),
                child: const SizedBox(
                  width: double.infinity,
                  height: 44, // Generous tap target
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.white,
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

  Widget _buildBottomNav(SessionProvider sessionProvider) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Icon Group
          Row(
            children: [
              // Active Timer Icon
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _accentColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.timer_rounded,
                  color: Colors.black,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Chart Icon
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StatsScreen()),
                ),
                child: AnimatedIcon(
                  icon: Icons.show_chart_rounded,
                  color: _accentColor,
                ),
              ),
              const SizedBox(width: 24),
              // Settings Icon
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
                child: AnimatedIcon(
                  icon: Icons.settings_rounded,
                  color: _accentColor,
                ),
              ),
            ],
          ),

          // Right Play Button
          GestureDetector(
            onTap: () async {
              if (!sessionProvider.isLocking) {
                await sessionProvider.startSession(_selectedDuration, context);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 80,
              height: 56,
              decoration: BoxDecoration(
                color: _accentColor,
                borderRadius: BorderRadius.circular(20),
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
          ),
        ],
      ),
    );
  }
}

// Simple helper to animate the color of the inactive icons
class AnimatedIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const AnimatedIcon({super.key, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedTheme(
      data: Theme.of(context).copyWith(iconTheme: IconThemeData(color: color)),
      child: Icon(icon, size: 28),
    );
  }
}
