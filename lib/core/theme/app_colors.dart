import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF194474); // Bleu "PASS" (Bleu foncé du logo)
  static const Color secondary = Color(0xFF4E9D50); // Vert "VOYAGE" (Vert du logo)
  static const Color tertiary = Color(0xFFED7E22); // Orange (Courbe du bas du logo)
  static const Color background = Color(0xFFF2F7F5); // Blanc cassé/vert très léger (comme capture1)


  static const Color surface = Color(0xFFF7F7F7);
  static const Color textPrimary = Color(0xFF1E1E1E);
  static const Color textSecondary = Color(0xFF757575);
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);
  
  static const Color numpadKeyBackground = Colors.transparent;
  static const Color numpadKeyText = Color(0xFF1E1E1E);
  static const Color buttonText = Colors.white;

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF265A96)], // Dark blue to a slightly lighter blue
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient brandGradient = LinearGradient(
    colors: [primary, secondary], // Blue to Green from logo
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
