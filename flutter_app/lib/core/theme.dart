import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Premium Color Palette
  static const Color deepNavy = Color(0xFF0F172A);
  static const Color trustBlue = Color(0xFF2563EB); // More vibrant blue
  static const Color neonBlue = Color(0xFF38BDF8); // For accents
  static const Color slate = Color(0xFF64748B);
  static const Color background = Color(0xFFF8FAFC);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF10B981);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: trustBlue,
        primary: trustBlue,
        secondary: deepNavy,
        surface: Colors.white,
        background: background,
        error: errorRed,
        onPrimary: Colors.white,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.outfitTextTheme(), // More modern than Inter
      
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: deepNavy, size: 24),
        titleTextStyle: TextStyle(
          color: deepNavy,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: deepNavy,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 60),
          elevation: 2,
          shadowColor: deepNavy.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ).copyWith(
          overlayColor: MaterialStateProperty.all(Colors.white.withOpacity(0.1)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: trustBlue, width: 2),
        ),
        hintStyle: const TextStyle(color: slate, fontSize: 14),
      ),
    );
  }
}
