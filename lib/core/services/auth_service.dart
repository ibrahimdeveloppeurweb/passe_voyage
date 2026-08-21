import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'notification_push_service.dart';

class AuthService {
  /// Helper pour préfixer le numéro avec l'indicatif pays s'il ne le contient pas déjà
  static String formatFullPhone(String phone, [String countryCode = '+225']) {
    final String codeDigits = countryCode.replaceAll(RegExp(r'[^0-9]'), '');
    final String phoneDigits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phoneDigits.isEmpty) return phone;
    
    if (codeDigits.isNotEmpty && !phoneDigits.startsWith(codeDigits)) {
      return '+$codeDigits$phoneDigits';
    }
    return '+$phoneDigits';
  }

  /// Demande d'envoi du code OTP au backend
  static Future<Map<String, dynamic>> sendOtp(String phone, [String countryCode = '+225']) async {
    try {
      final fullPhone = formatFullPhone(phone, countryCode);
      final response = await ApiService.post('/api/public/passenger/send-otp', {
        'phone': fullPhone,
      });

      final data = jsonDecode(response.body);
      final isAccountExist = data['accountExists'] == true || (data['message'] != null && data['message'].toString().toLowerCase().contains('existe déj'));

      if (response.statusCode == 200 || isAccountExist) {
        return {
          'success': true,
          'message': data['message'] ?? 'Code OTP envoyé',
          'otpCode': data['otpCode'],
          'accountExists': isAccountExist,
        };
      } else {
        debugPrint('⚠️ [AuthService sendOtp Failed] Code ${response.statusCode}: ${response.body}');
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de l\'envoi du code OTP',
        };
      }
    } catch (e, stackTrace) {
      debugPrint('💥 [AuthService sendOtp Exception] Error: $e\n$stackTrace');
      return {
        'success': false,
        'message': 'Connexion Internet requise. Veuillez vérifier votre réseau puis réessayer.',
      };
    }
  }

  /// Vérification du code OTP
  static Future<Map<String, dynamic>> verifyOtp(String phone, String code, [String countryCode = '+225']) async {
    try {
      final fullPhone = formatFullPhone(phone, countryCode);
      final response = await ApiService.post('/api/public/passenger/verify-otp', {
        'phone': fullPhone,
        'code': code,
      });

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Code valide',
        };
      } else {
        debugPrint('⚠️ [AuthService verifyOtp Failed] Code ${response.statusCode}: ${response.body}');
        return {
          'success': false,
          'message': data['message'] ?? 'Code de validation incorrect',
        };
      }
    } catch (e, stackTrace) {
      debugPrint('💥 [AuthService verifyOtp Exception] Error: $e\n$stackTrace');
      return {
        'success': false,
        'message': 'Connexion Internet requise. Veuillez vérifier votre réseau puis réessayer.',
      };
    }
  }

  /// Inscription d'un nouveau passager + stockage local
  static Future<Map<String, dynamic>> registerPassenger({
    required String phoneNumber,
    required String pinCode,
    required String firstname,
    required String lastname,
    required String gender,
    required String residenceAddress,
    String countryCode = '+225',
  }) async {
    try {
      final fullPhone = formatFullPhone(phoneNumber, countryCode);
      final fcmToken = await NotificationPushService.getFcmToken();

      final body = {
        'phoneNumber': fullPhone,
        'pinCode': pinCode,
        'firstname': firstname,
        'lastname': lastname,
        'gender': gender,
        'residenceAddress': residenceAddress,
        'countryCode': countryCode,
        'fcmToken': fcmToken,
      };

      final response = await ApiService.post('/api/public/passenger/register', body);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final token = data['token'];
        final passenger = data['passenger'];

        try {
          final storage = await StorageService.getInstance();
          if (token != null) {
            await storage.saveToken(token.toString());
          }
          if (passenger != null && passenger is Map<String, dynamic>) {
            await storage.savePassengerData(passenger);
          }
          await storage.savePhoneNumber(fullPhone);
          await storage.savePinCode(pinCode);
          NotificationPushService.syncFcmToken();
        } catch (storageError) {
          debugPrint('⚠️ [AuthService registerPassenger] Storage save failed: $storageError');
        }

        return {
          'success': true,
          'message': data['message'] ?? 'Compte créé avec succès',
          'token': token,
          'passenger': passenger,
        };
      } else {
        debugPrint('⚠️ [AuthService registerPassenger Failed] Code ${response.statusCode}: ${response.body}');
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de l\'inscription',
        };
      }
    } catch (e, stackTrace) {
      debugPrint('💥 [AuthService registerPassenger Exception] Error: $e\n$stackTrace');
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur lors de l\'inscription.',
      };
    }
  }

  /// Connexion d'un passager existant (Online + Offline)
  static Future<Map<String, dynamic>> loginPassenger({
    required String phone,
    required String pinCode,
    String countryCode = '+225',
  }) async {
    final storage = await StorageService.getInstance();
    final fullPhone = formatFullPhone(phone, countryCode);
    final fcmToken = await NotificationPushService.getFcmToken();

    try {
      final response = await ApiService.post('/api/public/passenger/login', {
        'phone': fullPhone,
        'pinCode': pinCode,
        'fcmToken': fcmToken,
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token = data['token'];
        final passenger = data['passenger'];

        try {
          if (token != null) {
            await storage.saveToken(token.toString());
          }
          if (passenger != null && passenger is Map<String, dynamic>) {
            await storage.savePassengerData(passenger);
          }
          await storage.savePhoneNumber(fullPhone);
          await storage.savePinCode(pinCode);
          NotificationPushService.syncFcmToken();
        } catch (storageError) {
          debugPrint('⚠️ [AuthService loginPassenger] Storage save failed: $storageError');
        }

        return {
          'success': true,
          'token': token,
          'passenger': passenger,
          'offline': false,
        };
      } else {
        debugPrint('⚠️ [AuthService loginPassenger Failed] Code ${response.statusCode}: ${response.body}');
        return {
          'success': false,
          'message': data['message'] ?? 'Code secret PIN ou numéro incorrect',
        };
      }
    } catch (e, stackTrace) {
      debugPrint('⚡ [AuthService loginPassenger Offline Fallback] Exception: $e');

      final savedPin = storage.getPinCode();
      final savedPassenger = storage.getPassengerData();
      final savedPhone = storage.getPhoneNumber() ?? savedPassenger?['phoneNumber'];

      final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
      final cleanSavedPhone = (savedPhone ?? '').replaceAll(RegExp(r'[^0-9]'), '');
      final isPhoneMatching = cleanSavedPhone.isEmpty || cleanSavedPhone == cleanPhone || cleanPhone.endsWith(cleanSavedPhone) || cleanSavedPhone.endsWith(cleanPhone);

      if (savedPassenger != null && isPhoneMatching) {
        if (savedPin == null || savedPin == pinCode) {
          if (savedPin == null) {
            await storage.savePinCode(pinCode);
          }
          await storage.savePassengerData(savedPassenger);
          debugPrint('✅ [Wave Offline Auth Success] Authentifié localement avec succès !');
          return {
            'success': true,
            'offline': true,
            'message': 'Connexion hors-ligne effectuée',
            'passenger': savedPassenger,
          };
        }
      }

      return {
        'success': false,
        'message': 'Code secret PIN incorrect (Mode hors-ligne).',
      };
    }
  }
}
