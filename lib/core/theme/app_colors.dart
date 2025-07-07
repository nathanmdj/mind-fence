import 'package:flutter/material.dart';

class AppColors {
  // Primary brand colors
  static const Color primary = Color(0xFF6366F1); // Indigo-500
  static const Color primaryVariant = Color(0xFF4F46E5); // Indigo-600
  static const Color onPrimary = Color(0xFFFFFFFF);
  
  // Secondary colors
  static const Color secondary = Color(0xFF10B981); // Emerald-500
  static const Color secondaryVariant = Color(0xFF059669); // Emerald-600
  static const Color onSecondary = Color(0xFFFFFFFF);
  
  // Error colors
  static const Color error = Color(0xFFEF4444); // Red-500
  static const Color errorVariant = Color(0xFFDC2626); // Red-600
  static const Color onError = Color(0xFFFFFFFF);
  
  // Success colors
  static const Color success = Color(0xFF10B981); // Emerald-500
  static const Color onSuccess = Color(0xFFFFFFFF);
  
  // Warning colors
  static const Color warning = Color(0xFFF59E0B); // Amber-500
  static const Color onWarning = Color(0xFF000000);
  
  // Info colors
  static const Color info = Color(0xFF3B82F6); // Blue-500
  static const Color onInfo = Color(0xFFFFFFFF);
  
  // Light theme colors
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightOnBackground = Color(0xFF1F2937); // Gray-800
  static const Color lightSurface = Color(0xFFF9FAFB); // Gray-50
  static const Color lightOnSurface = Color(0xFF1F2937); // Gray-800
  
  // Dark theme colors
  static const Color darkBackground = Color(0xFF111827); // Gray-900
  static const Color darkOnBackground = Color(0xFFF9FAFB); // Gray-50
  static const Color darkSurface = Color(0xFF1F2937); // Gray-800
  static const Color darkOnSurface = Color(0xFFF9FAFB); // Gray-50
  
  // Neutral colors
  static const Color outline = Color(0xFFD1D5DB); // Gray-300
  static const Color outlineVariant = Color(0xFF9CA3AF); // Gray-400
  static const Color onSurfaceVariant = Color(0xFF6B7280); // Gray-500
  
  // Focus/blocking related colors
  static const Color focusActive = Color(0xFF10B981); // Emerald-500
  static const Color focusInactive = Color(0xFF6B7280); // Gray-500
  static const Color blockingActive = Color(0xFFEF4444); // Red-500
  static const Color blockingInactive = Color(0xFF9CA3AF); // Gray-400
  
  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryVariant],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [success, Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient warningGradient = LinearGradient(
    colors: [warning, Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient errorGradient = LinearGradient(
    colors: [error, errorVariant],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Shadow colors
  static const Color shadowColor = Color(0x1A000000);
  static const Color darkShadowColor = Color(0x40000000);
  
  // Opacity variations
  static Color primaryWithOpacity(double opacity) => primary.withOpacity(opacity);
  static Color secondaryWithOpacity(double opacity) => secondary.withOpacity(opacity);
  static Color errorWithOpacity(double opacity) => error.withOpacity(opacity);
  static Color successWithOpacity(double opacity) => success.withOpacity(opacity);
  static Color warningWithOpacity(double opacity) => warning.withOpacity(opacity);
  static Color infoWithOpacity(double opacity) => info.withOpacity(opacity);
}