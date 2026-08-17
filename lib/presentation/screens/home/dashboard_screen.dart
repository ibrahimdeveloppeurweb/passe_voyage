import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';
import '../../../core/theme/app_colors.dart';
import '../../../config/routes.dart';
import '../../../core/services/storage_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _passenger;
  bool _isIdentified = false;
  String _displayName = 'Passager';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final storage = await StorageService.getInstance();
    final passengerData = storage.getPassengerData();
    if (passengerData != null) {
      setState(() {
        _passenger = passengerData;
        final firstname = passengerData['firstname'] ?? passengerData['first_name'] ?? '';
        final lastname = passengerData['lastname'] ?? passengerData['last_name'] ?? '';
        _displayName = '$firstname $lastname'.trim();
        if (_displayName.isEmpty) _displayName = 'Passager';

        final identityStatus = (passengerData['identityStatus'] ?? passengerData['identity_status'] ?? 'PENDING').toString().toUpperCase();
        final isIdentifiedBool = passengerData['isIdentified'] ?? passengerData['is_identified'] ?? false;

        _isIdentified = isIdentifiedBool || (identityStatus == 'VERIFIED' || identityStatus == 'VALIDATED');
      });
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

                SliverToBoxAdapter(child: SizedBox(height: 20.h)),

                // Affichage conditionnel de la bannière si le compte N'EST PAS encore validé/vérifié
                if (!_isIdentified) ...[
                  const _IdentificationBanner(),
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
                            'CRÉDIT VOYAGE DISPONIBLE',
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
                                '160.000',
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
                              Navigator.pushNamed(context, AppRoutes.remboursement);
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
                          onPressed: () {},
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
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildTransactionCard(
                        icon: Icons.account_balance_wallet,
                        title: 'Octroi Crédit Voyage',
                        date: '04 Jan • Validé',
                        amount: '+ 15.000F',
                        isPositive: true,
                      ),
                      _buildTransactionCard(
                        icon: Icons.directions_bus,
                        title: 'Achat Ticket UTB',
                        date: '05 Jan • Abidjan-Yakro',
                        amount: '- 5.000F',
                        isPositive: false,
                      ),
                    ]),
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
            amount,
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
  const _IdentificationBanner({Key? key}) : super(key: key);

  @override
  State<_IdentificationBanner> createState() => _IdentificationBannerState();
}

class _IdentificationBannerState extends State<_IdentificationBanner> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF7ECE1), // Soft warm amber background
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
                          'Bienvenue chez Passe Voyage',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Icon(
                        _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: AppColors.primary,
                        size: 28.w,
                      ),
                    ],
                  ),
                ),
                if (!_isExpanded) ...[
                  SizedBox(height: 12.h),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.identitySelection);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                      child: Text(
                        'Identifiez-vous et débloquez votre compte !',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  SizedBox(height: 12.h),
                  Text(
                    'Complétez votre identification sous 14 jours pour profiter pleinement de votre compte Passe Voyage !',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14.sp,
                      height: 1.4.h,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.identitySelection);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                      child: Text(
                        'Identifiez-vous !',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
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
