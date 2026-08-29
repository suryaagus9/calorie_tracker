import 'package:flutter/material.dart';

class AppTheme {
  // Palet Warna Dasar
  static const Color brandPrimary = Color(0xFF22C55E);
  static const Color brandLight = Color(0xFFDCFCE7);
  static const Color brandDark = Color(0xFF16A34A);

  // Palet Light Mode
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);

  // Palet Dark Mode (Baru)
  static const Color bgDark = Color(0xFF0F172A); // slate-900
  static const Color cardDark = Color(0xFF1E293B); // slate-800
  static const Color textLight = Color(0xFFF8FAFC); // slate-50
  static const Color textMutedDark = Color(0xFF94A3B8); // slate-400

  // Konfigurasi Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgLight,
      primaryColor: brandPrimary,
      cardColor: Colors.white,
      dividerColor: Colors.grey.shade200,

      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textDark, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: textDark),
        bodyMedium: TextStyle(color: textMuted),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
      ),
    );
  }

  // Konfigurasi Dark Theme (Baru)
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      primaryColor: brandPrimary,
      cardColor: cardDark,
      dividerColor: Colors.grey.shade800,

      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textLight, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: textLight),
        bodyMedium: TextStyle(color: textMutedDark),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
      ),
    );
  }
}