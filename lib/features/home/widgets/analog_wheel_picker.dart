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
  final List<int> _allMinutes = List.generate(120, (index) => index + 1);

  // Use a flag to prevent setState during build
  bool _isBuilding = true;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(
      initialItem: widget.selectedMinutes - 1,
    );
    // Mark build as finished after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isBuilding = false;
    });
  }

  @override
  void didUpdateWidget(covariant AnalogWheelPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedMinutes != oldWidget.selectedMinutes) {
      _controller.jumpToItem(widget.selectedMinutes - 1);
    }
  }

  bool _isHighlightMinute(int minutes) {
    return minutes % 15 == 0 && minutes >= 15;
  }

  void _safeHaptic(int minutes) {
    if (_isBuilding) return; // Skip during build

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isHighlightMinute(minutes)) {
        Vibration.vibrate(duration: 45, amplitude: 110);
      } else {
        Vibration.vibrate(duration: 20);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _isBuilding = true; // Set flag at start of build

    final widgetToBuild = SizedBox(
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Center highlight
          Container(
            height: 62,
            decoration: BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(
                  color: AppConstants.primaryOrange.withOpacity(0.3),
                  width: 2,
                ),
              ),
            ),
          ),

          ListWheelScrollView.useDelegate(
            controller: _controller,
            itemExtent: 58,
            perspective: 0.006,
            diameterRatio: 1.8,
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
                final bool isHighlight = _isHighlightMinute(minutes);

                return Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    style: TextStyle(
                      fontSize: isSelected ? 48 : (isHighlight ? 34 : 26),
                      fontWeight: isSelected 
                          ? FontWeight.bold 
                          : (isHighlight ? FontWeight.w600 : FontWeight.w400),
                      color: isSelected 
                          ? AppConstants.primaryOrange 
                          : (isHighlight 
                              ? AppConstants.primaryOrange.withOpacity(0.85) 
                              : AppConstants.textSecondary),
                    ),
                    child: Text('$minutes'),
                  ),
                );
              },
              childCount: _allMinutes.length,
            ),
          ),

          // Fade gradients
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 50,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppConstants.backgroundColor, Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 50,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [AppConstants.backgroundColor, Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // Reset flag after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isBuilding = false;
    });

    return widgetToBuild;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}