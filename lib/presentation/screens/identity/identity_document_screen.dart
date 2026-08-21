import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../config/routes.dart';
import '../../../core/services/passenger_service.dart';

class IdentityDocumentScreen extends StatefulWidget {
  const IdentityDocumentScreen({Key? key}) : super(key: key);

  @override
  State<IdentityDocumentScreen> createState() => _IdentityDocumentScreenState();
}

class _IdentityDocumentScreenState extends State<IdentityDocumentScreen> {
  XFile? _rectoImage;
  XFile? _versoImage;
  String? _rectoBase64;
  String? _versoBase64;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source, Function(XFile, String?) onPicked) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 75,
      );
      if (image != null) {
        String? b64;
        try {
          final bytes = await image.readAsBytes();
          if (bytes.isNotEmpty) {
            b64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
          }
        } catch (e) {
          debugPrint('💥 Error encoding image to base64 via readAsBytes: $e');
          try {
            final file = File(image.path);
            final bytes = await file.readAsBytes();
            if (bytes.isNotEmpty) {
              b64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
            }
          } catch (e2) {
            debugPrint('💥 Error encoding image to base64 via File: $e2');
          }
        }
        debugPrint('📸 [IdentityDocumentScreen] Picked image b64 len: ${b64?.length ?? 0}');
        onPicked(image, b64);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showPickerModal(Function(XFile, String?) onPicked) {
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
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String identityType = args?['identityType'] ?? 'CNI';
    final bool isPassport = identityType == 'PASSPORT';

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
                isPassport
                    ? 'Prenez en photo la page principale de votre passeport'
                    : 'Prenez en photo la pièce en vous assurant que les informations sont bien visibles',
                style: TextStyle(
                  color: AppColors.primary.withOpacity(0.8),
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 24.h),
              Expanded(
                child: ListView(
                  children: [
                    _buildScanBox(isPassport ? 'Page Principale Passeport' : 'Pièce Recto', _rectoImage, () {
                      _showPickerModal((file, b64) => setState(() {
                        _rectoImage = file;
                        _rectoBase64 = b64;
                        IdentitySession.rectoPath = file.path;
                        IdentitySession.rectoBase64 = b64;
                      }));
                    }),
                    if (!isPassport)
                      _buildScanBox('Pièce Verso', _versoImage, () {
                        _showPickerModal((file, b64) => setState(() {
                          _versoImage = file;
                          _versoBase64 = b64;
                          IdentitySession.versoPath = file.path;
                          IdentitySession.versoBase64 = b64;
                        }));
                      }),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (isPassport ? _rectoImage != null : (_rectoImage != null && _versoImage != null))
                      ? () async {
                          String? rB64 = _rectoBase64 ?? IdentitySession.rectoBase64;
                          String? vB64 = _versoBase64 ?? IdentitySession.versoBase64;

                          if ((rB64 == null || rB64.isEmpty) && _rectoImage != null) {
                            rB64 = await PassengerService.fileToBase64(_rectoImage!.path);
                          }
                          if (!isPassport && (vB64 == null || vB64.isEmpty) && _versoImage != null) {
                            vB64 = await PassengerService.fileToBase64(_versoImage!.path);
                          }

                          IdentitySession.rectoBase64 = rB64;
                          IdentitySession.versoBase64 = vB64;
                          IdentitySession.rectoPath = _rectoImage?.path;
                          IdentitySession.versoPath = _versoImage?.path;

                          debugPrint('📸 [IdentityDocumentScreen] Saved to IdentitySession - recto B64 len: ${rB64?.length ?? 0}, verso B64 len: ${vB64?.length ?? 0}');

                          if ((rB64 == null || rB64.isEmpty) || (!isPassport && (vB64 == null || vB64.isEmpty))) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Impossible d\'encoder la photo. Veuillez reprendre la photo.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                            return;
                          }

                          if (!mounted) return;

                          Navigator.pushNamed(
                            context,
                            AppRoutes.identitySelfie,
                            arguments: {
                              'identityType': identityType,
                              'rectoPath': _rectoImage?.path,
                              'versoPath': _versoImage?.path,
                              'rectoBase64': rB64,
                              'versoBase64': vB64,
                            },
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
