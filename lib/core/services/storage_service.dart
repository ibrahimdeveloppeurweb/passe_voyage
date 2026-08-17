import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static StorageService? _instance;
  static SharedPreferences? _prefs;

  StorageService._();

  static Future<StorageService> getInstance() async {
    _instance ??= StorageService._();
    if (_prefs == null) {
      try {
        _prefs = await SharedPreferences.getInstance();
      } catch (e) {
        debugPrint('⚠️ [StorageService] SharedPreferences initialization error: $e');
      }
    }
    return _instance!;
  }

  // Token JWT
  Future<bool> saveToken(String token) async {
    try {
      if (_prefs == null) {
        try {
          _prefs = await SharedPreferences.getInstance();
        } catch (_) {}
      }
      return await _prefs?.setString('auth_token', token) ?? false;
    } catch (e) {
      debugPrint('⚠️ [StorageService] saveToken error: $e');
      return false;
    }
  }

  String? getToken() {
    try {
      return _prefs?.getString('auth_token');
    } catch (_) {
      return null;
    }
  }

  Future<bool> clearToken() async {
    try {
      if (_prefs == null) {
        try {
          _prefs = await SharedPreferences.getInstance();
        } catch (_) {}
      }
      return await _prefs?.remove('auth_token') ?? false;
    } catch (e) {
      return false;
    }
  }

  // Numéro de Téléphone Persistant (Style Wave)
  Future<bool> savePhoneNumber(String phone) async {
    try {
      if (_prefs == null) {
        try {
          _prefs = await SharedPreferences.getInstance();
        } catch (_) {}
      }
      return await _prefs?.setString('saved_phone', phone) ?? false;
    } catch (e) {
      return false;
    }
  }

  String? getPhoneNumber() {
    try {
      return _prefs?.getString('saved_phone');
    } catch (_) {
      return null;
    }
  }

  // Code PIN Persistant (Style Wave)
  Future<bool> savePinCode(String pin) async {
    try {
      if (_prefs == null) {
        try {
          _prefs = await SharedPreferences.getInstance();
        } catch (_) {}
      }
      return await _prefs?.setString('saved_pin', pin) ?? false;
    } catch (e) {
      return false;
    }
  }

  String? getPinCode() {
    try {
      return _prefs?.getString('saved_pin');
    } catch (_) {
      return null;
    }
  }

  // Données Passager (JSON)
  Future<bool> savePassengerData(Map<String, dynamic> passenger) async {
    try {
      if (_prefs == null) {
        try {
          _prefs = await SharedPreferences.getInstance();
        } catch (_) {}
      }
      return await _prefs?.setString('passenger_data', jsonEncode(passenger)) ?? false;
    } catch (e) {
      debugPrint('⚠️ [StorageService] savePassengerData error: $e');
      return false;
    }
  }

  Map<String, dynamic>? getPassengerData() {
    try {
      final data = _prefs?.getString('passenger_data');
      if (data != null && data.isNotEmpty) {
        return jsonDecode(data) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('⚠️ [StorageService] getPassengerData error: $e');
    }
    return null;
  }

  Future<bool> clearPassengerData() async {
    try {
      if (_prefs == null) {
        try {
          _prefs = await SharedPreferences.getInstance();
        } catch (_) {}
      }
      return await _prefs?.remove('passenger_data') ?? false;
    } catch (e) {
      return false;
    }
  }

  // Vérifie si un compte est déjà enregistré sur l'appareil (Style Wave)
  bool hasSavedAccount() {
    final phone = getPhoneNumber();
    final data = getPassengerData();
    return (phone != null && phone.isNotEmpty) || (data != null && data.isNotEmpty);
  }

  // Session
  bool isLoggedIn() {
    final token = getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    await clearToken();
    await clearPassengerData();
    // On conserve le numéro de téléphone et le PIN pour réauthentification Wave rapide
  }

  Future<void> resetAll() async {
    await _prefs?.clear();
  }
}
