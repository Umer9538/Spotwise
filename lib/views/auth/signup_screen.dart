import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedRole = 'Student';
  bool _agreeToTerms = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Back Button
              Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Account',
                          style: AppTextStyles.h1,
                        ),
                        const SizedBox(height: AppSizes.xl),
                        // Full Name
                        CustomTextField(
                          label: 'Full Name',
                          hint: 'Enter your full name',
                          controller: _nameController,
                          prefixIcon: Icons.person,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSizes.md),
                        // Email
                        CustomTextField(
                          label: 'University Email',
                          hint: 'student@psu.edu.sa',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email,
                          helperText: 'Enter your email address',
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
                        // Student/Staff ID
                        CustomTextField(
                          label: 'Student/Staff ID',
                          hint: 'Enter your ID',
                          controller: _studentIdController,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.badge,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your ID';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSizes.md),
                        // Password
                        CustomTextField(
                          label: 'Password',
                          hint: 'Create password',
                          controller: _passwordController,
                          isPassword: true,
                          prefixIcon: Icons.lock,
                          helperText: 'Min 8 characters',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (value.length < 8) {
                              return 'Password must be at least 8 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSizes.md),
                        // Confirm Password
                        CustomTextField(
                          label: 'Confirm Password',
                          hint: 'Re-enter password',
                          controller: _confirmPasswordController,
                          isPassword: true,
                          prefixIcon: Icons.lock_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSizes.md),
                        // Role Selection
                        Text(
                          'I am a:',
                          style: AppTextStyles.captionBold,
                        ),
                        const SizedBox(height: AppSizes.sm),
                        ..._buildRoleOptions(),
                        const SizedBox(height: AppSizes.md),
                        // Terms & Conditions
                        Row(
                          children: [
                            Checkbox(
                              value: _agreeToTerms,
                              onChanged: (value) {
                                setState(() {
                                  _agreeToTerms = value ?? false;
                                });
                              },
                              activeColor: AppColors.primaryBlue,
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _agreeToTerms = !_agreeToTerms;
                                  });
                                },
                                child: RichText(
                                  text: TextSpan(
                                    style: AppTextStyles.caption,
                                    children: [
                                      const TextSpan(text: 'I agree to '),
                                      TextSpan(
                                        text: 'Terms & Privacy Policy',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.primaryBlue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.xl),
                        // Create Account Button
                        CustomButton(
                          text: 'CREATE ACCOUNT',
                          onPressed: _handleSignUp,
                          isLoading: _isLoading,
                        ),
                        const SizedBox(height: AppSizes.lg),
                        // Sign In Link
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Already have account? ',
                                style: AppTextStyles.body,
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Text(
                                  'Sign In',
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
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRoleOptions() {
    final roles = ['Student', 'Faculty', 'Staff'];
    return roles.map((role) {
      return RadioListTile<String>(
        title: Text(role, style: AppTextStyles.body),
        value: role,
        groupValue: _selectedRole,
        onChanged: (value) {
          setState(() {
            _selectedRole = value!;
          });
        },
        activeColor: AppColors.primaryBlue,
        contentPadding: EdgeInsets.zero,
      );
    }).toList();
  }

  Future<void> _handleSignUp() async {
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to Terms & Privacy Policy'),
          backgroundColor: AppColors.occupiedRed,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Convert role string to UserRole enum
    UserRole role;
    switch (_selectedRole) {
      case 'Faculty':
        role = UserRole.faculty;
        break;
      case 'Staff':
        role = UserRole.staff;
        break;
      default:
        role = UserRole.student;
    }

    final success = await authProvider.signUpWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      studentId: _studentIdController.text.trim(),
      role: role,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      // Navigate to verification screen
      Navigator.pushReplacementNamed(context, '/verification');
    } else {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Sign up failed'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      authProvider.clearError();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _studentIdController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
