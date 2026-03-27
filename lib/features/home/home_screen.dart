import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/session_provider.dart';
import '../../core/constants/app_constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedDuration = 30;

  @override
  Widget build(BuildContext context) {
    final sessionProvider = context.watch<SessionProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "blockit",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Icon(Icons.person, color: Colors.white70),
                  )
                ],
              ),

              const SizedBox(height: 24),

              /// TIMER CARD
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    /// TIME + LABEL
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatTime(_selectedDuration),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),

                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "Easy",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),

                    /// VERTICAL PROGRESS BAR
                    Container(
                      width: 36,
                      height: 130,
                      decoration: BoxDecoration(
                        color: const Color(0xFF222222),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.bottomCenter,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: (_selectedDuration / 180) * 130,
                        width: 6,
                        decoration: BoxDecoration(
                          color: AppConstants.primaryOrange,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// PRESET GRID
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.3,
                  children: [
                    _timeCard(15),
                    _timeCard(30),
                    _timeCard(60),
                    _timeCard(120),
                    _timeCard(180),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              /// START BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await sessionProvider.startSession(
                        _selectedDuration, context);
                  },
                  child: sessionProvider.isLocking
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("START"),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// FORMAT TIME → 00:30 / 01:00
  String _formatTime(int minutes) {
    final m = minutes % 60;
    final h = minutes ~/ 60;

    if (h == 0) {
      return "00:${m.toString().padLeft(2, '0')}";
    }
    return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}";
  }

  /// TIME PRESET CARD
  Widget _timeCard(int minutes) {
    final isSelected = _selectedDuration == minutes;

    return GestureDetector(
      onTap: () => setState(() => _selectedDuration = minutes),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.primaryOrange.withOpacity(0.15)
              : const Color(0xFF141414),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppConstants.primaryOrange
                : Colors.white10,
          ),
        ),
        child: Center(
          child: Text(
            minutes >= 60
                ? "${minutes ~/ 60} Hour${minutes >= 120 ? "s" : ""}"
                : "$minutes Minutes",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? AppConstants.primaryOrange
                  : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}