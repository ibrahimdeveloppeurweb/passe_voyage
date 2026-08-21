import 'dart:async';
import 'package:flutter/material.dart';
import 'storage_service.dart';
import '../../config/routes.dart';

class InactivityService with WidgetsBindingObserver {
  static final InactivityService _instance = InactivityService._internal();
  factory InactivityService() => _instance;

  InactivityService._internal();

  static const Duration timeoutDuration = Duration(minutes: 2);
  Timer? _inactivityTimer;
  DateTime? _pausedTime;
  GlobalKey<NavigatorState>? _navigatorKey;
  bool _isInitialized = false;
  bool _isLocked = false;

  void init(GlobalKey<NavigatorState> navigatorKey) {
    if (_isInitialized) return;
    _navigatorKey = navigatorKey;
    _isInitialized = true;
    WidgetsBinding.instance.addObserver(this);
    resetTimer();
  }

  Future<void> unlockSession() async {
    _isLocked = false;
    _pausedTime = null;
    final storage = await StorageService.getInstance();
    await storage.setLocked(false);
    resetTimer();
  }

  void userActivityDetected() {
    if (_isLocked) return;
    _resetInactivityTimer();
  }

  void _resetInactivityTimer() {
    if (_isLocked) return;
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(timeoutDuration, _handleTimeout);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('📱 [AppLifecycleState] $state');
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _pausedTime ??= DateTime.now();
      _inactivityTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedTime != null) {
        final elapsed = DateTime.now().difference(_pausedTime!);
        debugPrint('⏱️ [AppLifecycleState resumed] Durée d\'absence: ${elapsed.inSeconds} secondes');
        _pausedTime = null;
        if (elapsed >= timeoutDuration) {
          _handleTimeout();
          return;
        }
      }
      _resetInactivityTimer();
    }
  }

  Future<void> _handleTimeout() async {
    if (_isLocked) return;

    final storage = await StorageService.getInstance();
    final savedPhone = storage.getPhoneNumber() ?? storage.getPassengerData()?['phoneNumber'] ?? '';

    if (savedPhone.isEmpty) return;

    _isLocked = true;
    _inactivityTimer?.cancel();
    await storage.setLocked(true);

    debugPrint('🔒 [InactivityService] Timeout 2 min atteint. Redirection vers LoginScreen pour le numéro $savedPhone');

    _navigatorKey?.currentState?.pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
      arguments: {'phoneNumber': savedPhone},
    );
  }

  void resetTimer() {
    _resetInactivityTimer();
  }
}
