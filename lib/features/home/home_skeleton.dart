import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// Placeholder mirroring the home layout; shown until the route transition
/// ends and the real content is built.
class HomeSkeleton extends StatefulWidget {
  const HomeSkeleton({super.key});

  @override
  State<HomeSkeleton> createState() => _HomeSkeletonState();
}

class _HomeSkeletonState extends State<HomeSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Widget _block(double radius, {double? width, double? height}) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppConstants.cardColor,
          borderRadius: BorderRadius.circular(radius),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final landscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final grid = Row(
      children: [
        Expanded(
          flex: 13,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: _block(24)),
                    const SizedBox(width: 12),
                    Expanded(child: _block(24)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(child: _block(24, width: double.infinity)),
                          const SizedBox(height: 12),
                          Expanded(child: _block(24, width: double.infinity)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _block(24, height: double.infinity)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(flex: 4, child: _block(32, height: double.infinity)),
      ],
    );

    final body = landscape
        ? Row(
            children: [
              Expanded(flex: 5, child: _block(28, height: double.infinity)),
              const SizedBox(width: 12),
              Expanded(flex: 6, child: grid),
            ],
          )
        : Column(
            children: [
              Expanded(flex: 4, child: _block(28, width: double.infinity)),
              const SizedBox(height: 12),
              Expanded(flex: 5, child: grid),
            ],
          );

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: FadeTransition(
        opacity: Tween(begin: 0.45, end: 1.0).animate(
          CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
        ),
        child: SafeArea(
          child: landscape
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 16, 12),
                  child: Row(
                    children: [
                      _block(40, width: 64),
                      const SizedBox(width: 12),
                      Expanded(child: body),
                    ],
                  ),
                )
              : Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 40),
                    _block(8, width: 110, height: 24),
                    _block(18, width: 36, height: 36),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(child: body),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _block(32, width: 150, height: 64),
                    if (!landscape) _block(28, width: 96, height: 72),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
