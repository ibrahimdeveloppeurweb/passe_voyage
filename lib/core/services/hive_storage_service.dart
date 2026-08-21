import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveStorageService {
  static const String passesBoxName = 'passes_box';
  static const String dashboardBoxName = 'dashboard_box';

  static const String passesKey = 'cached_passes';
  static const String passesLastSyncKey = 'passes_last_sync_timestamp';

  static const String dashboardKey = 'cached_dashboard';
  static const String dashboardLastSyncKey = 'dashboard_last_sync_timestamp';

  /// Expiration TTL en heures (72h)
  static const int ttlHours = 72;

  static bool _initialized = false;

  /// Initialisation de Hive au lancement de l'application
  static Future<void> init() async {
    if (_initialized) return;
    try {
      await Hive.initFlutter();
      await Hive.openBox(passesBoxName);
      await Hive.openBox(dashboardBoxName);
      _initialized = true;
      debugPrint('📦 [HiveStorageService] Initialisé avec succès.');
    } catch (e) {
      debugPrint('⚠️ [HiveStorageService] Erreur lors de l\'initialisation: $e');
    }
  }

  static Box _getPassesBox() {
    return Hive.box(passesBoxName);
  }

  static Box _getDashboardBox() {
    return Hive.box(dashboardBoxName);
  }

  // ==========================================
  // GESTION DU CACHE : MES PASS
  // ==========================================

  /// Sauvegarder la liste des Pass récupérés en ligne + Horodatage
  static Future<void> savePasses(List<Map<String, dynamic>> passes) async {
    try {
      final box = _getPassesBox();
      final jsonStr = jsonEncode(passes);
      final nowTimestamp = DateTime.now().millisecondsSinceEpoch;

      await box.put(passesKey, jsonStr);
      await box.put(passesLastSyncKey, nowTimestamp);
      debugPrint('📦 [HiveStorageService] ${passes.length} pass enregistrés dans le cache Hive.');
    } catch (e) {
      debugPrint('⚠️ [HiveStorageService savePasses error]: $e');
    }
  }

  /// Récupérer les Pass depuis le cache Hive
  static List<Map<String, dynamic>>? getPasses() {
    try {
      final box = _getPassesBox();
      final String? jsonStr = box.get(passesKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      debugPrint('⚠️ [HiveStorageService getPasses error]: $e');
    }
    return null;
  }

  /// Vérifier si le cache des Pass a dépassé les 72 heures
  static bool isPassesExpired() {
    try {
      final box = _getPassesBox();
      final int? lastSync = box.get(passesLastSyncKey);
      if (lastSync == null) return true;

      final now = DateTime.now().millisecondsSinceEpoch;
      final differenceInHours = (now - lastSync) / (1000 * 60 * 60);

      return differenceInHours >= ttlHours;
    } catch (e) {
      return true;
    }
  }

  /// Obtenir le nombre d'heures restantes avant expiration du cache Pass
  static int getPassesRemainingHours() {
    try {
      final box = _getPassesBox();
      final int? lastSync = box.get(passesLastSyncKey);
      if (lastSync == null) return 0;

      final now = DateTime.now().millisecondsSinceEpoch;
      final elapsedHours = ((now - lastSync) / (1000 * 60 * 60)).floor();
      final remaining = ttlHours - elapsedHours;
      return remaining > 0 ? remaining : 0;
    } catch (_) {
      return 0;
    }
  }

  /// Purger le cache des Pass
  static Future<void> clearPasses() async {
    try {
      final box = _getPassesBox();
      await box.delete(passesKey);
      await box.delete(passesLastSyncKey);
      debugPrint('🧹 [HiveStorageService] Cache des Pass purgé.');
    } catch (e) {
      debugPrint('⚠️ [HiveStorageService clearPasses error]: $e');
    }
  }

  // ==========================================
  // GESTION DU CACHE : DASHBOARD
  // ==========================================

  /// Sauvegarder les données du Tableau de Bord (solde, statut KYC, activités récentes)
  static Future<void> saveDashboard(Map<String, dynamic> data) async {
    try {
      final box = _getDashboardBox();
      final jsonStr = jsonEncode(data);
      final nowTimestamp = DateTime.now().millisecondsSinceEpoch;

      await box.put(dashboardKey, jsonStr);
      await box.put(dashboardLastSyncKey, nowTimestamp);
      debugPrint('📦 [HiveStorageService] Données Dashboard enregistrées dans le cache Hive.');
    } catch (e) {
      debugPrint('⚠️ [HiveStorageService saveDashboard error]: $e');
    }
  }

  /// Récupérer les données Dashboard depuis le cache Hive
  static Map<String, dynamic>? getDashboard() {
    try {
      final box = _getDashboardBox();
      final String? jsonStr = box.get(dashboardKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        return jsonDecode(jsonStr) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('⚠️ [HiveStorageService getDashboard error]: $e');
    }
    return null;
  }

  /// Vérifier si le cache du Dashboard a dépassé les 72 heures
  static bool isDashboardExpired() {
    try {
      final box = _getDashboardBox();
      final int? lastSync = box.get(dashboardLastSyncKey);
      if (lastSync == null) return true;

      final now = DateTime.now().millisecondsSinceEpoch;
      final differenceInHours = (now - lastSync) / (1000 * 60 * 60);

      return differenceInHours >= ttlHours;
    } catch (e) {
      return true;
    }
  }

  /// Purger le cache Dashboard
  static Future<void> clearDashboard() async {
    try {
      final box = _getDashboardBox();
      await box.delete(dashboardKey);
      await box.delete(dashboardLastSyncKey);
      debugPrint('🧹 [HiveStorageService] Cache Dashboard purgé.');
    } catch (e) {
      debugPrint('⚠️ [HiveStorageService clearDashboard error]: $e');
    }
  }

  /// Purger la totalité des caches Hive (déconnexion ou expiration générale)
  static Future<void> clearAll() async {
    await clearPasses();
    await clearDashboard();
  }
}
