import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../config/routes.dart';

class IdentitySelfieScreen extends StatefulWidget {
  const IdentitySelfieScreen({Key? key}) : super(key: key);

  @override
  State<IdentitySelfieScreen> createState() => _IdentitySelfieScreenState();
}

class _IdentitySelfieScreenState extends State<IdentitySelfieScreen> {
  XFile? _selfieImage;

  Widget _buildRuleItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.0.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 4.0.h, right: 8.0.w),
            child: Icon(Icons.circle, size: 8.w, color: AppColors.primary),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
                fontSize: 13.sp,
              ),
            ),
          ),
        ],
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
      backgroundColor: AppColors.background,
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
              _buildProgressBar(3),
              Text(
                'Prenez un selfie',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Prendre une photo de vous',
                style: TextStyle(
                  color: AppColors.primary.withOpacity(0.8),
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info, color: AppColors.primary, size: 20.w),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Une photo ne satisfaisant pas aux exigences exposées ci-dessous ne sera pas admise.',
                      style: TextStyle(
                        color: AppColors.primary.withOpacity(0.9),
                        fontWeight: FontWeight.bold,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              _buildRuleItem('Visage dégagé'),
              _buildRuleItem('Être dans un environnement éclairé'),
              _buildRuleItem('Éviter les reflets de lunettes'),
              _buildRuleItem('Ne pas mettre de lunettes de soleil'),
              _buildRuleItem('Ne pas être torse nu'),
              SizedBox(height: 32.h),
              
              // Selfie Box
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (_selfieImage != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: Image.file(
                          File(_selfieImage!.path),
                          height: 120.h,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.crop_free, size: 80.w, color: Colors.grey[300]),
                          Icon(Icons.person, size: 40.w, color: AppColors.primary),
                        ],
                      ),
                    SizedBox(height: 16.h),
                    Text(
                      'Selfie Photo',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Il est requis par la loi de vérifier votre identité en tant que nouvel utilisateur.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.pushNamed(context, AppRoutes.customCamera);
                          if (result != null && result is XFile) {
                            setState(() {
                              _selfieImage = result;
                            });
                          }
                        },
                        icon: Icon(_selfieImage != null ? Icons.check : Icons.camera_alt, color: Colors.white),
                        label: Text(
                          _selfieImage != null ? 'Photo prise' : 'Prendre une photo',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selfieImage != null
                      ? () {
                          // Complete process and go back to dashboard
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            AppRoutes.dashboard,
                            (route) => false,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Identification soumise avec succès !"),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                  ),
                  child: Text(
                    'Continuer',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
