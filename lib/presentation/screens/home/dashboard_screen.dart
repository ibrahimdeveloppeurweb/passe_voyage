import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';
import '../../../core/theme/app_colors.dart';
import '../../../config/routes.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Light premium background
      body: Stack(
        children: [

          RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(seconds: 1));
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
                            Text('Cissé Ibrahim', style: TextStyle(color: Colors.black87, fontSize: 18.sp, fontWeight: FontWeight.bold)),
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
                        icon: Icon(Icons.notifications_outlined, color: Colors.black87),
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.notifications);
                        },
                      ),
                    ),
                  ],
                ),
                
                SliverToBoxAdapter(child: SizedBox(height: 20.h)),
                
                const _IdentificationBanner(),
                
                SliverToBoxAdapter(child: SizedBox(height: 24.h)),

                // Solde
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      Text(
                        'CRÉDIT VOYAGE',
                        style: TextStyle(
                          color: Color(0xFF6B7280), // Gris foncé
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '160.000',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 42.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.5,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 8.0.h),
                            child: Text(
                              'F',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Padding(
                            padding: EdgeInsets.only(top: 8.0.h),
                            child: Icon(Icons.visibility_off, color: AppColors.primary, size: 20.w),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                SliverToBoxAdapter(child: SizedBox(height: 24.h)),
                
                // Bouton Scanner un code
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.0.w),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context, 
                          AppRoutes.remboursement,
                          arguments: {'amount': 160000},
                        );
                      },
                      icon: Icon(Icons.payment, color: AppColors.background),
                      label: Text(
                        'REMBOURSER MON CRÉDIT',
                        style: TextStyle(
                          color: AppColors.background,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary, // Utilisation stricte de la couleur primaire
                        padding: EdgeInsets.symmetric(vertical: 20.h), // Taller button
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
                
                SliverToBoxAdapter(child: SizedBox(height: 24.h)),
                
                // 3 Actions Rapides
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.0.w),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 20.h),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.01),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildLightActionItem(
                            Icons.credit_score, 
                            'Demande\nCrédit', 
                            AppColors.primary.withOpacity(0.15),
                            AppColors.primary,
                            onTap: () {
                              Navigator.pushNamed(context, AppRoutes.demandeCredit);
                            },
                          ),
                          _buildLightActionItem(
                            Icons.confirmation_number, 
                            'Mes\nPass', 
                            AppColors.tertiary.withOpacity(0.15),
                            AppColors.tertiary,
                            onTap: () {
                              Navigator.pushNamed(context, AppRoutes.mesPass);
                            },
                          ),
                          _buildLightActionItem(
                            Icons.payment, 
                            'Mes\nRemboursements', 
                            AppColors.secondary.withOpacity(0.15),
                            AppColors.secondary,
                            onTap: () {
                              Navigator.pushNamed(context, AppRoutes.mesRemboursements);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                SliverToBoxAdapter(child: SizedBox(height: 24.h)),
                
                // Transactions
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.0.w),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.01),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildTransactionItem('Octroi Crédit Voyage', '04 Jan • Validé', '+ 15.000F', Icons.account_balance_wallet),
                          Divider(height: 1.h, color: AppColors.textSecondary.withOpacity(0.04), indent: 52, endIndent: 16),
                          _buildTransactionItem('Achat Ticket UTB', '05 Jan • Abidjan-Yakro', '- 5.000F', Icons.directions_bus),
                          Divider(height: 1.h, color: AppColors.textSecondary.withOpacity(0.04), indent: 52, endIndent: 16),
                          _buildTransactionItem('Achat Ticket UTB', '08 Jan • Yakro-Abidjan', '- 5.000F', Icons.directions_bus),
                          Divider(height: 1.h, color: AppColors.textSecondary.withOpacity(0.04), indent: 52, endIndent: 16),
                          _buildTransactionItem('Remboursement', '12 Jan • Mobile Money', '+ 5.000F', Icons.payment),
                          Divider(height: 1.h, color: AppColors.textSecondary.withOpacity(0.04), indent: 52, endIndent: 16),
                          _buildTransactionItem('Frais de dossier', '04 Jan • Système', '- 500F', Icons.receipt_long),
                          Divider(height: 1.h, color: AppColors.textSecondary.withOpacity(0.04), indent: 52, endIndent: 16),
                          _buildTransactionItem('Remboursement', '15 Jan • Espèces Guichet', '+ 5.000F', Icons.payment),
                        ],
                      ),
                    ),
                  ),
                ),
                
                SliverToBoxAdapter(child: SizedBox(height: 30.h)), // Petite hauteur en bas
            ],
          ),
        ),
        ],
      ),
    );
  }


  Widget _buildLightActionItem(IconData icon, String title, Color bgColor, Color iconColor, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24.w),
          ),
          SizedBox(height: 8.h),
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11.sp),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(String title, String subtitle, String amount, [IconData icon = Icons.shopping_cart]) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0.w, vertical: 14.0.h),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey[200], size: 20.w),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(color: AppColors.primary, fontSize: 13.sp, fontWeight: FontWeight.w600)),
                Text(subtitle, style: TextStyle(color: AppColors.textSecondary, fontSize: 11.sp)),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(color: AppColors.primary, fontSize: 13.sp, fontWeight: FontWeight.w600),
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
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.0.w),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppColors.tertiary.withOpacity(0.2), // Light amber/beige background
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
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
