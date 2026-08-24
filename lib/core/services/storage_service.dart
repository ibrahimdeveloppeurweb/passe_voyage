import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'hive_storage_service.dart';

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
    } else {
      try {
        await _prefs?.reload();
      } catch (e) {
        debugPrint('⚠️ [StorageService] SharedPreferences reload error: $e');
      }
    }
    return _instance!;
  }

  // Token JWT
  Future<bool> saveToken(String token) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      _prefs = prefs;
      return await prefs.setString('auth_token', token);
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
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      _prefs = prefs;
      return await prefs.remove('auth_token');
    } catch (e) {
      return false;
    }
  }

  // Numéro de Téléphone Persistant (Style Wave)
  Future<bool> savePhoneNumber(String phone) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      _prefs = prefs;
      return await prefs.setString('saved_phone', phone);
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
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      _prefs = prefs;
      return await prefs.setString('saved_pin', pin);
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
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      _prefs = prefs;
      final encoded = jsonEncode(passenger);
      await prefs.setBool('is_authenticated', true);
      return await prefs.setString('passenger_data', encoded);
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
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      _prefs = prefs;
      await prefs.remove('is_authenticated');
      return await prefs.remove('passenger_data');
    } catch (e) {
      return false;
    }
  }

  // Verrouillage de Session (Persistant)
  Future<bool> setLocked(bool locked) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      _prefs = prefs;
      return await prefs.setBool('is_locked', locked);
    } catch (e) {
      return false;
    }
  }

  bool isLocked() {
    try {
      return _prefs?.getBool('is_locked') ?? false;
    } catch (_) {
      return false;
    }
  }

  // Heure de la dernière activité (pour l'inactivité)
  Future<bool> saveLastActiveTime(int timestamp) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      _prefs = prefs;
      return await prefs.setInt('last_active_time', timestamp);
    } catch (e) {
      return false;
    }
  }

  int? getLastActiveTime() {
    try {
      return _prefs?.getInt('last_active_time');
    } catch (_) {
      return null;
    }
  }

  // Vérifie si un compte est déjà enregistré sur l'appareil (Style Wave)
  bool hasSavedAccount() {
    final phone = getPhoneNumber();
    final data = getPassengerData();
    final isAuth = _prefs?.getBool('is_authenticated') ?? false;
    return isAuth || (phone != null && phone.isNotEmpty) || (data != null && data.isNotEmpty);
  }

  // Session : l'utilisateur est considéré comme connecté s'il a un profil passager enregistré
  bool isLoggedIn() {
    final isAuth = _prefs?.getBool('is_authenticated') ?? false;
    final token = getToken();
    final passenger = getPassengerData();
    final phone = getPhoneNumber();

    return isAuth || (token != null && token.isNotEmpty) || (passenger != null && passenger.isNotEmpty) || (phone != null && phone.isNotEmpty);
  }

  // Déconnexion manuelle
  Future<void> logout() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    await prefs.remove('auth_token');
    await prefs.remove('passenger_data');
    await prefs.remove('saved_phone');
    await prefs.remove('saved_pin');
    await prefs.remove('is_authenticated');
    await prefs.remove('is_locked');
    await prefs.clear();
    await HiveStorageService.clearAll();
  }

  Future<void> resetAll() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    await prefs.clear();
    await HiveStorageService.clearAll();
  }

  // Settings Preferences
  Future<bool> setNotificationsEnabled(bool enabled) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    return await prefs.setBool('notifications_enabled', enabled);
  }

  bool getNotificationsEnabled() {
    return _prefs?.getBool('notifications_enabled') ?? true;
  }

  Future<bool> setLocationEnabled(bool enabled) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    return await prefs.setBool('location_enabled', enabled);
  }

  bool getLocationEnabled() {
    return _prefs?.getBool('location_enabled') ?? true;
  }

  Future<bool> setLastRating(int rating) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    return await prefs.setInt('last_app_rating', rating);
  }

  int getLastRating() {
    return _prefs?.getInt('last_app_rating') ?? 5;
  }

  // Dashboard Cache (Offline First)
  Future<bool> saveFormattedCredit(String formattedCredit) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    return await prefs.setString('cached_formatted_credit', formattedCredit);
  }

  String getFormattedCredit() {
    return _prefs?.getString('cached_formatted_credit') ?? '0';
  }

  Future<bool> saveRecentActivities(List<dynamic> activities) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    return await prefs.setString('cached_recent_activities', jsonEncode(activities));
  }

  List<Map<String, dynamic>> getRecentActivities() {
    try {
      final raw = _prefs?.getString('cached_recent_activities');
      if (raw != null && raw.isNotEmpty) {
        final sanitized = raw.replaceAll('FCFA', 'XOF');
        final decoded = jsonDecode(sanitized);
        if (decoded is List) {
          return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }
    } catch (e) {
      debugPrint('⚠️ [StorageService] Error reading cached_recent_activities: $e');
    }
    return [];
  }
}
