import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/routes/app_routes.dart';
import 'core/constants/app_colors.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/parking_provider.dart';
import 'providers/notification_provider.dart';
import 'services/fcm_service.dart';

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Handling background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize FCM background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ParkingProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        Provider(create: (_) => FCMService()),
      ],
      child: const AppRoot(),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  @override
  void initState() {
    super.initState();
    _initializeFCM();
  }

  Future<void> _initializeFCM() async {
    final fcmService = Provider.of<FCMService>(context, listen: false);
    await fcmService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpotWise',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Color Scheme
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlue,
          primary: AppColors.primaryBlue,
          secondary: AppColors.lightBlue,
          surface: AppColors.backgroundWhite,
        ),

        // Primary Color
        primaryColor: AppColors.primaryBlue,
        scaffoldBackgroundColor: AppColors.backgroundWhite,

        // AppBar Theme
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.backgroundWhite,
          foregroundColor: AppColors.textDark,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: AppColors.textDark),
        ),

        // Text Theme
        fontFamily: 'Inter',
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
          displayMedium: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
          displaySmall: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: AppColors.textDark,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: AppColors.textLight,
          ),
        ),

        // Input Decoration Theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.backgroundWhite,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.disabledGray),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.disabledGray),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.primaryBlue,
              width: 2,
            ),
          ),
        ),

        // Button Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: AppColors.backgroundWhite,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // Card Theme
        cardTheme: CardThemeData(
          color: AppColors.backgroundWhite,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        // Divider Theme
        dividerTheme: const DividerThemeData(
          color: AppColors.disabledGray,
          thickness: 1,
        ),

        // Bottom Navigation Bar Theme
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.backgroundWhite,
          selectedItemColor: AppColors.primaryBlue,
          unselectedItemColor: AppColors.textLight,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
      ),

      // Routes
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
    );
  }
}
