import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../providers/auth_provider.dart';
import '../../services/fcm_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;

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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSizes.xl),
                  // Logo
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundWhite,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.sm),
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  Center(
                    child: Text(
                      'SpotWise',
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.xxl),
                  // Welcome Text
                  Text(
                    'Welcome Back!',
                    style: AppTextStyles.h1,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    'Sign in to continue',
                    style: AppTextStyles.bodyLight,
                  ),
                  const SizedBox(height: AppSizes.xl),
                  // Email Field
                  CustomTextField(
                    label: 'Email',
                    hint: 'Enter your email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.md),
                  // Password Field
                  CustomTextField(
                    label: 'Password',
                    hint: 'Enter your password',
                    controller: _passwordController,
                    isPassword: true,
                    prefixIcon: Icons.lock,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.md),
                  // Remember Me & Forgot Password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                            activeColor: AppColors.primaryBlue,
                          ),
                          const Text('Remember me', style: AppTextStyles.caption),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          // Navigate to forgot password
                        },
                        child: const Text(
                          'Forgot password?',
                          style: AppTextStyles.caption,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.xl),
                  // Sign In Button
                  CustomButton(
                    text: 'SIGN IN',
                    onPressed: _handleSignIn,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: AppSizes.lg),
                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: AppColors.disabledGray,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                        child: Text(
                          'OR',
                          style: AppTextStyles.caption,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: AppColors.disabledGray,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.lg),
                  // Google Sign In
                  CustomButton(
                    text: 'Continue with Google',
                    onPressed: _handleGoogleSignIn,
                    isOutlined: true,
                    icon: Icons.login,
                  ),
                  const SizedBox(height: AppSizes.xl),
                  // Sign Up Link
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: AppTextStyles.body,
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/signup');
                          },
                          child: Text(
                            'Sign Up',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final fcmService = Provider.of<FCMService>(context, listen: false);

    final success = await authProvider.signInWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      // TODO: Re-enable email verification for production
      // if (!authProvider.isEmailVerified) {
      //   Navigator.pushReplacementNamed(context, '/verification');
      //   return;
      // }

      // Save FCM token
      final user = authProvider.user;
      if (user != null) {
        await fcmService.saveTokenToDatabase(user.uid);
      }

      // Navigate to home
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Login failed'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      authProvider.clearError();
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final fcmService = Provider.of<FCMService>(context, listen: false);

    final success = await authProvider.signInWithGoogle();

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      // Save FCM token
      final user = authProvider.user;
      if (user != null) {
        await fcmService.saveTokenToDatabase(user.uid);
      }

      // Navigate to home
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Google sign-in failed'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      authProvider.clearError();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
