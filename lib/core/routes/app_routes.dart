import 'package:flutter/material.dart';
import '../../views/splash_screen.dart';
import '../../views/onboarding/onboarding_screen.dart';
import '../../views/auth/login_screen.dart';
import '../../views/auth/signup_screen.dart';
import '../../views/auth/verification_screen.dart';
import '../../views/home/home_screen.dart';
import '../../views/map/map_screen.dart';
import '../../views/campus/campus_selection_screen.dart';
import '../../views/zone/zone_details_screen.dart';
import '../../views/booking/spot_selection_screen.dart';
import '../../views/booking/reservation_confirmation_screen.dart';
import '../../views/reservation/active_reservation_screen.dart';
import '../../views/navigation/navigation_screen.dart';
import '../../views/notifications/notifications_screen.dart';
import '../../views/profile/profile_screen.dart';
import '../../views/profile/edit_profile_screen.dart';
import '../../views/reservation/my_reservations_screen.dart';
import '../../views/settings/notification_settings_screen.dart';
import '../../views/settings/map_settings_screen.dart';
import '../../views/support/help_faq_screen.dart';
import '../../views/support/contact_support_screen.dart';
import '../../views/support/terms_privacy_screen.dart';
import '../../views/history/parking_history_screen.dart';
import '../../views/statistics/statistics_screen.dart';
import '../../views/admin/admin_dashboard_screen.dart';
import '../../views/admin/parking_detection_screen.dart';
import '../../views/parking_detection/parking_gallery_screen.dart';
import '../../views/parking_detection/parking_detection_results_screen.dart';
import '../../models/parking_image_model.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String verification = '/verification';
  static const String home = '/home';
  static const String map = '/map';
  static const String campusSelection = '/campus-selection';
  static const String zoneDetails = '/zone-details';
  static const String spotSelection = '/spot-selection';
  static const String reservationConfirmation = '/reservation-confirmation';
  static const String reservation = '/reservation';
  static const String navigation = '/navigation';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String myReservations = '/my-reservations';
  static const String settings = '/settings';
  static const String notificationSettings = '/notification-settings';
  static const String mapSettings = '/map-settings';
  static const String helpFaq = '/help-faq';
  static const String contactSupport = '/contact-support';
  static const String termsPrivacy = '/terms-privacy';
  static const String history = '/history';
  static const String statistics = '/statistics';
  static const String admin = '/admin';
  static const String aiDetection = '/ai-detection';
  static const String parkingGallery = '/parking-gallery';
  static const String parkingDetection = '/parking-detection';

  static Map<String, WidgetBuilder> get routes {
    return {
      splash: (context) => const SplashScreen(),
      onboarding: (context) => const OnboardingScreen(),
      login: (context) => const LoginScreen(),
      signup: (context) => const SignUpScreen(),
      verification: (context) => const VerificationScreen(),
      home: (context) => const HomeScreen(),
      map: (context) => const MapScreen(),
      campusSelection: (context) => const CampusSelectionScreen(),
      zoneDetails: (context) => const ZoneDetailsScreen(),
      spotSelection: (context) => const SpotSelectionScreen(),
      reservationConfirmation: (context) =>
          const ReservationConfirmationScreen(),
      reservation: (context) => const ActiveReservationScreen(),
      navigation: (context) => const NavigationScreen(),
      notifications: (context) => const NotificationsScreen(),
      profile: (context) => const ProfileScreen(),
      editProfile: (context) => const EditProfileScreen(),
      myReservations: (context) => const MyReservationsScreen(),
      notificationSettings: (context) => const NotificationSettingsScreen(),
      mapSettings: (context) => const MapSettingsScreen(),
      helpFaq: (context) => const HelpFaqScreen(),
      contactSupport: (context) => const ContactSupportScreen(),
      termsPrivacy: (context) => const TermsPrivacyScreen(),
      history: (context) => const ParkingHistoryScreen(),
      statistics: (context) => const StatisticsScreen(),
      admin: (context) => const AdminDashboardScreen(),
      aiDetection: (context) => const ParkingDetectionScreen(),
      parkingGallery: (context) => const ParkingGalleryScreen(),
      parkingDetection: (context) {
        final parkingImage = ModalRoute.of(context)!.settings.arguments as ParkingImageModel;
        return ParkingDetectionResultsScreen(parkingImage: parkingImage);
      },
    };
  }
}
