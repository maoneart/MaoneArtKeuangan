import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Royal Blue Theme Tokens (BuildWithAngga / www/Keuangan Concept)
  static const Color blueDark = Color(0xFF002680);
  static const Color bluePrimary = Color(0xFF0047CC);
  static const Color blueAccent = Color(0xFF0056FB);
  static const Color blueLight = Color(0xFFEEF4FF);
  static const Color blueSoft = Color(0xFFF4F8FF);

  // App Background & Surface Colors
  static const Color bgApp = Color(0xFFF6F8FC);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Text Tokens
  static const Color textDark = Color(0xFF0F172A);
  static const Color textBody = Color(0xFF334155);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);

  // Status & Financial Indicators
  static const Color greenMain = Color(0xFF059669);
  static const Color greenSoft = Color(0xFFD1FAE5);

  static const Color redMain = Color(0xFFDC2626);
  static const Color redSoft = Color(0xFFFEE2E2);

  static const Color cyanMain = Color(0xFF0284C7);
  static const Color cyanSoft = Color(0xFFE0F2FE);

  static const Color amberMain = Color(0xFFD97706);
  static const Color amberSoft = Color(0xFFFEF3C7);

  static const Color purpleMain = Color(0xFF7C3AED);
  static const Color purpleSoft = Color(0xFFEDE9FE);

  // Header Royal Blue Gradient
  static const LinearGradient royalBlueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF002680),
      Color(0xFF0047CC),
      Color(0xFF0056FB),
    ],
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgApp,
      primaryColor: bluePrimary,
      colorScheme: const ColorScheme.light(
        primary: bluePrimary,
        secondary: blueAccent,
        surface: cardBg,
        error: redMain,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: cardBg,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
        iconTheme: const IconThemeData(color: textDark),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: textDark,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardTheme(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: borderLight, width: 1),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardBg,
        selectedItemColor: bluePrimary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
