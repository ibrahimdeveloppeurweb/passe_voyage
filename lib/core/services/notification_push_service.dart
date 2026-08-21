import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';
import 'storage_service.dart';
import '../../main.dart';
import '../../config/routes.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("🔔 [FCM Background Message] ID: ${message.messageId} - Title: ${message.notification?.title}");
}

class NotificationPushService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  static final StreamController<Map<String, dynamic>> _onNotificationStream = StreamController<Map<String, dynamic>>.broadcast();
  static Stream<Map<String, dynamic>> get onNotificationStream => _onNotificationStream.stream;

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Demander l'autorisation des notifications Push
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('🔔 [FCM Settings] User granted permission: ${settings.authorizationStatus}');

      // Autoriser l'affichage des bannières/alertes même lorsque l'application est au premier plan (Foreground)
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Initialiser les notifications locales pour Android & iOS en Foreground
      const AndroidInitializationSettings androidInitSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosInitSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidInitSettings,
        iOS: iosInitSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('🔔 [FCM Local Click] Payload: ${response.payload}');
          _navigateToNotificationsScreen();
        },
      );

      // Canal de notification Android High Priority (Bannière Pop-up)
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'Notifications Pass Voyage',
        description: 'Canal de notifications importantes pour Pass Voyage',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // Récupérer et envoyer le token FCM au serveur
      await syncFcmToken();

      // Écouter le rafraîchissement du Token FCM
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 [FCM Token Refreshed] $newToken');
        sendTokenToServer(newToken);
      });

      // Écouter et afficher les messages en Foreground (Application Ouverte)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('📩 [FCM Foreground Message] Data: ${message.data} - Notification: ${message.notification?.title}');
        _onNotificationStream.add(message.data);
        
        final String title = message.notification?.title ?? message.data['title'] ?? 'Pass Voyage';
        final String body = message.notification?.body ?? message.data['message'] ?? message.data['body'] ?? '';

        if (title.isNotEmpty || body.isNotEmpty) {
          _localNotifications.show(
            message.hashCode,
            title,
            body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                icon: '@mipmap/ic_launcher',
                importance: Importance.max,
                priority: Priority.max,
                playSound: true,
                enableVibration: true,
                visibility: NotificationVisibility.public,
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
            payload: jsonEncode(message.data),
          );
        }
      });

      // Écouter le clic sur la notification quand l'application était en arrière-plan
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('👉 [FCM Opened App] ${message.data}');
        _navigateToNotificationsScreen();
      });

      // Vérifier si l'application a été ouverte depuis une notification (Application fermée)
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('🚀 [FCM Initial Message] ${initialMessage.data}');
        Future.delayed(const Duration(milliseconds: 600), () {
          _navigateToNotificationsScreen();
        });
      }

    } catch (e) {
      debugPrint('⚠️ [FCM Init Exception] Error initializing FCM: $e');
    }
  }

  /// Naviguer vers l'écran des notifications
  static void _navigateToNotificationsScreen() {
    try {
      final navigatorState = PasseVoyageApp.navigatorKey.currentState;
      if (navigatorState != null) {
        navigatorState.pushNamed(AppRoutes.notifications);
      }
    } catch (e) {
      debugPrint('⚠️ [FCM Navigation Error] $e');
    }
  }

  /// Obtenir le token FCM courant
  static Future<String?> getFcmToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      return null;
    }
  }

  /// Synchroniser le Token FCM avec le serveur backend
  static Future<void> syncFcmToken() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        debugPrint('🔑 [FCM Token] $token');
        await sendTokenToServer(token);
      }
    } catch (e) {
      debugPrint('⚠️ [FCM getToken Error] $e');
    }
  }

  /// Envoyer le Token FCM vers l'API backend Symfony
  static Future<void> sendTokenToServer(String token) async {
    try {
      final storage = await StorageService.getInstance();
      final phone = storage.getPhoneNumber() ?? storage.getPassengerData()?['phoneNumber'];

      await ApiService.post('/api/private/passenger/fcm-token', {
        'fcmToken': token,
        'phone': phone,
      });

      debugPrint('✅ [FCM Token Synced] Token envoyé au backend');
    } catch (e) {
      debugPrint('⚠️ [FCM Token Sync Error] $e');
    }
  }
}
