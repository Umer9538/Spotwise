import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_button.dart';
import '../../providers/auth_provider.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({Key? key}) : super(key: key);

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  Timer? _timer;
  bool _isLoading = false;
  bool _canResend = false;
  int _resendCountdown = 60;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _resendCountdown = 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              children: [
                const SizedBox(height: AppSizes.xxl),
                // Email Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.email,
                    size: 50,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: AppSizes.xl),
                // Title
                Text(
                  'Verify Your Email',
                  style: AppTextStyles.h1,
                ),
                const SizedBox(height: AppSizes.md),
                // Description
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    final email = authProvider.user?.email ?? 'your email';
                    return Column(
                      children: [
                        Text(
                          'We sent a verification link to:',
                          style: AppTextStyles.bodyLight,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSizes.sm),
                        Text(
                          email,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSizes.xl),
                // Instructions
                Text(
                  'Please check your email and click the verification link to continue.',
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.xxl),
                // Check Verification Button
                CustomButton(
                  text: 'I HAVE VERIFIED',
                  onPressed: _handleCheckVerification,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: AppSizes.lg),
                // Resend Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive the email? ",
                      style: AppTextStyles.body,
                    ),
                    GestureDetector(
                      onTap: _canResend ? _resendVerificationEmail : null,
                      child: Text(
                        _canResend
                            ? 'Resend Link'
                            : 'Resend in ${_resendCountdown}s',
                        style: AppTextStyles.body.copyWith(
                          color: _canResend
                              ? AppColors.primaryBlue
                              : AppColors.disabledGray,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.md),
                // Back to Login
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: Text(
                    'Back to Login',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleCheckVerification() async {
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Reload user to get latest email verification status
    await authProvider.reloadUser();

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (authProvider.isEmailVerified) {
      // Email verified, navigate to home
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // Not verified yet
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email not verified yet. Please check your email and click the verification link.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _resendVerificationEmail() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.sendEmailVerification();

    if (!mounted) return;

    if (success) {
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent! Please check your inbox.'),
          backgroundColor: AppColors.availableGreen,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Failed to send verification email'),
          backgroundColor: Colors.red,
        ),
      );
      authProvider.clearError();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
