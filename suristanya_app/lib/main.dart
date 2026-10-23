import 'package:flutter/material.dart';

import 'services/auth_store.dart';
import 'services/scan_history_store.dart';
import 'theme/app_theme.dart';
import 'widgets/connection_banner.dart';

// Screens
import 'screens/welcome_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/how_it_works_screen.dart';
import 'screens/dashboard_screen.dart'; 
import 'screens/chatbot_screen.dart';
import 'screens/labs_screen.dart'; // <-- ADDED
import 'screens/scan_screen.dart';
import 'screens/processing_screen.dart';
import 'screens/results_screen.dart';
import 'screens/full_report_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/history_screen.dart';
import 'screens/privacy_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthStore.instance.load();
  await ScanHistoryStore.instance.load();
  runApp(const SuristanyaApp());
}

class SuristanyaApp extends StatelessWidget {
  const SuristanyaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final initial = AuthStore.instance.isSignedIn ? '/dashboard' : '/';

    return MaterialApp(
      title: 'Suristanya',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: initial,
      builder: (context, child) =>
          ConnectionBanner(child: child ?? const SizedBox()),
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/signin': (context) => const SignInScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/forgot': (context) => const ForgotPasswordScreen(),
        '/how': (context) => const HowItWorksScreen(),
        '/dashboard': (context) => const DashboardScreen(), 
        '/chat': (context) => const ChatbotScreen(),
        '/labs': (context) => const LabsScreen(), // <-- ADDED
        '/scan': (context) => const ScanScreen(),
        '/processing': (context) => const ProcessingScreen(),
        '/results': (context) => const ResultsScreen(),
        '/full-report': (context) => const FullReportScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/history': (context) => const HistoryScreen(),
        '/privacy': (context) => const PrivacyScreen(),
      },
    );
  }
}