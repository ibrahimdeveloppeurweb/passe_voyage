import 'package:flutter/material.dart';
import '../presentation/screens/auth/phone_entry_screen.dart';
import '../presentation/screens/auth/otp_validation_screen.dart';
import '../presentation/screens/auth/pin_entry_screen.dart';
import '../presentation/screens/home/dashboard_screen.dart';
import '../presentation/screens/payments/factures_screen.dart';
import '../presentation/screens/profile/profile_screen.dart';
import '../presentation/screens/profile/settings_screen.dart';

class AppRoutes {
  static const String phoneEntry = '/phone_entry';
  static const String otpValidation = '/otp_validation';
  static const String pinEntry = '/pin_entry';
  static const String dashboard = '/dashboard';
  static const String factures = '/factures';
  static const String profile = '/profile';
  static const String settings = '/settings';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
      case phoneEntry:
        return MaterialPageRoute(builder: (_) => const PhoneEntryScreen());
      case otpValidation:
        final args = settings.arguments as Map<String, dynamic>?;
        final phoneNumber = args?['phoneNumber'] ?? '';
        return MaterialPageRoute(builder: (_) => OtpValidationScreen(phoneNumber: phoneNumber));
      case pinEntry:
        final args = settings.arguments as Map<String, dynamic>?;
        final phoneNumber = args?['phoneNumber'] ?? '';
        return MaterialPageRoute(builder: (_) => PinEntryScreen(phoneNumber: phoneNumber));
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case factures:
        return MaterialPageRoute(builder: (_) => const FacturesScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route ${settings.name} introuvable.'),
            ),
          ),
        );
    }
  }
}
