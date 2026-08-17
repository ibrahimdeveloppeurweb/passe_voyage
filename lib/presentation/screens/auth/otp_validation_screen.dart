import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../widgets/custom_numpad.dart';
import '../../../config/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';

class OtpValidationScreen extends StatefulWidget {
  final String phoneNumber;
  final String countryCode;

  const OtpValidationScreen({Key? key, required this.phoneNumber, this.countryCode = '+225'}) : super(key: key);

  @override
  State<OtpValidationScreen> createState() => _OtpValidationScreenState();
}

class _OtpValidationScreenState extends State<OtpValidationScreen> {
  String _otpCode = '';
  bool _isVerifying = false;

  Future<void> _onKeyPressed(String value) async {
    if (_otpCode.length < 4 && !_isVerifying) {
      setState(() {
        _otpCode += value;
      });

      if (_otpCode.length == 4) {
        setState(() {
          _isVerifying = true;
        });

        final result = await AuthService.verifyOtp(widget.phoneNumber, _otpCode);

        if (mounted) {
          setState(() {
            _isVerifying = false;
          });

          if (result['success'] == true) {
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.pinEntry,
              arguments: {
                'phoneNumber': widget.phoneNumber,
                'countryCode': widget.countryCode,
              },
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Code OTP incorrect'),
                backgroundColor: Colors.redAccent,
              ),
            );
            setState(() {
              _otpCode = ''; // Réinitialiser le code
            });
          }
        }
      }
    }
  }

  void _onDelete() {
    if (_otpCode.isNotEmpty && !_isVerifying) {
      setState(() {
        _otpCode = _otpCode.substring(0, _otpCode.length - 1);
      });
    }
  }

  Future<void> _resendOtp() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Envoi du nouveau code en cours...')),
    );

    final result = await AuthService.sendOtp(widget.phoneNumber);

    if (mounted) {
      if (result['success'] == true) {
        final otpCode = result['otpCode']?.toString() ?? '1234';
        _showOtpDevModal(otpCode);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Erreur lors du renvoi OTP'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showOtpDevModal(String otpCode) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          title: Row(
            children: [
              Icon(Icons.sms_rounded, color: AppColors.primary, size: 28.w),
              SizedBox(width: 10.w),
              Expanded(
                child: Text('Nouveau Code (Mode Dev)', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Votre nouveau code SMS de validation est :',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: Text(
                  otpCode,
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8.0,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 10.h),

            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.chat_bubble_rounded,
                color: Colors.white,
                size: 28.w,
              ),
            ),

            SizedBox(height: 20.h),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.0.w),
              child: Text(
                'Entrez le code de validation envoyé\npar SMS au ${widget.phoneNumber}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                  height: 1.3.h,
                ),
              ),
            ),

            const Spacer(),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                bool isActive = index == _otpCode.length;
                bool isFilled = index < _otpCode.length;

                return Container(
                  width: 50.w,
                  height: 60.h,
                  margin: EdgeInsets.symmetric(horizontal: 10.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: isActive ? AppColors.primary : Colors.transparent,
                      width: isActive ? 2.0 : 0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isActive
                            ? AppColors.primary.withOpacity(0.15)
                            : Colors.black.withOpacity(0.04),
                        blurRadius: isActive ? 12 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: isFilled
                      ? Text(
                          _otpCode[index],
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        )
                      : isActive
                          ? Container(
                              width: 2.w,
                              height: 28.h,
                              color: AppColors.primary,
                            )
                          : null,
                );
              }),
            ),

            if (_isVerifying) ...[
              SizedBox(height: 16.h),
              SizedBox(
                height: 24.h,
                width: 24.w,
                child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
              ),
            ],

            const Spacer(),

            TextButton(
              onPressed: _resendOtp,
              child: Text(
                'Renvoyer SMS',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            SizedBox(height: 20.h),

            CustomNumpad(
              onKeyPressed: _onKeyPressed,
              onDelete: _onDelete,
            ),

            SizedBox(height: 30.h),
          ],
        ),
      ),
    );
  }
}
