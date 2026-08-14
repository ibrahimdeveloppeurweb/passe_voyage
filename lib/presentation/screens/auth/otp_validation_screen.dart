import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../widgets/custom_numpad.dart';
import '../../../config/routes.dart';
import '../../../core/theme/app_colors.dart';

class OtpValidationScreen extends StatefulWidget {
  final String phoneNumber;
  
  const OtpValidationScreen({Key? key, required this.phoneNumber}) : super(key: key);

  @override
  State<OtpValidationScreen> createState() => _OtpValidationScreenState();
}

class _OtpValidationScreenState extends State<OtpValidationScreen> {
  String _otpCode = '';

  void _onKeyPressed(String value) {
    if (_otpCode.length < 4) {
      setState(() {
        _otpCode += value;
      });
      
      // Auto-validate and navigate when 4 digits are entered
      if (_otpCode.length == 4) {
        Future.delayed(const Duration(milliseconds: 200), () {
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.pinEntry,
            arguments: {'phoneNumber': widget.phoneNumber},
          );
        });
      }
    }
  }

  void _onDelete() {
    if (_otpCode.isNotEmpty) {
      setState(() {
        _otpCode = _otpCode.substring(0, _otpCode.length - 1);
      });
    }
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
            
            // Icon Bubble
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
            
            // Text Message
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
            
            // 4 Digit Slots
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
            
            const Spacer(),
            
            // Resend SMS Button
            TextButton(
              onPressed: () {
                // TODO: Implement resend logic
              },
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
            
            // Custom Numpad
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
