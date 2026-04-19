import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      icon: Icons.search,
      title: 'Find Parking in\nSeconds',
      description: 'Never waste time searching for parking again',
      color: AppColors.primaryBlue,
    ),
    OnboardingData(
      icon: Icons.videocam,
      title: 'Live Parking\nUpdates',
      description: 'See available spots in real-time with AI-powered cameras',
      color: AppColors.availableGreen,
    ),
    OnboardingData(
      icon: Icons.bookmark,
      title: 'Reserve &\nNavigate',
      description: 'Book your spot and get directions instantly',
      color: AppColors.reservedYellow,
    ),
    OnboardingData(
      icon: Icons.notifications_active,
      title: 'Stay\nInformed',
      description: 'Receive alerts when spots open or your time expires',
      color: AppColors.occupiedRed,
    ),
  ];

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
              // Skip Button
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _skipToLogin,
                  child: const Text(
                    'Skip',
                    style: AppTextStyles.body,
                  ),
                ),
              ),
              // PageView
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPage(_pages[index]);
                  },
                ),
              ),
              // Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => _buildIndicator(index),
                ),
              ),
              const SizedBox(height: AppSizes.xl),
              // Next/Get Started Button
              Padding(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: CustomButton(
                  text: _currentPage == _pages.length - 1
                      ? 'Get Started'
                      : 'Next',
                  onPressed: () {
                    if (_currentPage == _pages.length - 1) {
                      _skipToLogin();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: AppSizes.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingData data) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              data.icon,
              size: 100,
              color: data.color,
            ),
          ),
          const SizedBox(height: AppSizes.xxl),
          // Title
          Text(
            data.title,
            style: AppTextStyles.h1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.md),
          // Description
          Text(
            data.description,
            style: AppTextStyles.bodyLight,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: _currentPage == index ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? AppColors.primaryBlue
            : AppColors.disabledGray,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  void _skipToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class OnboardingData {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  OnboardingData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
