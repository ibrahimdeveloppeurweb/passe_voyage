import 'package:flutter/material.dart';
import '../presentation/screens/auth/phone_entry_screen.dart';
import '../presentation/screens/auth/otp_validation_screen.dart';
import '../presentation/screens/auth/pin_entry_screen.dart';
import '../presentation/screens/auth/personal_info_screen.dart';
import '../presentation/screens/credit/demande_credit_screen.dart';
import '../presentation/screens/credit/remboursement_screen.dart';
import '../presentation/screens/credit/mes_pass_screen.dart';
import '../presentation/screens/credit/mes_remboursements_screen.dart';
import '../presentation/screens/home/dashboard_screen.dart';
import '../presentation/screens/home/notifications_screen.dart';
import '../presentation/screens/identity/custom_camera_screen.dart';
import '../presentation/screens/identity/identity_document_screen.dart';
import '../presentation/screens/gares/gares_screen.dart';
import '../presentation/screens/identity/identity_selection_screen.dart';
import '../presentation/screens/identity/identity_selfie_screen.dart';
import '../presentation/screens/payments/factures_screen.dart';
import '../presentation/screens/profile/profile_screen.dart';
import '../presentation/screens/profile/settings_screen.dart';

class AppRoutes {
  static const String phoneEntry = '/phone_entry';
  static const String otpValidation = '/otp_validation';
  static const String pinEntry = '/pin_entry';
  static const String dashboard = '/dashboard';
  static const String notifications = '/notifications';
  static const String demandeCredit = '/demande_credit';
  static const String remboursement = '/remboursement';
  static const String mesPass = '/mes_pass';
  static const String mesRemboursements = '/mes_remboursements';
  static const String personalInfo = '/personal_info';
  static const String factures = '/factures';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String identitySelection = '/identity_selection';
  static const String identityDocument = '/identity_document';
  static const String identitySelfie = '/identity_selfie';
  static const String customCamera = '/custom_camera';
  static const String gares = '/gares';

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
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const DashboardScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        );
      case notifications:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => const NotificationsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        );
      case identitySelection:
        return MaterialPageRoute(builder: (_) => const IdentitySelectionScreen());
      case identityDocument:
        return MaterialPageRoute(builder: (_) => const IdentityDocumentScreen());
      case identitySelfie:
        return MaterialPageRoute(builder: (_) => const IdentitySelfieScreen());
      case customCamera:
        return MaterialPageRoute(builder: (_) => const CustomCameraScreen());
      case gares:
        return MaterialPageRoute(builder: (_) => const GaresScreen());
      case demandeCredit:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => const DemandeCreditScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0); // Slide from right for new screens
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        );
      case remboursement:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => const RemboursementScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        );
      case mesPass:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => const MesPassScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(position: animation.drive(tween), child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        );
      case mesRemboursements:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => const MesRemboursementsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(position: animation.drive(tween), child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        );
      case personalInfo:
        return MaterialPageRoute(builder: (_) => const PersonalInfoScreen());
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
