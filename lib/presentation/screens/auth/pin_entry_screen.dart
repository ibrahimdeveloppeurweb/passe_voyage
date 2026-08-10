import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../widgets/custom_numpad.dart';
import '../../../config/routes.dart';
import '../../../core/theme/app_colors.dart';

class PinEntryScreen extends StatefulWidget {
  final String phoneNumber;
  
  const PinEntryScreen({Key? key, required this.phoneNumber}) : super(key: key);

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  String _pinCode = '';

  void _onKeyPressed(String value) {
    if (_pinCode.length < 4) {
      setState(() {
        _pinCode += value;
      });
      
      // Auto-validate and navigate when 4 digits are entered
      if (_pinCode.length == 4) {
        Future.delayed(const Duration(milliseconds: 200), () {
          Navigator.pushNamed(
            context,
            AppRoutes.personalInfo,
          );
        });
      }
    }
  }

  void _onDelete() {
    if (_pinCode.isNotEmpty) {
      setState(() {
        _pinCode = _pinCode.substring(0, _pinCode.length - 1);
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
            
            // Lock Icon
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary, // Dark blue from screenshot
                  width: 3.w,
                ),
              ),
              child: Icon(
                Icons.lock,
                color: AppColors.primary,
                size: 28.w,
              ),
            ),
            
            SizedBox(height: 30.h),
            
            // Text Message
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.0.w),
              child: Text(
                'Entrez votre code secret pour le\ncompte ${widget.phoneNumber}',
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
            
            // 4 Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _pinCode.length;
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 12.w),
                  width: 14.w,
                  height: 14.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? AppColors.primary : AppColors.primary.withOpacity(0.2), // Light blue for empty, primary for filled
                  ),
                );
              }),
            ),
            
            const Spacer(),
            
            // Custom Numpad with "OUBLIÉ?"
            CustomNumpad(
              onKeyPressed: _onKeyPressed,
              onDelete: _onDelete,
              leftActionKey: InkWell(
                onTap: () {
                  // TODO: Implement forgot PIN logic
                },
                borderRadius: BorderRadius.circular(40.r),
                child: Container(
                  width: 80.w,
                  height: 80.h,
                  alignment: Alignment.center,
                  child: Text(
                    'OUBLIÉ?',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 30.h),
          ],
        ),
      ),
    );
  }
}
