import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'hive_storage_service.dart';

class IdentitySession {
  static String identityType = 'CNI';
  static String? rectoPath;
  static String? versoPath;
  static String? rectoBase64;
  static String? versoBase64;

  static void clear() {
    identityType = 'CNI';
    rectoPath = null;
    versoPath = null;
    rectoBase64 = null;
    versoBase64 = null;
  }
}

class PassengerService {
  static Future<String?> fileToBase64(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return null;
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        if (bytes.isNotEmpty) {
          final base64Str = base64Encode(bytes);
          return 'data:image/jpeg;base64,$base64Str';
        }
      }
    } catch (e) {
      debugPrint('💥 [PassengerService fileToBase64] Error for path $filePath: $e');
    }
    return null;
  }

  /// Soumission des pièces d'identité et du selfie au backend
  static Future<Map<String, dynamic>> submitIdentity({
    required String identityType,
    String? rectoPath,
    String? versoPath,
    String? selfiePath,
    String? rectoBase64,
    String? versoBase64,
    String? selfieBase64,
  }) async {
    final storage = await StorageService.getInstance();
    final phone = storage.getPhoneNumber() ?? storage.getPassengerData()?['phoneNumber'];

    if (phone == null || phone.isEmpty) {
      return {
        'success': false,
        'message': 'Aucun compte passager identifié. Veuillez vous connecter.',
      };
    }

    final String type = identityType.isNotEmpty ? identityType : IdentitySession.identityType;
    final String? rB64Input = (rectoBase64 != null && rectoBase64.isNotEmpty) ? rectoBase64 : IdentitySession.rectoBase64;
    final String? rPathInput = (rectoPath != null && rectoPath.isNotEmpty) ? rectoPath : IdentitySession.rectoPath;

    final String? vB64Input = (versoBase64 != null && versoBase64.isNotEmpty) ? versoBase64 : IdentitySession.versoBase64;
    final String? vPathInput = (versoPath != null && versoPath.isNotEmpty) ? versoPath : IdentitySession.versoPath;

    final String? finalRectoB64 = (rB64Input != null && rB64Input.isNotEmpty)
        ? rB64Input
        : await fileToBase64(rPathInput);

    final String? finalVersoB64 = (vB64Input != null && vB64Input.isNotEmpty)
        ? vB64Input
        : await fileToBase64(vPathInput);

    final String? finalSelfieB64 = (selfieBase64 != null && selfieBase64.isNotEmpty)
        ? selfieBase64
        : await fileToBase64(selfiePath);

    debugPrint('📸 [submitIdentity] phone: $phone, type: $type');
    debugPrint('📸 [submitIdentity] recto B64 len: ${finalRectoB64?.length ?? 0}');
    debugPrint('📸 [submitIdentity] verso B64 len: ${finalVersoB64?.length ?? 0}');
    debugPrint('📸 [submitIdentity] selfie B64 len: ${finalSelfieB64?.length ?? 0}');

    if (finalRectoB64 == null || finalRectoB64.isEmpty) {
      return {
        'success': false,
        'message': 'Photo de la pièce d\'identité (recto) manquante. Veuillez reprendre la photo.',
      };
    }

    try {
      final response = await ApiService.post('/api/private/passenger/identity', {
        'phone': phone,
        'identityType': type,
        'rectoImage': finalRectoB64,
        'versoImage': finalVersoB64,
        'selfieImage': finalSelfieB64,
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        IdentitySession.clear();
        final passenger = data['passenger'];
        if (passenger != null && passenger is Map<String, dynamic>) {
          await storage.savePassengerData(passenger);
        }
        return {
          'success': true,
          'message': data['message'] ?? 'Documents transmis avec succès',
          'passenger': passenger,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de la transmission des documents',
        };
      }
    } catch (e) {
      debugPrint('💥 [PassengerService submitIdentity Exception] Error: $e');
      return {
        'success': false,
        'message': 'Connexion Internet requise. Veuillez vérifier votre réseau puis réessayer.',
      };
    }
  }

  /// Récupérer l'historique des notifications du passager
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final storage = await StorageService.getInstance();
    final phone = storage.getPhoneNumber() ?? storage.getPassengerData()?['phoneNumber'];

    if (phone == null || phone.isEmpty) {
      return [];
    }

    try {
      final response = await ApiService.post('/api/private/passenger/notifications', {
        'phone': phone,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['notifications'];
        if (list is List) {
          return list.map((item) => Map<String, dynamic>.from(item)).toList();
        }
      }
    } catch (e) {
      debugPrint('💥 [PassengerService getNotifications Exception] Error: $e');
    }
    return [];
  }

  /// Marquer les notifications comme lues
  static Future<void> markNotificationsRead() async {
    final storage = await StorageService.getInstance();
    final phone = storage.getPhoneNumber() ?? storage.getPassengerData()?['phoneNumber'];

    if (phone == null || phone.isEmpty) return;

    try {
      await ApiService.post('/api/private/passenger/notifications/mark-read', {
        'phone': phone,
      });
    } catch (e) {
      debugPrint('💥 [PassengerService markNotificationsRead Exception] Error: $e');
    }
  }

  /// Soumettre une évaluation / note pour l'application Pass Voyage
  static Future<Map<String, dynamic>> submitRating({
    required int rating,
    String? comment,
  }) async {
    final storage = await StorageService.getInstance();
    final phone = storage.getPhoneNumber() ?? storage.getPassengerData()?['phoneNumber'];

    try {
      final response = await ApiService.post('/api/private/passenger/rating', {
        'rating': rating,
        'comment': comment,
        'phone': phone,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Merci pour votre évaluation !',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de l\'envoi de la note',
        };
      }
    } catch (e) {
      debugPrint('💥 [PassengerService submitRating Exception] Error: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur',
      };
    }
  }

  /// Récupérer les données du tableau de bord (solde et activités récentes)
  static Future<Map<String, dynamic>> getDashboardData() async {
    final storage = await StorageService.getInstance();
    final phone = storage.getPhoneNumber() ?? storage.getPassengerData()?['phoneNumber'];

    if (phone == null || phone.isEmpty) {
      return {'success': false, 'isOffline': false};
    }

    try {
      var response = await ApiService.post('/api/private/passenger/dashboard', {
        'phone': phone,
      });

      if (response.statusCode != 200) {
        debugPrint('⚠️ [PassengerService] Tente /api/public/passenger/dashboard...');
        response = await ApiService.post('/api/public/passenger/dashboard', {
          'phone': phone,
        });
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        try {
          if (data['passenger'] != null && data['passenger'] is Map<String, dynamic>) {
            await storage.savePassengerData(Map<String, dynamic>.from(data['passenger']));
          } else {
            final Map<String, dynamic> localData = storage.getPassengerData() ?? {};
            if (data['identityStatus'] != null) {
              localData['identityStatus'] = data['identityStatus'];
              localData['identity_status'] = data['identityStatus'];
            }
            if (data['isIdentified'] != null) {
              localData['isIdentified'] = data['isIdentified'];
              localData['is_identified'] = data['isIdentified'];
            }
            if (data['isBlacklisted'] != null) {
              localData['isBlacklisted'] = data['isBlacklisted'];
              localData['is_blacklisted'] = data['isBlacklisted'];
            }
            if (data['isBlocked'] != null) {
              localData['isBlocked'] = data['isBlocked'];
              localData['is_blocked'] = data['isBlocked'];
            }
            await storage.savePassengerData(localData);
          }
        } catch (e) {
          debugPrint('💥 Error syncing passenger storage: $e');
        }

        final resultData = {
          'success': true,
          'availableCredit': data['availableCredit'] ?? 0,
          'formattedCredit': data['formattedCredit'] ?? '0',
          'identityStatus': data['identityStatus'],
          'isIdentified': data['isIdentified'],
          'recentActivities': data['recentActivities'] ?? [],
          'isOffline': false,
          'isExpired': false,
        };

        // Sauvegarde dans la Box Hive + horodatage 72h
        await HiveStorageService.saveDashboard(resultData);

        return resultData;
      }
    } catch (e) {
      debugPrint('💥 [PassengerService getDashboardData Exception] Offline fallback check: $e');
    }

    // Mode Hors-Ligne (Offline Fallback depuis Hive)
    if (HiveStorageService.isDashboardExpired()) {
      debugPrint('⚠️ [PassengerService getDashboardData] Cache Hive expiré (>72h). Purge...');
      await HiveStorageService.clearDashboard();
      return {'success': false, 'isOffline': true, 'isExpired': true};
    }

    final cached = HiveStorageService.getDashboard();
    if (cached != null) {
      debugPrint('📦 [PassengerService getDashboardData] Restitution des données depuis le cache Hive.');
      return {
        ...cached,
        'success': true,
        'isOffline': true,
        'isExpired': false,
      };
    }

    return {'success': false, 'isOffline': true, 'isExpired': false};
  }

  /// Vérifier l'état de la demande de crédit en attente et du KYC passager
  static Future<Map<String, dynamic>> getPendingCreditRequest() async {
    final storage = await StorageService.getInstance();
    final phone = storage.getPhoneNumber() ?? storage.getPassengerData()?['phoneNumber'];

    if (phone == null || phone.isEmpty) {
      return {'hasPendingRequest': false, 'passengerValid': false, 'success': false};
    }

    try {
      final response = await ApiService.post('/api/private/passenger/credit/pending', {
        'phone': phone,
      }, isPrivate: true);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final Map<String, dynamic> result = Map<String, dynamic>.from(data);
        result['success'] = true;

        // Mise à jour immédiate du cache local pour la cohérence temps réel avec l'administration
        try {
          final Map<String, dynamic> localData = storage.getPassengerData() ?? {};
          if (result['isBlocked'] != null || result['isBlacklisted'] != null) {
            final bool isBlockedLive = (result['isBlocked'] == true) || (result['isBlacklisted'] == true);
            localData['isBlacklisted'] = isBlockedLive;
            localData['is_blacklisted'] = isBlockedLive;
            localData['isBlocked'] = isBlockedLive;
            localData['is_blocked'] = isBlockedLive;
            await storage.savePassengerData(localData);
          }
        } catch (e) {
          debugPrint('💥 Sync local storage isBlocked error: $e');
        }

        return result;
      }
    } catch (e) {
      debugPrint('💥 [PassengerService getPendingCreditRequest Exception] Error: $e');
      return {'hasPendingRequest': false, 'passengerValid': false, 'success': false, 'isOffline': true};
    }
    return {'hasPendingRequest': false, 'passengerValid': false, 'success': false};
  }

  /// Soumettre une nouvelle demande de crédit voyage
  static Future<Map<String, dynamic>> submitCreditRequest({
    required String company,
    required String departureCity,
    required String arrivalCity,
    required String travelDate,
    String? returnDate,
    bool isRoundTrip = false,
    required int numberOfTickets,
    required int unitPrice,
    required int amountRequested,
    required int serviceFee,
    required int totalAmount,
    String? paymentMethod,
  }) async {
    final storage = await StorageService.getInstance();
    final phone = storage.getPhoneNumber() ?? storage.getPassengerData()?['phoneNumber'];

    if (phone == null || phone.isEmpty) {
      return {
        'success': false,
        'message': 'Aucun compte passager identifié.',
      };
    }

    try {
      final response = await ApiService.post('/api/private/passenger/credit/submit', {
        'phone': phone,
        'departureCompany': company,
        'departureCity': departureCity,
        'arrivalCity': arrivalCity,
        'travelDate': travelDate,
        'returnDate': returnDate,
        'isRoundTrip': isRoundTrip,
        'typeVoyage': isRoundTrip ? 'ALLER_RETOUR' : 'ALLER_SIMPLE',
        'numberOfTickets': numberOfTickets,
        'unitPrice': unitPrice,
        'amountRequested': amountRequested,
        'serviceFee': serviceFee,
        'totalAmount': totalAmount,
        'paymentMethod': paymentMethod ?? 'Wave',
        'serviceFeePaymentMethod': paymentMethod ?? 'Wave',
      }, isPrivate: true);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Demande soumise avec succès.',
          'creditRequest': data['creditRequest'],
        };
      } else {
        return {
          'success': false,
          'code': data['code'],
          'message': data['message'] ?? 'Erreur lors de la soumission de la demande.',
        };
      }
    } catch (e) {
      debugPrint('💥 [PassengerService submitCreditRequest Exception] Error: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur.',
      };
    }
  }

  /// Récupérer les partenaires, villes, trajets et la grille tarifaire du backend
  static Future<Map<String, dynamic>> getDemandeCreditConfig() async {
    try {
      final response = await ApiService.get('/api/private/passenger/referentiel/config');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final payload = data['data'] ?? data;
        return {
          'success': true,
          'companies': payload['companies'] ?? [],
          'cities': payload['cities'] ?? [],
          'routes': payload['routes'] ?? [],
          'tariffs': payload['tariffs'] ?? [],
        };
      }
    } catch (e) {
      debugPrint('💥 [PassengerService getDemandeCreditConfig Exception] Error: $e');
    }
    return {'success': false, 'companies': [], 'cities': [], 'routes': [], 'tariffs': []};
  }

  /// Récupérer les demandes de voyage / pass du passager avec leurs billets (Cache Hive & 72h Expiration)
  static Future<Map<String, dynamic>> getPassengerPassesData() async {
    final storage = await StorageService.getInstance();
    final phone = storage.getPhoneNumber() ?? storage.getPassengerData()?['phoneNumber'];

    try {
      final response = await ApiService.post('/api/private/passenger/passes', {
        'phone': phone,
      }, isPrivate: true);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['passes'] is List) {
          final List<dynamic> rawList = data['passes'];
          final List<Map<String, dynamic>> passesList =
              rawList.map((e) => Map<String, dynamic>.from(e)).toList();

          // Sauvegarde dans la box Hive des Pass
          await HiveStorageService.savePasses(passesList);

          return {
            'success': true,
            'passes': passesList,
            'isOffline': false,
            'isExpired': false,
            'remainingHours': 72,
          };
        }
      }
    } catch (e) {
      debugPrint('💥 [PassengerService getPassengerPassesData Exception] Offline fallback: $e');
    }

    // Fallback mode hors-ligne : chargement depuis le stockage local Hive
    if (HiveStorageService.isPassesExpired()) {
      debugPrint('⚠️ [PassengerService getPassengerPassesData] Cache Hive expiré (>72h). Purge...');
      await HiveStorageService.clearPasses();
      return {
        'success': false,
        'passes': <Map<String, dynamic>>[],
        'isOffline': true,
        'isExpired': true,
        'remainingHours': 0,
      };
    }

    final cachedPasses = HiveStorageService.getPasses();
    if (cachedPasses != null) {
      final remaining = HiveStorageService.getPassesRemainingHours();
      debugPrint('📦 [PassengerService getPassengerPassesData] ${cachedPasses.length} pass chargés depuis Hive ($remaining h restants).');
      return {
        'success': true,
        'passes': cachedPasses,
        'isOffline': true,
        'isExpired': false,
        'remainingHours': remaining,
      };
    }

    return {
      'success': false,
      'passes': <Map<String, dynamic>>[],
      'isOffline': true,
      'isExpired': false,
      'remainingHours': 0,
    };
  }

  /// Récupérer les pass du passager (Liste simple pour rétrocompatibilité)
  static Future<List<Map<String, dynamic>>> getPassengerPasses() async {
    final result = await getPassengerPassesData();
    final passes = result['passes'];
    if (passes is List<Map<String, dynamic>>) {
      return passes;
    }
    return [];
  }

  /// Soumettre un remboursement de crédit passager
  static Future<Map<String, dynamic>> submitReimbursement({
    required int amount,
    required String paymentMethod,
    String? creditUuid,
  }) async {
    final storage = await StorageService.getInstance();
    final phone = storage.getPhoneNumber() ?? storage.getPassengerData()?['phoneNumber'];

    try {
      final response = await ApiService.post('/api/private/passenger/reimburse', {
        'phone': phone,
        'amount': amount,
        'paymentMethod': paymentMethod,
        if (creditUuid != null) 'creditUuid': creditUuid,
      }, isPrivate: true);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          // Mettre à jour les données passager en local (disponible / totalDebt)
          final Map<String, dynamic> localData = storage.getPassengerData() ?? {};
          if (data['availableCredit'] != null) {
            localData['availableCredit'] = data['availableCredit'];
            localData['available_credit'] = data['availableCredit'];
          }
          if (data['totalDebt'] != null) {
            localData['totalDebt'] = data['totalDebt'];
            localData['total_debt'] = data['totalDebt'];
          }
          await storage.savePassengerData(localData);

          // Invalider / rafraîchir le dashboard Hive
          final cachedDash = HiveStorageService.getDashboard();
          if (cachedDash != null) {
            cachedDash['availableCredit'] = data['availableCredit'] ?? cachedDash['availableCredit'];
            cachedDash['formattedCredit'] = data['formattedCredit'] ?? cachedDash['formattedCredit'];
            await HiveStorageService.saveDashboard(cachedDash);
          }

          return {
            'success': true,
            'message': data['message'] ?? 'Remboursement effectué avec succès !',
            'availableCredit': data['availableCredit'],
            'formattedCredit': data['formattedCredit'],
            'totalDebt': data['totalDebt'],
            'totalReimbursed': data['totalReimbursed'],
            'payment': data['payment'],
          };
        }
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors du remboursement.',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Une erreur est survenue (${response.statusCode}).',
        };
      }
    } catch (e) {
      debugPrint('💥 [PassengerService submitReimbursement Exception]: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion avec le serveur. Veuillez réessayer.',
      };
    }
  }

  /// Récupérer l'historique et les totaux des remboursements du passager
  static Future<Map<String, dynamic>> getPassengerReimbursements() async {
    final storage = await StorageService.getInstance();
    final phone = storage.getPhoneNumber() ?? storage.getPassengerData()?['phoneNumber'];

    try {
      final response = await ApiService.post('/api/private/passenger/reimbursements', {
        'phone': phone,
      }, isPrivate: true);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> rawList = data['reimbursements'] ?? [];
          final List<Map<String, dynamic>> reimbursements =
              rawList.map((e) => Map<String, dynamic>.from(e)).toList();

          return {
            'success': true,
            'totalReimbursed': data['totalReimbursed'] ?? 0,
            'formattedTotalReimbursed': data['formattedTotalReimbursed'] ?? '0',
            'totalDebt': data['totalDebt'] ?? 0,
            'formattedTotalDebt': data['formattedTotalDebt'] ?? '0',
            'availableCredit': data['availableCredit'] ?? 0,
            'formattedAvailableCredit': data['formattedAvailableCredit'] ?? '0',
            'reimbursements': reimbursements,
          };
        }
      }
    } catch (e) {
      debugPrint('💥 [PassengerService getPassengerReimbursements Exception]: $e');
    }

    return {
      'success': false,
      'totalReimbursed': 0,
      'formattedTotalReimbursed': '0',
      'totalDebt': 0,
      'formattedTotalDebt': '0',
      'availableCredit': 0,
      'formattedAvailableCredit': '0',
      'reimbursements': <Map<String, dynamic>>[],
    };
  }

  /// Synchroniser le répertoire de contacts du passager avec le serveur
  static Future<Map<String, dynamic>> syncAddressBookContacts(List<Map<String, String>> contacts) async {
    final storage = await StorageService.getInstance();
    final phone = storage.getPhoneNumber() ?? storage.getPassengerData()?['phoneNumber'];

    if (phone == null || phone.isEmpty || contacts.isEmpty) {
      return {'success': false, 'message': 'Informations insuffisantes pour la synchronisation.'};
    }

    try {
      final response = await ApiService.post('/api/private/passenger/contacts/sync', {
        'phone': phone,
        'contacts': contacts,
      }, isPrivate: true);

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'message': data['message'] ?? '',
        'syncedCount': data['syncedCount'] ?? 0,
      };
    } catch (e) {
      debugPrint('💥 [PassengerService syncAddressBookContacts Exception] Error: $e');
      return {'success': false, 'message': 'Erreur lors de la synchronisation des contacts.'};
    }
  }
}
