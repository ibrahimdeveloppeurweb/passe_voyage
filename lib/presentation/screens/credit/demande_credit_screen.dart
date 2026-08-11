import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../config/routes.dart';

class DemandeCreditScreen extends StatefulWidget {
  const DemandeCreditScreen({super.key});

  @override
  State<DemandeCreditScreen> createState() => _DemandeCreditScreenState();
}

class _DemandeCreditScreenState extends State<DemandeCreditScreen> {
  String? _departureCity;
  String? _arrivalCity;
  String? _selectedCompany; // <-- Added
  DateTime? _selectedDate;
  DateTime? _returnDate;
  int _passengerCount = 1;
  bool _isRoundTrip = false;

  int _getBasePrice(String from, String to) {
    final route = [from, to]..sort();
    final key = route.join('-');
    
    // Matrice des prix simulée
    final Map<String, int> prices = {
      'Abidjan-Yamoussoukro': 4000,
      'Abidjan-Bouaké': 6000,
      'Abidjan-Korhogo': 10000,
      'Abidjan-San-Pédro': 7000,
      'Abidjan-Daloa': 6500,
      'Abidjan-Man': 8000,
      'Abidjan-Odienné': 12000,
      'Bouaké-Yamoussoukro': 2500,
      'Bouaké-Korhogo': 4000,
    };
    
    return prices[key] ?? 5000; // Prix par défaut si trajet non défini
  }

  int? get _estimatedPrice {
    if (_selectedCompany == null || _departureCity == null || _arrivalCity == null) return null;
    int basePrice = _getBasePrice(_departureCity!, _arrivalCity!);
    
    // Majoration fictive selon la compagnie (+1000 FCFA pour certaines)
    if (_selectedCompany == 'UTB' || _selectedCompany == 'CTE') {
      basePrice += 0;
    }
    
    return basePrice * _passengerCount * (_isRoundTrip ? 2 : 1);
  }

  int get _serviceFee {
    return 600 * _passengerCount * (_isRoundTrip ? 2 : 1);
  }

  final List<String> _cities = [
    'Abidjan',
    'Bouaké',
    'Yamoussoukro',
    'Korhogo',
    'San-Pédro',
    'Daloa',
    'Man',
    'Odienné',
  ];

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
          _returnDate = null; // Reset return date if it's before departure
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

  void _proceedToSummary() {
    if (_selectedCompany == null || _departureCity == null || _arrivalCity == null || _selectedDate == null || (_isRoundTrip && _returnDate == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs (compagnie, villes, dates).'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    if (_departureCity == _arrivalCity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La ville de départ et d\'arrivée ne peuvent pas être identiques.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    Navigator.pushNamed(context, AppRoutes.dashboard, arguments: {
      'company': _selectedCompany,
      'departure': _departureCity,
      'arrival': _arrivalCity,
      'date': _selectedDate,
      'returnDate': _returnDate,
      'isRoundTrip': _isRoundTrip,
      'passengers': _passengerCount,
      'pricePerTicket': 5000,
      'totalPrice': _estimatedPrice,
    });
  }

  Widget _buildPartnerCard(String name) {
    final bool isSelected = _selectedCompany == name;
    return GestureDetector(
      onTap: () => setState(() => _selectedCompany = name),
      child: Container(
        margin: EdgeInsets.only(right: 12.w, bottom: 4.h, top: 4.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_bus, color: isSelected ? Colors.white : AppColors.primary, size: 16.w),
            SizedBox(width: 8.w),
            Text(name, style: TextStyle(fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppColors.primary, fontSize: 13.sp)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Demande de Crédit Voyage'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Où souhaitez-vous aller ?',
              style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            SizedBox(height: 8.h),
            Text(
              'Obtenez un crédit pour réserver vos billets de car.',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),
            SizedBox(height: 24.h),
            
            Text('Nos partenaires', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
            SizedBox(height: 12.h),
            SizedBox(
              height: 45.h,
              child: ListView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                children: [
                  _buildPartnerCard('UTB'),
                  _buildPartnerCard('MT'),
                  _buildPartnerCard('AVS'),
                  _buildPartnerCard('CTE'),
                  _buildPartnerCard('SBTA'),
                ],
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
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      decoration: BoxDecoration(
                        color: !_isRoundTrip ? AppColors.primary : Colors.grey[100],
                        borderRadius: BorderRadius.horizontal(left: Radius.circular(12.r)),
                        border: Border.all(color: !_isRoundTrip ? AppColors.primary : Colors.grey[300]!),
                      ),
                      child: Center(
                        child: Text(
                          'Aller simple',
                          style: TextStyle(
                            color: !_isRoundTrip ? Colors.white : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isRoundTrip = true),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      decoration: BoxDecoration(
                        color: _isRoundTrip ? AppColors.primary : Colors.grey[100],
                        borderRadius: BorderRadius.horizontal(right: Radius.circular(12.r)),
                        border: Border.all(color: _isRoundTrip ? AppColors.primary : Colors.grey[300]!),
                      ),
                      child: Center(
                        child: Text(
                          'Aller-retour',
                          style: TextStyle(
                            color: _isRoundTrip ? Colors.white : Colors.grey[600],
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

            Text('Ville de départ', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8.h),
            LayoutBuilder(
              builder: (context, constraints) {
                return DropdownMenu<String>(
                  width: constraints.maxWidth,
                  enableFilter: true,
                  requestFocusOnTap: true,
                  leadingIcon: Icon(Icons.location_on_outlined, color: AppColors.secondary),
                  hintText: 'Rechercher une ville',
                  inputDecorationTheme: InputDecorationTheme(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: AppColors.primary)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                  ),
                  dropdownMenuEntries: _cities.map((city) {
                    return DropdownMenuEntry(value: city, label: city);
                  }).toList(),
                  onSelected: (val) => setState(() => _departureCity = val),
                );
              }
            ),
            SizedBox(height: 20.h),

            Text('Ville d\'arrivée', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8.h),
            LayoutBuilder(
              builder: (context, constraints) {
                return DropdownMenu<String>(
                  width: constraints.maxWidth,
                  enableFilter: true,
                  requestFocusOnTap: true,
                  leadingIcon: Icon(Icons.flag_outlined, color: AppColors.tertiary),
                  hintText: 'Rechercher une ville',
                  inputDecorationTheme: InputDecorationTheme(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: AppColors.primary)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                  ),
                  dropdownMenuEntries: _cities.map((city) {
                    return DropdownMenuEntry(value: city, label: city);
                  }).toList(),
                  onSelected: (val) => setState(() => _arrivalCity = val),
                );
              }
            ),
            SizedBox(height: 20.h),

            Text('Date du voyage', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, color: AppColors.primary),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              _selectedDate == null
                                  ? 'Départ'
                                  : DateFormat('d MMM yyyy', 'fr_FR').format(_selectedDate!),
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: _selectedDate == null ? Colors.grey[600] : Colors.black87,
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
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, color: AppColors.primary),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                _returnDate == null
                                    ? 'Retour'
                                    : DateFormat('d MMM yyyy', 'fr_FR').format(_returnDate!),
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: _returnDate == null ? Colors.grey[600] : Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
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

            Text('Passagers', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[400]!),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_outline, color: AppColors.primary),
                      SizedBox(width: 12.w),
                      Text(
                        '${_passengerCount * (_isRoundTrip ? 2 : 1)} Billet${(_passengerCount * (_isRoundTrip ? 2 : 1)) > 1 ? 's' : ''}', 
                        style: TextStyle(fontSize: 16.sp)
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline, color: Colors.grey),
                        onPressed: _passengerCount > 1
                            ? () => setState(() => _passengerCount--)
                            : null,
                      ),
                      Text('$_passengerCount', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline, color: AppColors.primary),
                        onPressed: _passengerCount < 10
                            ? () => setState(() => _passengerCount++)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            if (_estimatedPrice != null) ...[
              SizedBox(height: 24.h),
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Crédit demandé (Transport)', style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp)),
                        Text('${NumberFormat('#,###', 'fr_FR').format(_estimatedPrice)} FCFA', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15.sp)),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Divider(color: AppColors.primary.withOpacity(0.1), height: 1),
                    SizedBox(height: 12.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Frais de service (À payer)', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16.sp)),
                        Text('${NumberFormat('#,###', 'fr_FR').format(_serviceFee)} FCFA', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18.sp)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            
            SizedBox(height: 24.h),
            
            SizedBox(
              width: double.infinity,
              height: 55.h,
              child: ElevatedButton(
                onPressed: _proceedToSummary,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: Text(
                  'Faire la demande de crédit', 
                  style: TextStyle(fontSize: 18.sp, color: Colors.white, fontWeight: FontWeight.bold)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
