import 'package:flutter/material.dart';

class AppColors {
  static const ink = Color(0xFF111827);
  static const muted = Color(0xFF64748B);
  static const line = Color(0xFFE5E7EB);
  static const soft = Color(0xFFF8FAFC);
  static const brand = Color(0xFF0891B2);
  static const brandDark = Color(0xFF0E7490);
  static const mint = Color(0xFF059669);
  static const amber = Color(0xFFD97706);
  static const rose = Color(0xFFE11D48);
}

class AppText {
  static const title = TextStyle(fontSize: 30, height: 1.04, fontWeight: FontWeight.w900, color: AppColors.ink);
  static const hero = TextStyle(fontSize: 33, height: .98, fontWeight: FontWeight.w900, color: Colors.white);
  static const section = TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.ink);
  static const value = TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink);
  static const label = TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.muted);
}

ThemeData buildSnapCleanTheme() {
  final base = ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: AppColors.brand));
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.soft,
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
      fontFamily: 'Inter',
      fontFamilyFallback: const ['Roboto', 'Arial'],
    ),
  );
}
