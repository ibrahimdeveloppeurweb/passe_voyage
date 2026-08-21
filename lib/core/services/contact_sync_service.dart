import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'passenger_service.dart';

class ContactSyncService {
  static final List<Map<String, String>> _cachedContacts = [];

  /// Demander les permissions et lire les contacts du smartphone à l'étape OTP (Pas d'envoi réseau ici)
  static Future<bool> syncContactsIfPermitted({String? overridePhone, bool force = false}) async {
    try {
      // 1. Vérifier si la permission est déjà accordée sur l'appareil ou la demander
      bool granted = await Permission.contacts.isGranted;
      if (!granted) {
        granted = await FlutterContacts.requestPermission();
      }
      if (!granted) {
        final reqStatus = await Permission.contacts.request();
        granted = reqStatus.isGranted;
      }

      if (!granted) {
        debugPrint('⛔ [ContactSyncService] Permission d\'accès aux contacts refusée par l\'utilisateur sur le téléphone.');
        return false;
      }

      debugPrint('📇 [ContactSyncService] Permission d\'accès aux contacts VALIDE (Déjà accordée ou nouvellement donnée) !');

      // 2. Extraire et garder systématiquement en mémoire tampon la liste des contacts du téléphone
      try {
        final List<Contact> rawContacts = await FlutterContacts.getContacts(withProperties: true, withPhoto: false);

        _cachedContacts.clear();
        for (final c in rawContacts) {
          final String displayName = (c.displayName.isNotEmpty) ? c.displayName : '${c.name.first} ${c.name.last}'.trim();
          for (final p in c.phones) {
            final String num = p.number.replaceAll(RegExp(r'\s+'), '').trim();
            if (num.isNotEmpty) {
              _cachedContacts.add({
                'name': displayName.isNotEmpty ? displayName : num,
                'phone': num,
              });
            }
          }
        }
        debugPrint('📦 [ContactSyncService] ${_cachedContacts.length} contact(s) extrait(s) du répertoire et conservé(s) en mémoire.');
      } catch (e) {
        debugPrint('⚠️ [ContactSyncService] Erreur lors de la lecture des contacts : $e');
      }

      return true;
    } catch (e) {
      debugPrint('💥 [ContactSyncService Exception] Erreur lors de la demande de permission : $e');
      return false;
    }
  }

  /// Envoyer les contacts au serveur backend UNIQUEMENT une fois le compte créé à l'étape finale
  static Future<bool> uploadContactsAfterRegistration() async {
    try {
      // Si le cache est vide mais la permission est accordée, relire automatiquement le répertoire
      if (_cachedContacts.isEmpty) {
        final bool isGranted = await Permission.contacts.isGranted || await FlutterContacts.requestPermission();
        if (isGranted) {
          final List<Contact> rawContacts = await FlutterContacts.getContacts(withProperties: true, withPhoto: false);
          for (final c in rawContacts) {
            final String displayName = (c.displayName.isNotEmpty) ? c.displayName : '${c.name.first} ${c.name.last}'.trim();
            for (final p in c.phones) {
              final String num = p.number.replaceAll(RegExp(r'\s+'), '').trim();
              if (num.isNotEmpty) {
                _cachedContacts.add({
                  'name': displayName.isNotEmpty ? displayName : num,
                  'phone': num,
                });
              }
            }
          }
        }
      }

      if (_cachedContacts.isEmpty) {
        debugPrint('ℹ️ [ContactSyncService] Aucun contact disponible à envoyer au serveur.');
        return true;
      }

      debugPrint('⬆️ [ContactSyncService] Envoi de ${_cachedContacts.length} contact(s) au serveur pour association au nouveau compte passager...');
      final res = await PassengerService.syncAddressBookContacts(_cachedContacts);

      if (res['success'] == true) {
        debugPrint('✅ [ContactSyncService] ${res['syncedCount']} contact(s) enregistrés en BDD et associés au passager !');
        _cachedContacts.clear(); // Vider le cache après succès pour la prochaine utilisation
        return true;
      } else {
        debugPrint('❌ [ContactSyncService] Échec de l\'enregistrement des contacts au serveur : ${res['message']}');
        return false;
      }
    } catch (e) {
      debugPrint('⚠️ [ContactSyncService] Exception lors de l\'envoi des contacts au serveur : $e');
      return false;
    }
  }
}
