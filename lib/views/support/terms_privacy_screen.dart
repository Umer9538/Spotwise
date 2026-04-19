import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';

class TermsPrivacyScreen extends StatelessWidget {
  const TermsPrivacyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Terms & Privacy'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Terms of Service'),
              Tab(text: 'Privacy Policy'),
            ],
            labelColor: AppColors.primaryBlue,
            unselectedLabelColor: AppColors.textLight,
            indicatorColor: AppColors.primaryBlue,
          ),
        ),
        body: const TabBarView(
          children: [
            _TermsOfServiceTab(),
            _PrivacyPolicyTab(),
          ],
        ),
      ),
    );
  }
}

class _TermsOfServiceTab extends StatelessWidget {
  const _TermsOfServiceTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSizes.lg),
      children: [
        Text('Terms of Service', style: AppTextStyles.h2),
        const SizedBox(height: AppSizes.sm),
        Text(
          'Last updated: January 2025',
          style: AppTextStyles.caption.copyWith(color: AppColors.textLight),
        ),
        const SizedBox(height: AppSizes.lg),
        
        _Section(
          title: '1. Acceptance of Terms',
          content: 'By accessing and using the SpotWise parking application, you accept '
              'and agree to be bound by the terms and provision of this agreement. '
              'If you do not agree to abide by these terms, please do not use this service.',
        ),
        
        _Section(
          title: '2. Use of Service',
          content: 'SpotWise provides a parking reservation system for Prince Sultan University. '
              'You agree to use this service only for lawful purposes and in accordance with '
              'university parking regulations.\n\n'
              '• You must be a registered PSU student, faculty, or staff member\n'
              '• You must provide accurate registration information\n'
              '• You are responsible for maintaining the confidentiality of your account',
        ),
        
        _Section(
          title: '3. Reservations',
          content: '• Reservations are subject to availability\n'
              '• You must arrive within the reservation time window\n'
              '• Unused reservations will expire automatically\n'
              '• Repeated no-shows may result in account restrictions\n'
              '• You may cancel reservations at any time before arrival',
        ),
        
        _Section(
          title: '4. User Conduct',
          content: 'You agree not to:\n\n'
              '• Share your account credentials with others\n'
              '• Make reservations you do not intend to use\n'
              '• Attempt to manipulate or abuse the system\n'
              '• Violate any university parking policies\n'
              '• Use the service for any illegal purposes',
        ),
        
        _Section(
          title: '5. Limitation of Liability',
          content: 'SpotWise and Prince Sultan University shall not be liable for:\n\n'
              '• Unavailability of parking spots\n'
              '• Damages to vehicles in parking areas\n'
              '• Service interruptions or technical issues\n'
              '• Any indirect or consequential damages',
        ),
        
        _Section(
          title: '6. Modifications',
          content: 'We reserve the right to modify these terms at any time. '
              'Continued use of the service after changes constitutes acceptance '
              'of the modified terms.',
        ),
        
        _Section(
          title: '7. Contact',
          content: 'For questions about these terms, please contact:\n'
              'support@spotwise.psu.edu.sa',
        ),
        
        const SizedBox(height: AppSizes.xl),
      ],
    );
  }
}

class _PrivacyPolicyTab extends StatelessWidget {
  const _PrivacyPolicyTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSizes.lg),
      children: [
        Text('Privacy Policy', style: AppTextStyles.h2),
        const SizedBox(height: AppSizes.sm),
        Text(
          'Last updated: January 2025',
          style: AppTextStyles.caption.copyWith(color: AppColors.textLight),
        ),
        const SizedBox(height: AppSizes.lg),
        
        _Section(
          title: '1. Information We Collect',
          content: 'We collect the following information:\n\n'
              '• Account Information: Name, email, student/staff ID\n'
              '• Usage Data: Parking history, reservation patterns\n'
              '• Device Information: Device type, app version\n'
              '• Location Data: Only when using navigation features',
        ),
        
        _Section(
          title: '2. How We Use Your Information',
          content: 'Your information is used to:\n\n'
              '• Provide and improve the parking service\n'
              '• Send reservation confirmations and alerts\n'
              '• Analyze usage patterns to optimize availability\n'
              '• Communicate important updates\n'
              '• Ensure security and prevent fraud',
        ),
        
        _Section(
          title: '3. Data Storage',
          content: 'Your data is stored securely using:\n\n'
              '• Firebase Cloud Services with encryption\n'
              '• Secure authentication protocols\n'
              '• Regular security audits\n\n'
              'Data is retained as long as your account is active.',
        ),
        
        _Section(
          title: '4. Data Sharing',
          content: 'We do not sell your personal information. We may share data with:\n\n'
              '• University administration for parking management\n'
              '• Service providers who assist in app operation\n'
              '• Law enforcement when required by law',
        ),
        
        _Section(
          title: '5. Your Rights',
          content: 'You have the right to:\n\n'
              '• Access your personal data\n'
              '• Correct inaccurate information\n'
              '• Delete your account and data\n'
              '• Opt-out of non-essential communications\n'
              '• Export your parking history',
        ),
        
        _Section(
          title: '6. Notifications',
          content: 'We send notifications for:\n\n'
              '• Reservation confirmations\n'
              '• Expiry warnings\n'
              '• System updates\n\n'
              'You can manage notification preferences in the app settings.',
        ),
        
        _Section(
          title: '7. Children\'s Privacy',
          content: 'This service is intended for university students and staff. '
              'We do not knowingly collect information from children under 18 '
              'who are not enrolled at the university.',
        ),
        
        _Section(
          title: '8. Changes to Policy',
          content: 'We may update this privacy policy periodically. '
              'We will notify you of significant changes through the app '
              'or via email.',
        ),
        
        _Section(
          title: '9. Contact Us',
          content: 'For privacy-related questions:\n\n'
              'Email: privacy@spotwise.psu.edu.sa\n'
              'Address: Prince Sultan University, Riyadh, Saudi Arabia',
        ),
        
        const SizedBox(height: AppSizes.xl),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String content;

  const _Section({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            content,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textLight,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
