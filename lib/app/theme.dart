import 'package:flutter/material.dart';

class DespensaTheme {
  static const Color accent = Color(0xffcde600);

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      primaryColor: accent,
      fontFamily: 'Bricolage Grotesque',
      scaffoldBackgroundColor: Colors.black,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        onPrimary: Colors.black,
        surface: Colors.black,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.black,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
