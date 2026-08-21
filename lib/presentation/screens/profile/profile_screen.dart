import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/passenger_service.dart';
import '../../../config/routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isBannerExpanded = true;
  String _userName = 'Passager';
  String _userPhone = '';
  bool _isIdentified = false;
  String _identityStatus = 'NOT_SUBMITTED';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final storage = await StorageService.getInstance();
    final passengerData = storage.getPassengerData();
    final phone = storage.getPhoneNumber() ?? passengerData?['phoneNumber'] ?? '';

    if (mounted) {
      setState(() {
        if (passengerData != null) {
          final fn = passengerData['firstname']?.toString() ?? passengerData['first_name']?.toString() ?? '';
          final ln = passengerData['lastname']?.toString() ?? passengerData['last_name']?.toString() ?? '';
          _userName = '$fn $ln'.trim();
          if (_userName.isEmpty) {
            _userName = 'Passager';
          }
          _identityStatus = (passengerData['identityStatus'] ?? passengerData['identity_status'] ?? 'NOT_SUBMITTED').toString().toUpperCase();
          final isIdentifiedBool = passengerData['isIdentified'] ?? passengerData['is_identified'] ?? false;
          _isIdentified = isIdentifiedBool || _identityStatus == 'VERIFIED' || _identityStatus == 'VALIDATED' || _identityStatus == 'APPROVED';
        }
        _userPhone = phone;
        _isLoading = false;
      });
    }

    // Interrogation du backend pour obtenir le statut KYC et le profil actualisé en temps réel
    try {
      final dashResult = await PassengerService.getDashboardData();
      if (dashResult['success'] == true && mounted) {
        final freshData = storage.getPassengerData();
        setState(() {
          if (freshData != null) {
            final fn = freshData['firstname']?.toString() ?? freshData['first_name']?.toString() ?? '';
            final ln = freshData['lastname']?.toString() ?? freshData['last_name']?.toString() ?? '';
            _userName = '$fn $ln'.trim();
            if (_userName.isEmpty) _userName = 'Passager';

            _identityStatus = (freshData['identityStatus'] ?? freshData['identity_status'] ?? 'NOT_SUBMITTED').toString().toUpperCase();
            final isIdentifiedBool = freshData['isIdentified'] ?? freshData['is_identified'] ?? false;
            _isIdentified = isIdentifiedBool || _identityStatus == 'VERIFIED' || _identityStatus == 'VALIDATED' || _identityStatus == 'APPROVED';
          } else if (dashResult['identityStatus'] != null) {
            _identityStatus = dashResult['identityStatus'].toString().toUpperCase();
            _isIdentified = (dashResult['isIdentified'] == true) || (_identityStatus == 'VERIFIED' || _identityStatus == 'VALIDATED' || _identityStatus == 'APPROVED');
          }
        });
      }
    } catch (e) {
      debugPrint('💥 Error syncing profile with backend: $e');
    }
  }

  String _formatPhoneDisplay(String phone) {
    if (phone.isEmpty) return '';
    String digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 10) {
      final last10 = digits.substring(digits.length - 10);
      return '${last10.substring(0, 2)} ${last10.substring(2, 4)} ${last10.substring(4, 6)} ${last10.substring(6, 8)} ${last10.substring(8, 10)}';
    }
    return phone;
  }

  Future<void> _handleLogout() async {
    final storage = await StorageService.getInstance();
    await storage.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.phoneEntry,
        (route) => false,
      );
    }
  }

  Future<void> _launchWhatsApp() async {
    const phoneNumber = '2250000000000';
    const message = 'Bonjour, j\'ai besoin d\'aide avec l\'application Passe Voyage.';
    final Uri url = Uri.parse('https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primary, size: 24.w),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadUserData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.0.w),
                child: Column(
                children: [
                  SizedBox(height: 10.h),
                  
                  // Profile Header Card (Dynamique)
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(24.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: Icon(Icons.person, color: Colors.white, size: 36.w),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _userName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                _formatPhoneDisplay(_userPhone),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.identitySelection);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Row(
                              children: [
                                Text('Mon profil', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13.sp)),
                                SizedBox(width: 2.w),
                                Icon(Icons.chevron_right, size: 16.w, color: Colors.white),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 24.h),
                  
                  // Identification Banner (Dynamique)
                  if (!_isIdentified)
                    Builder(
                      builder: (context) {
                        final isPending = _identityStatus == 'PENDING' || _identityStatus == 'SUBMITTED';
                        final isRejected = _identityStatus == 'REJECTED' || _identityStatus == 'REFUSED';

                        final Color bgColor = isPending
                            ? const Color(0xFFE8F0FE) // Soft Blue pour traitement
                            : isRejected
                                ? const Color(0xFFFFEBEE) // Soft Red pour refus
                                : const Color(0xFFF7ECE1); // Soft Amber pour démarrage

                        final Color textColor = isPending
                            ? const Color(0xFF1967D2)
                            : isRejected
                                ? const Color(0xFFD32F2F)
                                : AppColors.primary;

                        final String title = isPending
                            ? 'Dossier en cours de traitement'
                            : isRejected
                                ? 'Identification refusée'
                                : 'Bienvenue chez Pass Voyage';

                        final String shortMessage = isPending
                            ? 'Vos documents d\'identification ont été transmis. Votre compte est actuellement en cours de vérification par un administrateur.'
                            : isRejected
                                ? 'Votre dossier d\'identification a été refusé par l\'administrateur. Veuillez soumettre à nouveau vos pièces d\'identité.'
                                : 'Identifiez-vous et débloquez votre compte !';

                        return Container(
                          padding: EdgeInsets.all(20.w),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isBannerExpanded = !_isBannerExpanded;
                                  });
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      _isBannerExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                      color: textColor,
                                      size: 28.w,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 10.h),
                              Text(
                                shortMessage,
                                style: TextStyle(
                                  color: textColor.withOpacity(0.9),
                                  fontSize: 13.sp,
                                  height: 1.4.h,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (!isPending) ...[
                                SizedBox(height: 14.h),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(context, AppRoutes.identitySelection);
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                                    decoration: BoxDecoration(
                                      color: textColor,
                                      borderRadius: BorderRadius.circular(24.r),
                                    ),
                                    child: Text(
                                      isRejected ? 'Soumettre à nouveau vos documents' : 'Identifiez-vous et débloquez votre compte !',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.sp,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.verified_user_rounded, color: Colors.green, size: 28.w),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              'Compte Identifié & Vérifié',
                              style: TextStyle(
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 15.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  SizedBox(height: 24.h),
                  
                  // Menu List
                  _buildMenuItem(Icons.settings_outlined, 'Paramètres', onTap: () {
                    Navigator.pushNamed(context, AppRoutes.settings);
                  }),
                  _buildMenuItem(Icons.notifications_none_outlined, 'Notifications', onTap: () {
                    Navigator.pushNamed(context, AppRoutes.notifications);
                  }),
                  _buildMenuItem(Icons.storefront_outlined, 'Trouver une gare', onTap: () {
                    Navigator.pushNamed(context, AppRoutes.gares);
                  }),
                  _buildMenuItem(Icons.headset_mic_outlined, 'Aide et assistance', onTap: _launchWhatsApp),
                  
                  SizedBox(height: 40.h),
                  
                  // Footer
                  Text('Version 3.4.2 631', style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
                  SizedBox(height: 12.h),
                  Text('Conditions générales', style: TextStyle(color: Colors.grey, fontSize: 13.sp)),
                  SizedBox(height: 24.h),
                  
                  // Logout Button (Fonctionne En Ligne et Hors-Ligne)
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(
                              'Déconnexion',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                            content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context); // Fermer le modal
                                  await _handleLogout(); // Déconnexion locale + redirection immédiate
                                },
                                child: const Text('Se déconnecter', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'Se déconnecter',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24.w),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.primary, size: 20.w),
          ],
        ),
      ),
    );
  }
}
