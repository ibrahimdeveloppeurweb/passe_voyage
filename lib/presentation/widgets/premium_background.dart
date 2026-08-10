import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';
import '../../core/theme/app_colors.dart';

class PremiumBackground extends StatelessWidget {
  final Widget child;

  const PremiumBackground({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.surface, // Light premium background
      child: Stack(
        children: [
          // Background Glow Effects
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300.w,
              height: 300.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.1),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          // Content
          Positioned.fill(
            child: child,
          ),
        ],
      ),
    );
  }
}
