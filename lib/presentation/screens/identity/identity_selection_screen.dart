import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../config/routes.dart';

class IdentitySelectionScreen extends StatelessWidget {
  const IdentitySelectionScreen({Key? key}) : super(key: key);

  Widget _buildDocumentOption(BuildContext context, String title, IconData icon) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.identityDocument);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
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
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(int step) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.0.h, top: 8.0.h),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 4.h,
              decoration: BoxDecoration(
                color: step >= 1 ? AppColors.primary : Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Container(
              height: 4.h,
              decoration: BoxDecoration(
                color: step >= 2 ? AppColors.primary : Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Container(
              height: 4.h,
              decoration: BoxDecoration(
                color: step >= 3 ? AppColors.primary : Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.0.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProgressBar(1),
              Text(
                'Identification',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Sélectionnez votre pièce d\'identité',
                style: TextStyle(
                  color: AppColors.primary.withOpacity(0.8),
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 32.h),
              Expanded(
                child: ListView(
                  children: [
                    _buildDocumentOption(context, 'CNI', Icons.badge_outlined),
                    _buildDocumentOption(context, 'Passeport', Icons.book_outlined),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
