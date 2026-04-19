import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({Key? key}) : super(key: key);

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedCategory = 'General';
  bool _isSubmitting = false;

  final List<String> _categories = [
    'General',
    'Reservation Issue',
    'Account Problem',
    'Payment',
    'Bug Report',
    'Feature Request',
    'Other',
  ];

  Future<void> _sendEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@spotwise.psu.edu.sa',
      queryParameters: {
        'subject': '[$_selectedCategory] ${_subjectController.text}',
        'body': _messageController.text,
      },
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open email app'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    // Simulate sending
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() => _isSubmitting = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Support request submitted successfully!'),
          backgroundColor: AppColors.availableGreen,
        ),
      );

      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Support'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact methods
            Text('Get in Touch', style: AppTextStyles.h3),
            const SizedBox(height: AppSizes.md),
            
            Row(
              children: [
                Expanded(
                  child: _ContactCard(
                    icon: Icons.email,
                    title: 'Email',
                    subtitle: 'support@spotwise.psu.edu.sa',
                    onTap: _sendEmail,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: _ContactCard(
                    icon: Icons.phone,
                    title: 'Phone',
                    subtitle: '+966 11 123 4567',
                    onTap: () async {
                      final Uri phoneUri = Uri(scheme: 'tel', path: '+966111234567');
                      if (await canLaunchUrl(phoneUri)) {
                        await launchUrl(phoneUri);
                      }
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSizes.xl),
            
            // Support form
            Text('Send us a Message', style: AppTextStyles.h3),
            const SizedBox(height: AppSizes.md),
            
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category dropdown
                  Text('Category', style: AppTextStyles.captionBold),
                  const SizedBox(height: AppSizes.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundGray,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  
                  // Subject
                  CustomTextField(
                    label: 'Subject',
                    hint: 'Brief description of your issue',
                    controller: _subjectController,
                    prefixIcon: Icons.subject,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a subject';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.md),
                  
                  // Message
                  Text('Message', style: AppTextStyles.captionBold),
                  const SizedBox(height: AppSizes.sm),
                  TextFormField(
                    controller: _messageController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Describe your issue in detail...',
                      filled: true,
                      fillColor: AppColors.backgroundGray,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your message';
                      }
                      if (value.length < 10) {
                        return 'Message must be at least 10 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.xl),
                  
                  // Submit button
                  CustomButton(
                    text: 'Submit',
                    onPressed: _submitForm,
                    isLoading: _isSubmitting,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSizes.xl),
            
            // Office hours
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.backgroundGray,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: AppColors.primaryBlue),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Support Hours', style: AppTextStyles.captionBold),
                        Text(
                          'Sunday - Thursday: 8:00 AM - 4:00 PM',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryBlue, size: 32),
            const SizedBox(height: AppSizes.sm),
            Text(title, style: AppTextStyles.captionBold),
            const SizedBox(height: AppSizes.xs),
            Text(
              subtitle,
              style: AppTextStyles.small.copyWith(color: AppColors.textLight),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
