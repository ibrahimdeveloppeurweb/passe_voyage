import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';
import '../../../core/theme/app_colors.dart';
import '../../../config/routes.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/passenger_service.dart';
import '../../../core/services/notification_push_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _passenger;
  bool _isIdentified = false;
  bool _isOffline = false;
  String _displayName = 'Passager';
  String _identityStatus = 'NOT_SUBMITTED';
  String _formattedCredit = '0';
  List<Map<String, dynamic>> _recentActivities = [];
  StreamSubscription<Map<String, dynamic>>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _notificationSubscription = NotificationPushService.onNotificationStream.listen((data) {
      debugPrint('⚡ [DashboardScreen Realtime Event] FCM Notification received. Refreshing profile...');
      _loadProfile();
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final storage = await StorageService.getInstance();
    final passengerData = storage.getPassengerData();
    final cachedCredit = storage.getFormattedCredit();
    final cachedActivities = storage.getRecentActivities();

    if (mounted) {
      setState(() {
        _passenger = passengerData;
        _formattedCredit = cachedCredit;
        _recentActivities = cachedActivities;

        if (passengerData != null) {
          final firstname = passengerData['firstname'] ?? passengerData['first_name'] ?? '';
          final lastname = passengerData['lastname'] ?? passengerData['last_name'] ?? '';
          _displayName = '$firstname $lastname'.trim();
          if (_displayName.isEmpty) _displayName = 'Passager';

          _identityStatus = (passengerData['identityStatus'] ?? passengerData['identity_status'] ?? 'NOT_SUBMITTED').toString().toUpperCase();
          final isIdentifiedBool = passengerData['isIdentified'] ?? passengerData['is_identified'] ?? false;
          _isIdentified = isIdentifiedBool || (_identityStatus == 'VERIFIED' || _identityStatus == 'VALIDATED');
        }
      });
    }

    // Récupération des données en ligne du backend (Solde & Activités réelles)
    final dashboardResult = await PassengerService.getDashboardData();
    if (mounted) {
      final isOfflineResult = dashboardResult['isOffline'] == true;
      if (dashboardResult['success'] == true) {
        final newCredit = dashboardResult['formattedCredit']?.toString() ?? _formattedCredit;
        final newActivitiesRaw = dashboardResult['recentActivities'];

        List<Map<String, dynamic>> newActivities = [];
        if (newActivitiesRaw is List) {
          newActivities = newActivitiesRaw.map((e) => Map<String, dynamic>.from(e)).toList();
        }

        setState(() {
          _isOffline = isOfflineResult;
          _formattedCredit = newCredit;
          if (newActivities.isNotEmpty) {
            _recentActivities = newActivities;
          }
          if (dashboardResult['identityStatus'] != null) {
            _identityStatus = dashboardResult['identityStatus'].toString().toUpperCase();
            _isIdentified = (dashboardResult['isIdentified'] == true) || (_identityStatus == 'VERIFIED' || _identityStatus == 'VALIDATED');
          }
        });

        // Sauvegarde locale pour le mode Hors-Ligne (Ex: Gare routière)
        await storage.saveFormattedCredit(newCredit);
        if (newActivities.isNotEmpty) {
          await storage.saveRecentActivities(newActivities);
        }
      } else {
        setState(() {
          _isOffline = isOfflineResult;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Light premium background
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await _loadProfile();
            },
            color: AppColors.primary,
            backgroundColor: Colors.white,
            displacement: 20,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverAppBar(
                  backgroundColor: AppColors.background.withOpacity(0.9),
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  pinned: true,
                  toolbarHeight: 70,
                  title: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.profile);
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person, color: AppColors.primary),
                        ),
                        SizedBox(width: 12.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Bienvenue,', style: TextStyle(color: Colors.grey[600], fontSize: 13.sp)),
                            Text(_displayName, style: TextStyle(color: Colors.black87, fontSize: 18.sp, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    Container(
                      margin: EdgeInsets.only(right: 20.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 1,
                          )
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.notifications);
                        },
                      ),
                    ),
                  ],
                ),

                SliverToBoxAdapter(child: SizedBox(height: 10.h)),

                if (_isOffline)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.offline_pin_rounded, color: AppColors.primary, size: 20.w),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              'Mode Hors-Ligne',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Affichage conditionnel de la bannière si le compte N'EST PAS encore validé/vérifié
                if (!_isIdentified) ...[
                  _IdentificationBanner(identityStatus: _identityStatus),
                  SliverToBoxAdapter(child: SizedBox(height: 24.h)),
                ],

                // Solde Premium Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Container(
                      padding: EdgeInsets.all(24.w),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SOLDE CRÉDIT À REMBOURSER',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                _formattedCredit,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 36.sp,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                'XOF',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20.h),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, AppRoutes.remboursement).then((_) => _loadProfile());
                            },
                            icon: Icon(Icons.payment, color: AppColors.primary, size: 20.w),
                            label: Text(
                              'REMBOURSER MON CRÉDIT',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.sp,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              elevation: 0,
                              minimumSize: Size(double.infinity, 48.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(child: SizedBox(height: 28.h)),

                // Action Menu Grid (Demande, Pass, Remboursements)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildActionButton(
                          context,
                          icon: Icons.assignment_turned_in_outlined,
                          label: 'Demande\nCrédit',
                          bgColor: const Color(0xFFE8F1F5),
                          iconColor: const Color(0xFF2B5B75),
                          route: AppRoutes.demandeCredit,
                        ),
                        _buildActionButton(
                          context,
                          icon: Icons.confirmation_number_outlined,
                          label: 'Mes\nPass',
                          bgColor: const Color(0xFFFFF0E6),
                          iconColor: const Color(0xFFD97736),
                          route: AppRoutes.mesPass,
                        ),
                        _buildActionButton(
                          context,
                          icon: Icons.account_balance_wallet_outlined,
                          label: 'Mes\nRemboursements',
                          bgColor: const Color(0xFFE8F5E9),
                          iconColor: const Color(0xFF388E3C),
                          route: AppRoutes.mesRemboursements,
                        ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(child: SizedBox(height: 32.h)),

                // Section title: Activités récentes
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Activités récentes',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.notifications);
                          },
                          child: Text(
                            'Voir tout',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Transactions List
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  sliver: _recentActivities.isEmpty
                      ? SliverToBoxAdapter(
                          child: Container(
                            padding: EdgeInsets.all(20.w),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Text(
                              'Aucune activité récente pour le moment.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[500], fontSize: 13.sp),
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = _recentActivities[index];
                              final iconType = item['iconType']?.toString();
                              IconData iconData = Icons.account_balance_wallet;
                              if (iconType == 'BUS') iconData = Icons.directions_bus;
                              if (iconType == 'PAYMENT') iconData = Icons.payment;

                              return _buildTransactionCard(
                                icon: iconData,
                                title: item['title']?.toString() ?? 'Activité',
                                date: item['date']?.toString() ?? '',
                                amount: item['amount']?.toString() ?? '',
                                isPositive: item['isPositive'] == true,
                              );
                            },
                            childCount: _recentActivities.length > 6 ? 6 : _recentActivities.length,
                          ),
                        ),
                ),

                SliverToBoxAdapter(child: SizedBox(height: 40.h)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color iconColor,
    required String route,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, route);
      },
      child: Column(
        children: [
          Container(
            width: 64.w,
            height: 64.w,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Icon(icon, color: iconColor, size: 28.w),
          ),
          SizedBox(height: 10.h),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              height: 1.2.h,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard({
    required IconData icon,
    required String title,
    required String date,
    required String amount,
    required bool isPositive,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
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
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22.w),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  date,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount.replaceAll('FCFA', 'XOF'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15.sp,
              color: isPositive ? const Color(0xFF2E7D32) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentificationBanner extends StatefulWidget {
  final String identityStatus;
  const _IdentificationBanner({Key? key, required this.identityStatus}) : super(key: key);

  @override
  State<_IdentificationBanner> createState() => _IdentificationBannerState();
}

class _IdentificationBannerState extends State<_IdentificationBanner> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isPending = widget.identityStatus == 'PENDING' || widget.identityStatus == 'SUBMITTED';
    final isRejected = widget.identityStatus == 'REJECTED' || widget.identityStatus == 'REFUSED';

    // Couleurs et textes dynamiques selon l'état du dossier
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

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Row(
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
                        _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
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
          ),
        ),
      ),
    );
  }
}
