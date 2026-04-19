import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';

class HelpFaqScreen extends StatelessWidget {
  const HelpFaqScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & FAQ'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.md),
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search for help...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppColors.backgroundGray,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          
          Text('Frequently Asked Questions', style: AppTextStyles.h3),
          const SizedBox(height: AppSizes.md),
          
          _FaqItem(
            question: 'How do I reserve a parking spot?',
            answer: '1. Open the app and go to Parking Zones\n'
                '2. Select a zone with available spots\n'
                '3. Tap "View Available Spots"\n'
                '4. Select an available (green) spot\n'
                '5. Choose your duration and tap "Reserve"',
          ),
          _FaqItem(
            question: 'How long can I reserve a spot?',
            answer: 'You can reserve a spot for 15 minutes up to 2 hours. '
                'You can extend your reservation if needed from the Active Reservation screen.',
          ),
          _FaqItem(
            question: 'What happens if my reservation expires?',
            answer: 'If your reservation expires, the spot will automatically become available '
                'for other users. You will receive a notification 5 minutes before expiry.',
          ),
          _FaqItem(
            question: 'Can I cancel my reservation?',
            answer: 'Yes, you can cancel your reservation at any time from the Active Reservation screen. '
                'Simply tap the "Cancel Booking" button.',
          ),
          _FaqItem(
            question: 'How do I change my profile information?',
            answer: 'Go to Profile > Edit Profile. You can update your name, student ID, '
                'and profile picture from there.',
          ),
          _FaqItem(
            question: 'What do the spot colors mean?',
            answer: '• Green: Available - You can reserve this spot\n'
                '• Red: Occupied - Someone is parked there\n'
                '• Yellow: Reserved - Someone has reserved it\n'
                '• Gray: Disabled - Not available for use',
          ),
          _FaqItem(
            question: 'How do I enable/disable notifications?',
            answer: 'Go to Profile > Notifications. You can toggle different types of '
                'notifications including reservation confirmations, expiry warnings, and more.',
          ),
          _FaqItem(
            question: 'I forgot my password. What should I do?',
            answer: 'On the login screen, tap "Forgot Password?" and enter your email. '
                'You will receive a password reset link.',
          ),
          
          const SizedBox(height: AppSizes.xl),
          
          // Still need help section
          Container(
            padding: const EdgeInsets.all(AppSizes.lg),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.help_outline,
                  size: 48,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(height: AppSizes.md),
                Text(
                  'Still need help?',
                  style: AppTextStyles.h3,
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  'Contact our support team for assistance',
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.md),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/contact-support');
                  },
                  child: const Text('Contact Support'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.xl),
        ],
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqItem({
    required this.question,
    required this.answer,
  });

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: ExpansionTile(
        title: Text(
          widget.question,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: Icon(
          _isExpanded ? Icons.remove_circle : Icons.add_circle,
          color: AppColors.primaryBlue,
        ),
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Text(
              widget.answer,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
