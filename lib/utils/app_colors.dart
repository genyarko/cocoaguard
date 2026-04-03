import 'package:flutter/material.dart';

/// CocoaGuard Color Palette
/// Colors inspired by cocoa farming and tropical environments
class AppColors {
  // Primary Colors
  static const Color onyx = Color(0xFF141115); // Dark background
  static const Color mauveShadow = Color(0xFF4c2b36); // Dark accent
  static const Color toffeeBrown = Color(0xFF8d6346); // Warm brown
  static const Color lemonLime = Color(0xFFddf45b); // Bright yellow-green
  static const Color chartreuse = Color(0xFFC6f91f); // Bright green

  // Semantic Colors
  static const Color success = chartreuse;
  static const Color warning = lemonLime;
  static const Color error = Color(0xFFEF4444); // Red
  static const Color info = Color(0xFF3B82F6); // Blue
  static const Color healthy = chartreuse;
  static const Color diseased = Color(0xFFEF4444);

  // Grayscale (derived from onyx)
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color mediumGray = Color(0xFF9CA3AF);
  static const Color darkGray = Color(0xFF374151);
  static const Color black = onyx;

  // Transparent variants
  static Color onyxTransparent(double opacity) =>
      onyx.withValues(alpha: opacity);
  static Color toffeeBrownTransparent(double opacity) =>
      toffeeBrown.withValues(alpha: opacity);
  static Color chartreuseTransparent(double opacity) =>
      chartreuse.withValues(alpha: opacity);

  // Disease-specific colors
  static const Map<String, Color> diseaseColors = {
    'healthy': chartreuse,
    'anthracnose': Color(0xFFFF9500), // Orange
    'cssvd': Color(0xFF8B0000), // Dark red
    'carmenta': Color(0xFFDC143C), // Crimson
    'moniliasis': Color(0xFF8B4513), // Saddle brown
    'phytophthora': Color(0xFF1C1C1C), // Very dark gray
    'witches_broom': Color(0xFF654321), // Dark brown
  };
}
