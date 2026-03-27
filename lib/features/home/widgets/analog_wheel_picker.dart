import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '/core/constants/app_constants.dart';

class AnalogWheelPicker extends StatefulWidget {
  final int selectedMinutes;
  final ValueChanged<int> onDurationChanged;

  const AnalogWheelPicker({
    super.key,
    required this.selectedMinutes,
    required this.onDurationChanged,
  });

  @override
  State<AnalogWheelPicker> createState() => _AnalogWheelPickerState();
}

class _AnalogWheelPickerState extends State<AnalogWheelPicker> {
  late FixedExtentScrollController _controller;
  final List<int> _allMinutes = List.generate(180, (index) => index + 1);
  bool _isBuilding = true;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(initialItem: widget.selectedMinutes - 1);
    WidgetsBinding.instance.addPostFrameCallback((_) => _isBuilding = false);
  }

  void _safeHaptic(int minutes) {
    if (_isBuilding) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (minutes % 5 == 0) {
        Vibration.vibrate(duration: 40, amplitude: 120);
      } else {
        Vibration.vibrate(duration: 15, amplitude: 50);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _isBuilding = true;

    final widgetToBuild = SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Center Selector Frame (Teenage Engineering Style)
          Container(
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              border: Border.symmetric(
                horizontal: BorderSide(color: AppConstants.primaryOrange.withOpacity(0.5), width: 2),
              ),
            ),
          ),

          ListWheelScrollView.useDelegate(
            controller: _controller,
            itemExtent: 65,
            perspective: 0.005,
            diameterRatio: 2.0,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (index) {
              final minutes = _allMinutes[index];
              widget.onDurationChanged(minutes);
              _safeHaptic(minutes);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                final minutes = _allMinutes[index];
                final bool isSelected = minutes == widget.selectedMinutes;

                return Center(
                  child: Text(
                    minutes.toString().padLeft(2, '0'),
                    style: TextStyle(
                      fontSize: isSelected ? 42 : 28,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      color: isSelected ? AppConstants.primaryOrange : const Color(0xFF444444),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                );
              },
              childCount: _allMinutes.length,
            ),
          ),

          // Aggressive OLED Fade Gradients
          Positioned(
            top: 0, left: 0, right: 0, height: 65,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Color(0xFF000000), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0, height: 65,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter, end: Alignment.topCenter,
                  colors: [Color(0xFF000000), Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _isBuilding = false);
    return widgetToBuild;
  }
}