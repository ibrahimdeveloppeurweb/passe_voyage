import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../config/routes.dart';

class IdentityDocumentScreen extends StatefulWidget {
  const IdentityDocumentScreen({Key? key}) : super(key: key);

  @override
  State<IdentityDocumentScreen> createState() => _IdentityDocumentScreenState();
}

class _IdentityDocumentScreenState extends State<IdentityDocumentScreen> {
  XFile? _rectoImage;
  XFile? _versoImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source, Function(XFile) onPicked) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        onPicked(image);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showPickerModal(Function(XFile) onPicked) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: AppColors.primary),
                title: Text('Prendre une photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera, onPicked);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: AppColors.primary),
                title: Text('Choisir depuis la galerie'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery, onPicked);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScanBox(String title, XFile? imageFile, VoidCallback onTap) {
    final isDone = imageFile != null;
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 24.h),
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
          if (imageFile != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: Image.file(
                File(imageFile.path),
                height: 120.h,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            Icon(
              Icons.badge_outlined,
              size: 64.w,
              color: AppColors.primary.withOpacity(0.8),
            ),
          SizedBox(height: 16.h),
          Text(
            title,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(isDone ? Icons.check : Icons.camera_alt, color: Colors.white),
              label: Text(
                isDone ? 'Photo prise' : 'Prendre une photo',
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
              _buildProgressBar(2),
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
                'Prenez en photo la pièce en vous assurant que les informations sont bien visibles',
                style: TextStyle(
                  color: AppColors.primary.withOpacity(0.8),
                  fontSize: 14.sp,
                  height: 1.4.h,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 32.h),
              Expanded(
                child: ListView(
                  children: [
                    _buildScanBox('Pièce Recto', _rectoImage, () {
                      _showPickerModal((file) => setState(() => _rectoImage = file));
                    }),
                    _buildScanBox('Pièce Verso', _versoImage, () {
                      _showPickerModal((file) => setState(() => _versoImage = file));
                    }),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_rectoImage != null && _versoImage != null)
                      ? () {
                          Navigator.pushNamed(context, AppRoutes.identitySelfie);
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
