import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _studentIdController = TextEditingController();
  bool _isLoading = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.currentUser;
    if (user != null) {
      _nameController.text = user.name;
      _studentIdController.text = user.studentId;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid;

      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Upload image if selected
      if (_selectedImage != null) {
        await userProvider.uploadProfilePicture(
          userId: userId,
          imageFile: _selectedImage!,
        );
      }

      // Update profile data
      await userProvider.updateProfile(
        userId: userId,
        name: _nameController.text.trim(),
        studentId: _studentIdController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.availableGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          final user = userProvider.currentUser;

          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Profile Picture
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppColors.primaryBlue.withOpacity(0.2),
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!)
                            : (user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                                ? NetworkImage(user.avatarUrl!)
                                : null) as ImageProvider?,
                        child: (_selectedImage == null &&
                                (user.avatarUrl == null || user.avatarUrl!.isEmpty))
                            ? const Icon(
                                Icons.person,
                                size: 60,
                                color: AppColors.primaryBlue,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primaryBlue,
                          child: IconButton(
                            icon: const Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: AppColors.backgroundWhite,
                            ),
                            onPressed: _pickImage,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.xl),

                  // Name Field
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

                  // Student ID Field
                  CustomTextField(
                    label: 'Student/Staff ID',
                    hint: 'Enter your ID',
                    controller: _studentIdController,
                    prefixIcon: Icons.badge,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your ID';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.md),

                  // Email (read-only)
                  Container(
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundGray,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.email, color: AppColors.textLight),
                        const SizedBox(width: AppSizes.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Email',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textLight,
                                ),
                              ),
                              Text(
                                user.email,
                                style: AppTextStyles.body,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.lock, size: 16, color: AppColors.textLight),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),

                  // Role (read-only)
                  Container(
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundGray,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.work, color: AppColors.textLight),
                        const SizedBox(width: AppSizes.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Role',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textLight,
                                ),
                              ),
                              Text(
                                user.role.name.toUpperCase(),
                                style: AppTextStyles.body,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.lock, size: 16, color: AppColors.textLight),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.xl),

                  // Save Button
                  CustomButton(
                    text: 'Save Changes',
                    onPressed: _saveProfile,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: AppSizes.md),

                  // Cancel Button
                  CustomButton(
                    text: 'Cancel',
                    onPressed: () => Navigator.pop(context),
                    isOutlined: true,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
