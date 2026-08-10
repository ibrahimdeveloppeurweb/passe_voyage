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
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.primary, // Purple color from screenshot
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.chat_bubble,
                color: AppColors.background,
                size: 24.w,
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
                  width: 40.w,
                  margin: EdgeInsets.symmetric(horizontal: 8.w),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isActive ? AppColors.primary : AppColors.textSecondary,
                        width: isActive ? 2.0 : 1.5,
                      ),
                    ),
                  ),
                  alignment: Alignment.center,
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: isFilled
                      ? Text(
                          _otpCode[index],
                          style: TextStyle(
                            fontSize: 32.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        )
                      : isActive
                          ? Container(
                              width: 2.w,
                              height: 32.h,
                              color: AppColors.primary,
                            )
                          : SizedBox(height: 32.h),
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
