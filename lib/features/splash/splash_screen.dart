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
  double _loadingProgress = 0.0;
  String _loadingStatus = "Initializing blockit...";

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
      // Step 1: Simulate engine warm up
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() {
        _loadingProgress = 0.3;
        _loadingStatus = "Loading secure configurations...";
      });

      // Step 2: Initialize stats, syncing from the cloud if already signed in
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await context.read<StatsProvider>().loginAndSync(user.uid);
      } else {
        await context.read<StatsProvider>().loadStats();
      }
      
      if (!mounted) return;
      setState(() {
        _loadingProgress = 0.7;
        _loadingStatus = "Synchronizing cloud data...";
      });

      // Step 3: Brief hold to prevent layout flash on ultra-fast devices
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      setState(() {
        _loadingProgress = 1.0;
        _loadingStatus = "Ready";
      });

      await Future.delayed(const Duration(milliseconds: 200));

      // Route smoothly into the home screen workspace
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
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppConstants.cardColor,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppConstants.borderColor, width: 1.5),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.phonelink_lock_rounded, // High-fidelity contextual shield icon
                        size: 44,
                        color: AppConstants.primaryAccent, // Peach color token
                      ),
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