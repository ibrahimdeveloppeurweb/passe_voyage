import 'package:flutter/material.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/notification_push_service.dart';
import '../../config/routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    final storage = await StorageService.getInstance();
    final isLocked = storage.isLocked();
    final isLoggedIn = storage.isLoggedIn();
    final hasAccount = storage.hasSavedAccount();
    final savedPhone = storage.getPhoneNumber() ?? storage.getPassengerData()?['phoneNumber'] ?? '';

    debugPrint('🚀 [SplashScreen] isLocked: $isLocked, isLoggedIn: $isLoggedIn, hasAccount: $hasAccount, savedPhone: $savedPhone');

    if (!mounted) return;

    // Vérification de l'inactivité si l'application était tuée / fermée
    bool shouldLockDueToInactivity = false;
    if (!isLocked && isLoggedIn) {
      final lastActive = storage.getLastActiveTime();
      if (lastActive != null) {
        final lastActiveDate = DateTime.fromMillisecondsSinceEpoch(lastActive);
        final elapsed = DateTime.now().difference(lastActiveDate);
        if (elapsed.inMinutes >= 2) { // 2 minutes max pour l'app Passager
          shouldLockDueToInactivity = true;
          await storage.setLocked(true);
        }
      }
    }

    if ((isLocked || shouldLockDueToInactivity) && savedPhone.isNotEmpty) {
      // Si la session est actuellement verrouillée -> Redirection obligatoire sur LoginScreen
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.login,
        arguments: {'phoneNumber': savedPhone},
      );
    } else if (isLoggedIn && !shouldLockDueToInactivity) {
      // Session authentifiée et déverrouillée -> Accès direct au Dashboard
      NotificationPushService.syncFcmToken();
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } else if (hasAccount && savedPhone.isNotEmpty) {
      // Compte enregistré sur l'appareil -> Écran Login PIN
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.login,
        arguments: {'phoneNumber': savedPhone},
      );
    } else {
      // Premier lancement / Aucun compte -> Inscription
      Navigator.pushReplacementNamed(context, AppRoutes.phoneEntry);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
