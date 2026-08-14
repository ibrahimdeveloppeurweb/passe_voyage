import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  Widget _buildNotificationItem(String title, String description, String time, bool isUnread, IconData icon, Color iconColor) {
    return Container(
      padding: EdgeInsets.all(16.w),
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isUnread ? Colors.blue[50] : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          if (isUnread)
            BoxShadow(
              color: Colors.blue.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          else
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24.w),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                          fontSize: 15.sp,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8.w,
                        height: 8.h,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
        title: Text(
          'NOTIFICATIONS',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w900,
            fontSize: 16.sp,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(20.w),
        children: [
          Text(
            'Aujourd\'hui',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 14.sp),
          ),
          SizedBox(height: 12.h),
          _buildNotificationItem(
            'Crédit validé',
            'Félicitations ! Votre demande de crédit voyage de 160.000 F a été approuvée.',
            'Il y a 10 minutes',
            true,
            Icons.task_alt,
            AppColors.success,
          ),
          _buildNotificationItem(
            'Remboursement reçu',
            'Votre remboursement de 15.000 F a bien été reçu et traité.',
            'Il y a 2 heures',
            true,
            Icons.check_circle_outline,
            AppColors.secondary,
          ),
          _buildNotificationItem(
            'Pass UTB scanné',
            'Votre Pass UTB (Abidjan - Yamoussoukro) a été scanné avec succès.',
            'Il y a 5 heures',
            true,
            Icons.directions_bus,
            AppColors.tertiary,
          ),
          SizedBox(height: 20.h),
          Text(
            'Hier',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 14.sp),
          ),
          SizedBox(height: 12.h),
          _buildNotificationItem(
            'Crédit refusé',
            'Votre récente demande de crédit voyage n\'a malheureusement pas été validée.',
            'Hier à 16:45',
            false,
            Icons.cancel_outlined,
            AppColors.error,
          ),
          _buildNotificationItem(
            'Rappel Identité',
            'N\'oubliez pas de compléter votre profil sous 14 jours.',
            'Hier à 14:30',
            false,
            Icons.warning_amber_rounded,
            Colors.orange,
          ),
          _buildNotificationItem(
            'Bienvenue sur Passe Voyage',
            'Votre compte a été créé avec succès. Profitez de vos voyages !',
            'Hier à 09:15',
            false,
            Icons.celebration,
            AppColors.primary,
          ),
        ],
      ),
    );
  }
}
