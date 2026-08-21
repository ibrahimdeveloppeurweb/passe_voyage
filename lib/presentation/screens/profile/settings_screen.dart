import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/passenger_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final storage = await StorageService.getInstance();
    if (mounted) {
      setState(() {
        _notificationsEnabled = storage.getNotificationsEnabled();
        _locationEnabled = storage.getLocationEnabled();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });
    final storage = await StorageService.getInstance();
    await storage.setNotificationsEnabled(value);
  }

  Future<void> _toggleLocation(bool value) async {
    setState(() {
      _locationEnabled = value;
    });
    final storage = await StorageService.getInstance();
    await storage.setLocationEnabled(value);
  }

  Future<void> _showRatingModal() async {
    final storage = await StorageService.getInstance();
    int rating = storage.getLastRating();
    bool isSubmitting = false;
    final commentController = TextEditingController();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 24.h,
                left: 20.w,
                right: 20.w,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24.h,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Icon(Icons.star_rounded, color: Colors.amber, size: 50.w),
                  SizedBox(height: 12.h),
                  Text(
                    'Noter Pass Voyage',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Aimez-vous l\'application ? Laissez-nous une évaluation !',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
                  ),
                  SizedBox(height: 20.h),

                  // Etoiles interactives
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starIndex = index + 1;
                      return GestureDetector(
                        onTap: isSubmitting
                            ? null
                            : () {
                                setModalState(() {
                                  rating = starIndex;
                                });
                              },
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          child: Icon(
                            starIndex <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: Colors.amber,
                            size: 38.w,
                          ),
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 20.h),

                  // Champ de commentaire optionnel
                  TextField(
                    controller: commentController,
                    enabled: !isSubmitting,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Écrivez votre avis (optionnel)...',
                      hintStyle: TextStyle(fontSize: 13.sp, color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.all(14.w),
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Bouton soumettre
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setModalState(() {
                                isSubmitting = true;
                              });

                              final result = await PassengerService.submitRating(
                                rating: rating,
                                comment: commentController.text.trim(),
                              );

                              if (result['success'] == true) {
                                await storage.setLastRating(rating);
                              }

                              if (Navigator.canPop(modalContext)) {
                                Navigator.pop(modalContext);
                              }

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(
                                          result['success'] == true ? Icons.check_circle_rounded : Icons.info_rounded,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 10.w),
                                        Expanded(
                                          child: Text(
                                            result['message'] ?? 'Évaluation envoyée avec succès !',
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: result['success'] == true ? Colors.green[700] : AppColors.primary,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                    margin: EdgeInsets.all(16.w),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                      ),
                      child: isSubmitting
                          ? SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              'Envoyer la note',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15.sp),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAboutModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 20.h),
              Container(
                width: 70.w,
                height: 70.w,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 45.w,
                    height: 45.w,
                    errorBuilder: (_, __, ___) => Icon(Icons.directions_bus_rounded, color: AppColors.primary, size: 36.w),
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                'Pass Voyage',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'Version 1.0.0 (Build 102)',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
              ),
              SizedBox(height: 16.h),
              Text(
                'Pass Voyage est la plateforme moderne de mobilité interurbaine en Côte d\'Ivoire. Effectuez vos réservations de tickets de car à crédit grâce au crédit voyage et voyagez en toute sérénité.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary, height: 1.4),
              ),
              SizedBox(height: 24.h),
              Divider(color: Colors.grey[200]),
              SizedBox(height: 12.h),

              _buildAboutInfoRow(Icons.security, 'Sécurité des données', 'Conforme aux normes de protection'),
              SizedBox(height: 10.h),
              _buildAboutInfoRow(Icons.support_agent, 'Assistance Client', 'Disponible 7j/7 de 8h à 20h'),

              SizedBox(height: 24.h),
              Text(
                '© 2026 Pass Voyage. Tous droits réservés.',
                style: TextStyle(fontSize: 11.sp, color: Colors.grey[400]),
              ),
              SizedBox(height: 10.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAboutInfoRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20.w),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp, color: AppColors.primary)),
              Text(subtitle, style: TextStyle(fontSize: 11.sp, color: Colors.grey[600])),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primary, size: 24.w),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Paramètres',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: EdgeInsets.all(20.0.w),
              child: Column(
                children: [
                  _buildToggleItem(
                    Icons.notifications,
                    'Notifications',
                    _notificationsEnabled,
                    _toggleNotifications,
                    AppColors.primary,
                  ),
                  SizedBox(height: 12.h),
                  _buildToggleItem(
                    Icons.location_on,
                    'Géolocalisation',
                    _locationEnabled,
                    _toggleLocation,
                    AppColors.primary,
                  ),
                  SizedBox(height: 12.h),
                  _buildActionItem(
                    Icons.star_rate_rounded,
                    'Noter l\'application',
                    _showRatingModal,
                  ),
                  SizedBox(height: 12.h),
                  _buildActionItem(
                    Icons.info_rounded,
                    'À propos de nous',
                    _showAboutModal,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildToggleItem(
    IconData icon,
    String title,
    bool value,
    ValueChanged<bool> onChanged,
    Color activeColor,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20.w),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: activeColor,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey.shade300,
              trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((states) => Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 20.w),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_right, color: AppColors.primary, size: 20.w),
          ],
        ),
      ),
    );
  }
}
