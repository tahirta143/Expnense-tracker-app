import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../themes/app_theme.dart';
import 'onboarding_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _animationController.forward();
    _checkNavigation();
  }

  void _checkNavigation() async {
    final prefs = await SharedPreferences.getInstance();
    final showOnboarding = prefs.getBool('showOnboarding') ?? true;

    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      if (showOnboarding) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
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
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _opacityAnimation,
                child: Image.asset(
                  'assets/images/logo.png',
                  width: sw * 0.35,
                  height: sw * 0.35,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SizedBox(height: sh * 0.04),
            FadeTransition(
              opacity: _opacityAnimation,
              child: Text(
                'Expense Tracker',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: sw * 0.075,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            SizedBox(height: sh * 0.08),
            FadeTransition(
              opacity: _opacityAnimation,
              child: SizedBox(
                width: sw * 0.12,
                height: sw * 0.12,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryColor.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                    RotationTransition(
                      turns: _animationController,
                      child: SizedBox.expand(
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
