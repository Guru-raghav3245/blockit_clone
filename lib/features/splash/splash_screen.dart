import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/stats_provider.dart';
import '../home/home_screen.dart';
import '../../core/utils/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final double _loadingProgress = 0.0;
  final String _loadingStatus = "Initializing blockit...";

  @override
  void initState() {
    super.initState();
    
    // Set up subtle breathing animation for the logo icon
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Local stats only; the cloud merge runs in the background so a slow
      // network never holds up the splash.
      final stats = context.read<StatsProvider>();
      await stats.loadStats();
      final user = FirebaseAuth.instance.currentUser;
      // ponytail: a session finishing mid-sync could be overwritten by the
      // merge; serialize via a queue in StatsProvider if that ever shows up.
      if (user != null) unawaited(stats.loginAndSync(user.uid));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          AppRoutes.fadeSlide(const HomeScreen()),
        );
      }
    } catch (e) {
      // Fallback route transition if initialization errors out
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor, // Replicates warm charcoal theme
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 3),

              // Dynamic animated app logo segment
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _fadeAnimation,
                  // Rounded clip: logo.png has opaque corners outside the tile
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset(
                      'assets/logo.png',
                      width: 96,
                      height: 96,
                      cacheWidth: 192,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Application Title branding
              const Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4.0,
                  color: AppConstants.textPrimary,
                ),
              ),
              const SizedBox(height: 6),

              // Application Subtitle/Tagline
              const Text(
                AppConstants.appTagline,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.5,
                  color: AppConstants.textMuted,
                ),
              ),

              const Spacer(flex: 2),

              // Customized progress tracker element
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48.0),
                child: Column(
                  children: [
                    // Sleek horizontal progress line
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        height: 4,
                        width: 160,
                        child: LinearProgressIndicator(
                          value: _loadingProgress,
                          backgroundColor: AppConstants.borderColor,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppConstants.primaryAccent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Active initialization descriptive state labels
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _loadingStatus,
                        key: ValueKey<String>(_loadingStatus),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}