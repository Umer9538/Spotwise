import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';
import '../core/constants/app_text_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToOnboarding();
  }

  Future<void> _navigateToOnboarding() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Icon
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: AppColors.backgroundWhite,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              // App Name
              Text(
                'SpotWise',
                style: AppTextStyles.h1.copyWith(
                  fontSize: 36,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                'Smart Parking Start Here',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
