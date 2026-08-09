import 'package:flutter/material.dart';
import 'dart:ui';

class PremiumBackground extends StatelessWidget {
  final Widget child;

  const PremiumBackground({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF4F7FA), // Light premium background
      child: Stack(
        children: [
          // Background Glow Effects
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00C6F0).withOpacity(0.1),
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
