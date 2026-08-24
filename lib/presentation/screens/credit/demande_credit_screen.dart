import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../config/routes.dart';
import '../../../core/services/passenger_service.dart';
import '../../../core/services/storage_service.dart';
import 'package:url_launcher/url_launcher.dart';

class DemandeCreditScreen extends StatefulWidget {
  const DemandeCreditScreen({super.key});

  @override
  State<DemandeCreditScreen> createState() => _DemandeCreditScreenState();
}

class _DemandeCreditScreenState extends State<DemandeCreditScreen> {
  String? _departureCity;
  String? _arrivalCity;
  String? _selectedCompany;
  DateTime? _selectedDate;
  DateTime? _returnDate;
  int _passengerCount = 1;
  bool _isRoundTrip = false;

  bool _isLoadingCheck = true;
  bool _isSubmitting = false;
  bool _isOffline = false;
  bool _passengerValid = true;
  bool _isBlocked = false;
  String? _identityStatus;
  bool _hasPendingRequest = false;
  Map<String, dynamic>? _pendingRequestData;

  List<String> _partners = [];
  List<String> _cities = [];
  List<dynamic> _backendTariffs = [];
  List<dynamic> _backendRoutes = [];

  final TextEditingController _departureCityController =
      TextEditingController();
  final TextEditingController _arrivalCityController = TextEditingController();

  @override
  void dispose() {
    _departureCityController.dispose();
    _arrivalCityController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (_partners.isNotEmpty) {
      _selectedCompany = _partners.first;
    }
    _checkPassengerAndPendingStatus();
  }

  Future<void> _checkPassengerAndPendingStatus() async {
    setState(() {
      _isLoadingCheck = true;
      _isOffline = false;
    });

    final storage = await StorageService.getInstance();
    final passengerData = storage.getPassengerData();

    final data = await PassengerService.getPendingCreditRequest();
    final config = await PassengerService.getDemandeCreditConfig();

    if (mounted) {
      setState(() {
        _isLoadingCheck = false;
        if (data['isOffline'] == true) {
          _isOffline = true;
        } else {
          _isOffline = false;
          _identityStatus = data['identityStatus'] ??
              passengerData?['identityStatus'] ??
              passengerData?['identity_status'] ??
              'NOT_SUBMITTED';
          final String statusUpper =
              (_identityStatus ?? '').toString().toUpperCase();
          final bool isVerifiedKyc = statusUpper == 'VERIFIED' ||
              statusUpper == 'VALIDATED' ||
              statusUpper == 'APPROVED';
          if (data['isBlocked'] != null || data['isBlacklisted'] != null) {
            _isBlocked = (data['isBlocked'] == true) || (data['isBlacklisted'] == true);
          } else {
            _isBlocked = passengerData?['isBlacklisted'] == true ||
                passengerData?['is_blacklisted'] == true ||
                passengerData?['isBlocked'] == true ||
                passengerData?['is_blocked'] == true;
          }
          _passengerValid = ((data['passengerValid'] == true) ||
              isVerifiedKyc ||
              (passengerData?['isIdentified'] == true) ||
              (passengerData?['is_identified'] == true)) && !_isBlocked;
          _hasPendingRequest = data['hasPendingRequest'] ?? false;
          _pendingRequestData = data['pendingRequest'];

          // Dynamisation des données depuis le backend
          if (config['success'] == true) {
            final List<dynamic> comps = config['companies'] ?? [];
            if (comps.isNotEmpty) {
              final loadedNames = comps
                  .map<String>((c) => (c['name'] ?? c['nom'] ?? '').toString())
                  .where((n) => n.isNotEmpty)
                  .toList();
              if (loadedNames.isNotEmpty) {
                _partners = loadedNames;
              }
            }

            final List<dynamic> loadedCities = config['cities'] ?? [];
            if (loadedCities.isNotEmpty) {
              final cityStrings = loadedCities
                  .map<String>((c) => c.toString())
                  .where((c) => c.isNotEmpty)
                  .toList();
              if (cityStrings.isNotEmpty) {
                _cities = cityStrings;
              }
            }

            _backendTariffs = config['tariffs'] ?? [];
            _backendRoutes = config['routes'] ?? [];
          }

          if (_partners.isNotEmpty &&
              (_selectedCompany == null ||
                  !_partners.contains(_selectedCompany))) {
            _selectedCompany = _partners.first;
          }

          _updateCitySelectionsForCurrentCompany(resetToCompanyDefault: true);
        }
      });
    }
  }

  int _getBasePrice(String from, String to) {
    final fromNorm = from.trim().toLowerCase();
    final toNorm = to.trim().toLowerCase();
    final compNorm = (_selectedCompany ?? '').trim().toLowerCase();

    // 1. Tarif spécifique pour la compagnie sélectionnée et le trajet
    for (final t in _backendTariffs) {
      final tDep = (t['villeDepart'] ?? t['departureCity'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      final tArr = (t['villeArrivee'] ?? t['arrivalCity'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      final tComp = (t['compagnie'] ?? t['companyName'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      final priceVal =
          int.tryParse(t['price']?.toString() ?? t['prix']?.toString() ?? '') ??
              0;

      if (priceVal > 0 &&
          ((tDep == fromNorm && tArr == toNorm) ||
              (tDep == toNorm && tArr == fromNorm))) {
        if (compNorm.isNotEmpty && tComp == compNorm) {
          return priceVal;
        }
      }
    }

    // 2. Tarif général pour le trajet
    for (final t in _backendTariffs) {
      final tDep = (t['villeDepart'] ?? t['departureCity'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      final tArr = (t['villeArrivee'] ?? t['arrivalCity'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      final tComp = (t['compagnie'] ?? t['companyName'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      final priceVal =
          int.tryParse(t['price']?.toString() ?? t['prix']?.toString() ?? '') ??
              0;

      if (priceVal > 0 &&
          ((tDep == fromNorm && tArr == toNorm) ||
              (tDep == toNorm && tArr == fromNorm))) {
        if (tComp == 'toutes' || tComp == 'général' || tComp.isEmpty) {
          return priceVal;
        }
      }
    }

    return 0;
  }

  int? get _estimatedPrice {
    if (_selectedCompany == null ||
        _departureCity == null ||
        _arrivalCity == null) return null;
    int basePrice = _getBasePrice(_departureCity!, _arrivalCity!);
    if (basePrice <= 0) return null;
    return basePrice * _passengerCount * (_isRoundTrip ? 2 : 1);
  }

  int get _serviceFee {
    return 600 * _passengerCount * (_isRoundTrip ? 2 : 1);
  }

  String _formatCityName(String raw) {
    if (raw.isEmpty) return '';
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.split(' ').map((word) {
      if (word.isEmpty) return '';
      if (word.contains('-')) {
        return word.split('-').map((part) {
          if (part.isEmpty) return '';
          return part[0].toUpperCase() + part.substring(1).toLowerCase();
        }).join('-');
      }
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  List<String> get _availableDepartureCities {
    if (_selectedCompany == null || _selectedCompany!.isEmpty) {
      return [];
    }

    final compNorm = _selectedCompany!.trim().toLowerCase();
    final Map<String, String> cityMap = {};

    for (final t in _backendTariffs) {
      final tComp = (t['compagnie'] ?? t['companyName'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      final dep =
          (t['villeDepart'] ?? t['departureCity'] ?? '').toString().trim();
      final arr =
          (t['villeArrivee'] ?? t['arrivalCity'] ?? '').toString().trim();

      if (tComp == compNorm || tComp == 'toutes' || tComp == 'général') {
        if (dep.isNotEmpty && dep != '-') {
          final formatted = _formatCityName(dep);
          cityMap[formatted.toLowerCase()] = formatted;
        }
        if (arr.isNotEmpty && arr != '-') {
          final formatted = _formatCityName(arr);
          cityMap[formatted.toLowerCase()] = formatted;
        }
      }
    }

    if (cityMap.isNotEmpty) {
      final list = cityMap.values.toList()..sort();
      return list;
    }

    return [];
  }

  List<String> get _availableArrivalCities {
    if (_departureCity == null ||
        _departureCity!.isEmpty ||
        _selectedCompany == null ||
        _selectedCompany!.isEmpty) {
      return [];
    }

    final depNorm = _departureCity!.trim().toLowerCase();
    final compNorm = _selectedCompany!.trim().toLowerCase();
    final Map<String, String> cityMap = {};

    for (final t in _backendTariffs) {
      final tDep = (t['villeDepart'] ?? t['departureCity'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      final tArr =
          (t['villeArrivee'] ?? t['arrivalCity'] ?? '').toString().trim();
      final tComp = (t['compagnie'] ?? t['companyName'] ?? '')
          .toString()
          .trim()
          .toLowerCase();

      if (tComp == compNorm || tComp == 'toutes' || tComp == 'général') {
        if (tDep == depNorm && tArr.isNotEmpty && tArr != '-') {
          final formatted = _formatCityName(tArr);
          if (formatted.toLowerCase() != depNorm) {
            cityMap[formatted.toLowerCase()] = formatted;
          }
        } else if (tArr.toLowerCase() == depNorm &&
            tDep.isNotEmpty &&
            tDep != '-') {
          final formatted = _formatCityName(tDep);
          if (formatted.toLowerCase() != depNorm) {
            cityMap[formatted.toLowerCase()] = formatted;
          }
        }
      }
    }

    if (cityMap.isNotEmpty) {
      final list = cityMap.values.toList()..sort();
      return list;
    }

    return [];
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      locale: const Locale('fr', 'FR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        if (_returnDate != null && _returnDate!.isBefore(_selectedDate!)) {
          _returnDate = null;
        }
      });
    }
  }

  Future<void> _selectReturnDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: _selectedDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      locale: const Locale('fr', 'FR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _returnDate) {
      setState(() {
        _returnDate = picked;
      });
    }
  }

  Widget _buildModalRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? AppColors.textPrimary : Colors.grey.shade600,
              fontSize: isTotal ? 16.sp : 14.sp,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isTotal ? AppColors.primary : AppColors.textPrimary,
              fontSize: isTotal ? 18.sp : 14.sp,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmationModal(BuildContext context) {
    final int totalTickets = _passengerCount * (_isRoundTrip ? 2 : 1);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
            top: 24.h,
            left: 24.w,
            right: 24.w,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Confirmer la demande',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              _buildModalRow('Trajet', '$_departureCity - $_arrivalCity'),
              _buildModalRow('Compagnie', _selectedCompany!),
              if (!_isRoundTrip)
                _buildModalRow('Date', DateFormat('d MMM yyyy', 'fr_FR').format(_selectedDate!))
              else ...[
                _buildModalRow('Date Départ', DateFormat('d MMM yyyy', 'fr_FR').format(_selectedDate!)),
                _buildModalRow('Date Retour', _returnDate != null ? DateFormat('d MMM yyyy', 'fr_FR').format(_returnDate!) : 'Non renseignée'),
              ],
              _buildModalRow('Passagers', '$totalTickets Billet${totalTickets > 1 ? 's' : ''}'),
              SizedBox(height: 16.h),
              Divider(color: Colors.grey.shade200),
              SizedBox(height: 16.h),
              _buildModalRow('Crédit Transport', '${NumberFormat('#,###', 'fr_FR').format(_estimatedPrice)} XOF'),
              _buildModalRow('Frais de service', '${NumberFormat('#,###', 'fr_FR').format(_serviceFee)} XOF'),
              SizedBox(height: 8.h),
              _buildModalRow(
                'Total',
                '${NumberFormat('#,###', 'fr_FR').format(_estimatedPrice! + _serviceFee)} XOF',
                isTotal: true,
              ),
              SizedBox(height: 32.h),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Fermer le récapitulatif
                    _showPaymentModalForServiceFee(context); // Ouvrir le paiement des frais
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                  ),
                  child: Text(
                    'CONTINUER',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
            ],
          ),
        );
      },
    );
  }

  void _showPaymentModalForServiceFee(BuildContext context) {
    final int totalTickets = _passengerCount * (_isRoundTrip ? 2 : 1);
    String selectedPaymentMethod = 'Wave';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
              top: 20.h,
              left: 20.w,
              right: 20.w,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Paiement des Frais de Service',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Veuillez régler les frais de service de ${NumberFormat('#,###', 'fr_FR').format(_serviceFee)} XOF (${600} XOF × $totalTickets billet${totalTickets > 1 ? 's' : ''}) au comptant pour finaliser la soumission :',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  _buildServiceFeePaymentOption('Wave', 'Paiement instantané', Icons.waves, Colors.blue, selectedPaymentMethod, (val) => setModalState(() => selectedPaymentMethod = val)),
                  SizedBox(height: 8.h),
                  _buildServiceFeePaymentOption('Orange Money', 'Mobile Money', Icons.phone_android, Colors.orange, selectedPaymentMethod, (val) => setModalState(() => selectedPaymentMethod = val)),
                  SizedBox(height: 8.h),
                  _buildServiceFeePaymentOption('MTN Mobile Money', 'Mobile Money', Icons.phone_android, Colors.amber[800]!, selectedPaymentMethod, (val) => setModalState(() => selectedPaymentMethod = val)),
                  SizedBox(height: 8.h),
                  _buildServiceFeePaymentOption('Moov Money', 'Mobile Money', Icons.phone_android, Colors.blue[800]!, selectedPaymentMethod, (val) => setModalState(() => selectedPaymentMethod = val)),
                  SizedBox(height: 8.h),
                  _buildServiceFeePaymentOption('Carte Bancaire', 'Paiement Carte', Icons.credit_card, AppColors.primary, selectedPaymentMethod, (val) => setModalState(() => selectedPaymentMethod = val)),

                  SizedBox(height: 24.h),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () async {
                              setModalState(() => _isSubmitting = true);

                              final res = await PassengerService.submitCreditRequest(
                                company: _selectedCompany!,
                                departureCity: _departureCity!,
                                arrivalCity: _arrivalCity!,
                                travelDate: DateFormat('yyyy-MM-dd').format(_selectedDate!),
                                returnDate: _returnDate != null ? DateFormat('yyyy-MM-dd').format(_returnDate!) : null,
                                isRoundTrip: _isRoundTrip,
                                numberOfTickets: totalTickets,
                                unitPrice: _getBasePrice(_departureCity!, _arrivalCity!),
                                amountRequested: _estimatedPrice!,
                                serviceFee: _serviceFee,
                                totalAmount: _estimatedPrice!,
                                paymentMethod: selectedPaymentMethod,
                              );

                              if (context.mounted) {
                                Navigator.pop(context); // Fermer la modale
                              }

                              if (res['success'] == true) {
                                if (mounted) {
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    AppRoutes.dashboard,
                                    (route) => false,
                                  );
                                }
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(res['message'] ?? 'Erreur lors de la soumission de la demande.'),
                                      backgroundColor: Colors.black87,
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                      ),
                      child: _isSubmitting
                          ? SizedBox(
                              height: 20.h,
                              width: 20.h,
                              child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              'PAYER ${NumberFormat('#,###', 'fr_FR').format(_serviceFee)} XOF & SOUMETTRE',
                              style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8),
                            ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _buildServiceFeePaymentOption(
    String title,
    String subtitle,
    IconData icon,
    Color badgeColor,
    String groupValue,
    ValueChanged<String> onChanged,
  ) {
    final bool isSelected = title == groupValue;
    return InkWell(
      onTap: () => onChanged(title),
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.06) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[200]!,
            width: isSelected ? 2.w : 1.w,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: title,
              groupValue: groupValue,
              onChanged: (val) => onChanged(val!),
              activeColor: AppColors.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            SizedBox(width: 8.w),
            Icon(icon, color: badgeColor, size: 20.w),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp, color: AppColors.textPrimary)),
                  Text(subtitle, style: TextStyle(fontSize: 10.sp, color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _proceedToSummary() {
    if (_isBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Votre compte est actuellement suspendu ou bloqué. Vous ne pouvez pas effectuer de demande de crédit voyage."),
          backgroundColor: Colors.black87,
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    if (!_passengerValid) {
      final String statusUpper =
          (_identityStatus ?? 'NOT_SUBMITTED').toString().toUpperCase();
      final bool isPendingKyc =
          statusUpper == 'PENDING' || statusUpper == 'SUBMITTED';
      final bool isRejectedKyc = statusUpper == 'REJECTED';

      String msg =
          "Votre compte n'est pas encore validé. Veuillez soumettre vos pièces d'identité pour bénéficier d'un crédit voyage.";
      Color bgColor = AppColors.primary;
      SnackBarAction? action = SnackBarAction(
        label: 'SOUMETTRE',
        textColor: Colors.white,
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.identitySelection);
        },
      );

      if (isPendingKyc) {
        msg =
            "Vos pièces d'identité ont été soumises avec succès et sont en cours d'examen par l'administrateur. Vous pourrez faire une demande dès la validation.";
        bgColor = Colors.blue.shade900;
        action = null;
      } else if (isRejectedKyc) {
        msg =
            "Votre dossier d'identification a été rejeté par l'administrateur. Veuillez soumettre à nouveau vos pièces d'identité.";
        bgColor = Colors.black87;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: bgColor,
          action: action,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    if (_selectedCompany == null ||
        _departureCity == null ||
        _arrivalCity == null ||
        _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Veuillez remplir tous les champs obligatoires (compagnie, villes, date de départ).'),
          backgroundColor: Colors.black87,
        ),
      );
      return;
    }

    if (_departureCity == _arrivalCity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'La ville de départ et d\'arrivée ne peuvent pas être identiques.'),
          backgroundColor: Colors.black87,
        ),
      );
      return;
    }

    _showConfirmationModal(context);
  }

  void _updateCitySelectionsForCurrentCompany({bool resetToCompanyDefault = false}) {
    final availableDeps = _availableDepartureCities;
    if (resetToCompanyDefault || _departureCity == null || !availableDeps.contains(_departureCity)) {
      if (availableDeps.isNotEmpty) {
        _departureCity = availableDeps.first;
      } else {
        _departureCity = null;
      }
    }
    _departureCityController.text = _departureCity ?? '';

    final availableArrs = _availableArrivalCities;
    if (resetToCompanyDefault || _arrivalCity == null || !availableArrs.contains(_arrivalCity)) {
      if (availableArrs.isNotEmpty) {
        _arrivalCity = availableArrs.first;
      } else {
        _arrivalCity = null;
      }
    }
    _arrivalCityController.text = _arrivalCity ?? '';
  }

  Widget _buildPartnerCard(String name) {
    final bool isSelected = _selectedCompany == name;
    return GestureDetector(
      onTap: () {
        if (_selectedCompany != name) {
          setState(() {
            _selectedCompany = name;
            _updateCitySelectionsForCurrentCompany(resetToCompanyDefault: true);
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: EdgeInsets.only(right: 12.w, bottom: 4.h, top: 4.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.brandGradient : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
              color: isSelected ? Colors.transparent : Colors.grey[300]!),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_bus,
                color: isSelected ? Colors.white : AppColors.primary,
                size: 16.w),
            SizedBox(width: 8.w),
            Text(name,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontSize: 13.sp)),
          ],
        ),
      ),
    );
  }

  Future<void> _launchWhatsAppSupport() async {
    const phoneNumber = '2250700000000';
    const message = 'Bonjour, mon compte est actuellement suspendu sur l\'application Passe Voyage. Merci de m\'aider à le débloquer.';
    final Uri url = Uri.parse('https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}');
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir WhatsApp. Veuillez contacter le support.'),
            backgroundColor: Colors.black87,
          ),
        );
      }
    }
  }

  /// Bannière d'alerte en haut de l'écran si le compte n'est pas encore validé
  Widget _buildKycAlertBanner() {
    if (_isBlocked) {
      return Container(
        margin: EdgeInsets.only(bottom: 20.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.red.shade400, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.red.shade900.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.block_rounded, color: Colors.red.shade900, size: 28.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Compte Suspendu / Bloqué',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade900,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Votre compte est actuellement suspendu par l\'administration. Vous ne pouvez pas effectuer de demande de crédit voyage tant qu\'il n\'est pas débloqué.',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.red.shade800,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  InkWell(
                    onTap: _launchWhatsAppSupport,
                    borderRadius: BorderRadius.circular(8.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366),
                        borderRadius: BorderRadius.circular(8.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF25D366).withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 16.sp),
                          SizedBox(width: 6.w),
                          Text(
                            'Contacter le support WhatsApp',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final String statusUpper =
        (_identityStatus ?? 'NOT_SUBMITTED').toString().toUpperCase();

    final bool isVerifiedKyc = statusUpper == 'VERIFIED' ||
        statusUpper == 'VALIDATED' ||
        statusUpper == 'APPROVED';

    if (_passengerValid || isVerifiedKyc) return const SizedBox.shrink();
    final bool isPendingKyc =
        statusUpper == 'PENDING' || statusUpper == 'SUBMITTED';
    final bool isRejectedKyc = statusUpper == 'REJECTED';

    String title = 'Compte non validé';
    String message =
        "Votre compte n'est pas encore validé. Veuillez soumettre vos pièces d'identité pour bénéficier d'un crédit voyage.";
    String buttonText = "Soumettre mes pièces d'identité";
    IconData iconData = Icons.warning_amber_rounded;
    Color primaryColor = Colors.amber.shade900;
    Color bgColor = Colors.amber.shade50;
    Color borderColor = Colors.amber.shade400;

    if (isPendingKyc) {
      title = 'Identification en cours de vérification';
      message =
          "Vos pièces d'identité ont été soumises avec succès et sont en cours d'examen par l'administrateur. Vous pourrez faire une demande dès la validation de votre dossier.";
      buttonText = "Dossier en cours d'examen";
      iconData = Icons.hourglass_top_rounded;
      primaryColor = Colors.blue.shade900;
      bgColor = Colors.blue.shade50;
      borderColor = Colors.blue.shade300;
    } else if (isRejectedKyc) {
      title = 'Dossier d\'identité rejeté';
      message =
          "Votre dossier d'identification a été rejeté par l'administrateur. Veuillez soumettre à nouveau vos pièces d'identité.";
      buttonText = "Resoumettre mes pièces d'identité";
      iconData = Icons.cancel_outlined;
      primaryColor = Colors.red.shade900;
      bgColor = Colors.red.shade50;
      borderColor = Colors.red.shade300;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(iconData, color: primaryColor, size: 24.sp),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            message,
            style: TextStyle(
              fontSize: 13.sp,
              color: primaryColor,
              height: 1.4,
            ),
          ),
          SizedBox(height: 14.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isPendingKyc
                  ? null
                  : () {
                      Navigator.pushNamed(context, AppRoutes.identitySelection);
                    },
              icon: Icon(
                isPendingKyc ? Icons.hourglass_empty : Icons.badge_outlined,
                color: Colors.white,
                size: 18,
              ),
              label: Text(
                buttonText,
                style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isPendingKyc ? Colors.grey.shade400 : primaryColor,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Vue d'affichage de la demande de crédit en attente
  Widget _buildPendingRequestView() {
    final req = _pendingRequestData ?? {};
    final bool isRound = req['isRoundTrip'] == true || req['isRoundTrip'] == 1 || req['typeVoyage'] == 'ALLER_RETOUR' || req['returnDate'] != null || _isRoundTrip;
    final String? returnDateVal = req['returnDate'] ?? (_returnDate != null ? DateFormat('dd/MM/yyyy', 'fr_FR').format(_returnDate!) : null);
    final String from = req['departureCity'] ?? 'Ville départ';
    final String to = req['arrivalCity'] ?? 'Ville arrivée';
    final String company = req['companyName'] ?? 'Partenaire';
    final String travelDate = req['travelDate'] ?? 'Date non définie';
    final dynamic rawTickets = req['numberOfTickets'] ?? req['ticketCount'] ?? req['passengerCount'] ?? 1;
    final int ticketsCount = (rawTickets is int) ? rawTickets : int.tryParse(rawTickets.toString()) ?? 1;
    final int amount = req['amountRequested'] ?? req['totalAmount'] ?? req['amount'] ?? 0;
    final String createdAt = req['createdAt'] ?? '';

    final formattedAmount = NumberFormat('#,###', 'fr_FR').format(amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildKycAlertBanner(),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: Colors.grey.shade200, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Status Tag & Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(20.r),
                      border:
                          Border.all(color: Colors.amber.shade200, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 12.h,
                          width: 12.h,
                          child: CircularProgressIndicator(
                            color: Colors.amber.shade800,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'En attente de validation',
                          style: TextStyle(
                            color: Colors.amber.shade900,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (createdAt.isNotEmpty)
                    Text(
                      createdAt,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12.sp,
                      ),
                    ),
                ],
              ),

              SizedBox(height: 16.h),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Demande de Crédit Voyage',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: isRound ? Colors.blue.shade50 : Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: isRound ? Colors.blue.shade200 : Colors.indigo.shade200),
                    ),
                    child: Text(
                      isRound ? 'Aller-retour' : 'Aller simple',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: isRound ? Colors.blue.shade900 : Colors.indigo.shade900,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Text(
                "Votre dossier est actuellement en cours d\'examen par notre équipe. Dès validation par l'administration, vous recevrez une notification.",
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),

              SizedBox(height: 20.h),

              // Journey Card Details (Sober & Clean)
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DÉPART',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                from,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.directions_bus_rounded,
                            color: AppColors.primary,
                            size: 18.sp,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'ARRIVÉE',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                to,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 14.h),
                    Divider(color: Colors.grey.shade200, height: 1),
                    SizedBox(height: 14.h),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Compagnie',
                                style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.grey.shade500),
                              ),
                              SizedBox(height: 3.h),
                              Text(
                                company,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Billets',
                                style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.grey.shade500),
                              ),
                              SizedBox(height: 3.h),
                              Text(
                                '$ticketsCount ${ticketsCount > 1 ? "billets" : "billet"}',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isRound ? 'Date de départ' : 'Date du voyage',
                                style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.grey.shade500),
                              ),
                              SizedBox(height: 3.h),
                              Text(
                                travelDate,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isRound) ...[
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Date de retour',
                                  style: TextStyle(
                                      fontSize: 11.sp,
                                      color: Colors.grey.shade500),
                                ),
                                SizedBox(height: 3.h),
                                Text(
                                  returnDateVal ?? 'Non renseignée',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16.h),

              // Total Amount Row (Sober & Harmonious)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14.r),
                  border:
                      Border.all(color: AppColors.primary.withOpacity(0.12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Montant du Crédit',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      '$formattedAmount XOF',
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24.h),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
            },
            icon: Icon(Icons.home_outlined, color: Colors.white, size: 20.sp),
            label: Text(
              'RETOURNER AU TABLEAU DE BORD',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Vue problème de connexion Internet
  Widget _buildOfflineView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber.shade200, width: 2),
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 64.sp,
                color: Colors.amber.shade800,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Connexion Internet requise',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            Text(
              'L\'accès à la demande de crédit voyage nécessite une connexion Internet active. Veuillez vérifier votre connexion Wi-Fi ou vos données mobiles et réessayer.',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton.icon(
                onPressed: _checkPassengerAndPendingStatus,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                label: Text(
                  'RÉESSAYER',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.1,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Demande de Crédit Voyage'),
        backgroundColor: AppColors.background,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isLoadingCheck
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _isOffline
                ? _buildOfflineView()
                : SingleChildScrollView(
                    padding: EdgeInsets.all(24.0.w),
                    child: _hasPendingRequest
                        ? _buildPendingRequestView()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildKycAlertBanner(),

                              Text(
                                'Où souhaitez-vous aller ?',
                                style: TextStyle(
                                    fontSize: 24.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'Obtenez un crédit pour réserver vos billets de car.',
                                style: TextStyle(
                                    fontSize: 14.sp, color: Colors.grey),
                              ),
                              SizedBox(height: 24.h),

                              Text('Nos partenaires',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.sp)),
                              SizedBox(height: 12.h),
                              SizedBox(
                                height: 45.h,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  clipBehavior: Clip.none,
                                  itemCount: _partners.length,
                                  itemBuilder: (context, index) {
                                    return _buildPartnerCard(_partners[index]);
                                  },
                                ),
                              ),
                              SizedBox(height: 32.h),

                              // Type de trajet
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => setState(() {
                                        _isRoundTrip = false;
                                        _returnDate = null;
                                      }),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            vertical: 12.h),
                                        decoration: BoxDecoration(
                                          color: !_isRoundTrip
                                              ? AppColors.primary
                                              : Colors.grey[100],
                                          borderRadius: BorderRadius.horizontal(
                                              left: Radius.circular(12.r)),
                                          border: Border.all(
                                              color: !_isRoundTrip
                                                  ? AppColors.primary
                                                  : Colors.grey[300]!),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Aller simple',
                                            style: TextStyle(
                                              color: !_isRoundTrip
                                                  ? Colors.white
                                                  : Colors.grey[600],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () =>
                                          setState(() => _isRoundTrip = true),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            vertical: 12.h),
                                        decoration: BoxDecoration(
                                          color: _isRoundTrip
                                              ? AppColors.primary
                                              : Colors.grey[100],
                                          borderRadius: BorderRadius.horizontal(
                                              right: Radius.circular(12.r)),
                                          border: Border.all(
                                              color: _isRoundTrip
                                                  ? AppColors.primary
                                                  : Colors.grey[300]!),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Aller-retour',
                                            style: TextStyle(
                                              color: _isRoundTrip
                                                  ? Colors.white
                                                  : Colors.grey[600],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 24.h),

                              Text('Ville de départ',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 8.h),
                              LayoutBuilder(builder: (context, constraints) {
                                return DropdownMenu<String>(
                                  key: ValueKey(
                                      'dep_${_selectedCompany}_${_departureCity}_${_availableDepartureCities.join("_")}'),
                                  controller: _departureCityController,
                                  initialSelection: _availableDepartureCities
                                          .contains(_departureCity)
                                      ? _departureCity
                                      : null,
                                  width: constraints.maxWidth,
                                  enableFilter: true,
                                  requestFocusOnTap: true,
                                  leadingIcon: const Icon(
                                      Icons.location_on_outlined,
                                      color: AppColors.secondary),
                                  hintText: _availableDepartureCities.isEmpty
                                      ? 'Aucun trajet disponible pour cette compagnie'
                                      : 'Rechercher une ville de départ',
                                  inputDecorationTheme: InputDecorationTheme(
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.r)),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.r),
                                        borderSide: const BorderSide(
                                            color: AppColors.primary)),
                                    contentPadding:
                                        EdgeInsets.symmetric(horizontal: 16.w),
                                  ),
                                  dropdownMenuEntries:
                                      _availableDepartureCities.map((city) {
                                    return DropdownMenuEntry(
                                        value: city, label: city);
                                  }).toList(),
                                  onSelected: (val) => setState(() {
                                    _departureCity = val;
                                    _departureCityController.text = val ?? '';
                                    if (_arrivalCity != null &&
                                        !_availableArrivalCities
                                            .contains(_arrivalCity)) {
                                      _arrivalCity = null;
                                      _arrivalCityController.text = '';
                                    }
                                  }),
                                );
                              }),
                              SizedBox(height: 20.h),

                              Text('Ville d\'arrivée',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 8.h),
                              LayoutBuilder(builder: (context, constraints) {
                                return DropdownMenu<String>(
                                  key: ValueKey(
                                      'arr_${_selectedCompany}_${_departureCity}_${_arrivalCity}_${_availableArrivalCities.join("_")}'),
                                  controller: _arrivalCityController,
                                  initialSelection: _availableArrivalCities
                                          .contains(_arrivalCity)
                                      ? _arrivalCity
                                      : null,
                                  width: constraints.maxWidth,
                                  enableFilter: true,
                                  requestFocusOnTap: true,
                                  leadingIcon: const Icon(Icons.flag_outlined,
                                      color: AppColors.tertiary),
                                  hintText: _departureCity == null
                                      ? (_availableDepartureCities.isEmpty
                                          ? 'Aucun trajet disponible pour cette compagnie'
                                          : 'Veuillez d\'abord choisir la ville de départ')
                                      : (_availableArrivalCities.isEmpty
                                          ? 'Aucune ville d\'arrivée disponible'
                                          : 'Rechercher une ville d\'arrivée'),
                                  inputDecorationTheme: InputDecorationTheme(
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.r)),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.r),
                                        borderSide: const BorderSide(
                                            color: AppColors.primary)),
                                    contentPadding:
                                        EdgeInsets.symmetric(horizontal: 16.w),
                                  ),
                                  dropdownMenuEntries:
                                      _availableArrivalCities.map((city) {
                                    return DropdownMenuEntry(
                                        value: city, label: city);
                                  }).toList(),
                                  onSelected: (val) => setState(() {
                                    _arrivalCity = val;
                                    _arrivalCityController.text = val ?? '';
                                  }),
                                );
                              }),
                              SizedBox(height: 20.h),

                              Text('Date du voyage',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 8.h),
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => _selectDate(context),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16.w, vertical: 16.h),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.grey[400]!),
                                          borderRadius:
                                              BorderRadius.circular(12.r),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                                Icons.calendar_today_outlined,
                                                color: AppColors.primary),
                                            SizedBox(width: 12.w),
                                            Expanded(
                                              child: Text(
                                                _selectedDate == null
                                                    ? 'Départ'
                                                    : DateFormat('d MMM yyyy',
                                                            'fr_FR')
                                                        .format(_selectedDate!),
                                                style: TextStyle(
                                                  fontSize: 14.sp,
                                                  color: _selectedDate == null
                                                      ? Colors.grey[600]
                                                      : Colors.black87,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_isRoundTrip) ...[
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () => _selectReturnDate(context),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16.w, vertical: 16.h),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.grey[400]!),
                                            borderRadius:
                                                BorderRadius.circular(12.r),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                  Icons.calendar_today_outlined,
                                                  color: AppColors.primary),
                                              SizedBox(width: 12.w),
                                              Expanded(
                                                child: Text(
                                                  _returnDate == null
                                                      ? 'Retour (Optionnel)'
                                                      : DateFormat('d MMM yyyy',
                                                              'fr_FR')
                                                          .format(_returnDate!),
                                                  style: TextStyle(
                                                    fontSize: 14.sp,
                                                    color: _returnDate == null
                                                        ? Colors.grey[600]
                                                        : Colors.black87,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              SizedBox(height: 20.h),

                              Text('Passagers',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 8.h),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16.w, vertical: 8.h),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[400]!),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.person_outline,
                                            color: AppColors.primary),
                                        SizedBox(width: 12.w),
                                        Text(
                                            '${_passengerCount * (_isRoundTrip ? 2 : 1)} Billet${(_passengerCount * (_isRoundTrip ? 2 : 1)) > 1 ? 's' : ''}',
                                            style: TextStyle(fontSize: 16.sp)),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                              Icons.remove_circle_outline,
                                              color: Colors.grey),
                                          onPressed: _passengerCount > 1
                                              ? () => setState(
                                                  () => _passengerCount--)
                                              : null,
                                        ),
                                        Text('$_passengerCount',
                                            style: TextStyle(
                                                fontSize: 18.sp,
                                                fontWeight: FontWeight.bold)),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.add_circle_outline,
                                              color: AppColors.primary),
                                          onPressed: _passengerCount < 10
                                              ? () => setState(
                                                  () => _passengerCount++)
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              if (_availableDepartureCities.isEmpty) ...[
                                SizedBox(height: 24.h),
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(16.w),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(color: Colors.orange.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline, color: Colors.orange.shade800),
                                      SizedBox(width: 12.w),
                                      Expanded(
                                        child: Text(
                                          'Cette compagnie ne propose aucun trajet disponible pour le moment.',
                                          style: TextStyle(
                                            color: Colors.orange.shade900,
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else if (_estimatedPrice != null) ...[
                                SizedBox(height: 24.h),
                                Container(
                                  padding: EdgeInsets.all(20.w),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Colors.white, AppColors.surface],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(16.r),
                                    border: Border.all(
                                        color:
                                            AppColors.primary.withOpacity(0.1)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Crédit Transport',
                                              style: TextStyle(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontSize: 14.sp)),
                                          Text(
                                              '${NumberFormat('#,###', 'fr_FR').format(_estimatedPrice)} XOF',
                                              style: TextStyle(
                                                  color: AppColors.textPrimary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15.sp)),
                                        ],
                                      ),
                                      SizedBox(height: 12.h),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Frais de service',
                                              style: TextStyle(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontSize: 14.sp)),
                                          Text(
                                              '${NumberFormat('#,###', 'fr_FR').format(_serviceFee)} XOF',
                                              style: TextStyle(
                                                  color: AppColors.textPrimary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15.sp)),
                                        ],
                                      ),
                                      SizedBox(height: 16.h),
                                      Divider(
                                          color: AppColors.primary
                                              .withOpacity(0.1),
                                          height: 1),
                                      SizedBox(height: 16.h),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Montant Total',
                                              style: TextStyle(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 16.sp)),
                                          Text(
                                              '${NumberFormat('#,###', 'fr_FR').format(_estimatedPrice! + _serviceFee)} XOF',
                                              style: TextStyle(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 20.sp)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              SizedBox(height: 32.h),

                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: AppColors.brandGradient,
                                  borderRadius: BorderRadius.circular(16.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _proceedToSummary,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding:
                                        EdgeInsets.symmetric(vertical: 16.h),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16.r)),
                                  ),
                                  child: Text('CONFIRMER LA DEMANDE',
                                      style: TextStyle(
                                          fontSize: 15.sp,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.0)),
                                ),
                              ),
                              SizedBox(height: 24.h),
                            ],
                          ),
                  ),
      ),
    );
  }
}
