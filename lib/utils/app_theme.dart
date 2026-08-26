import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Color Palette (Modern Dark & Cyber Obsidian)
  static const Color bgDark = Color(0xFF0A0E1A);
  static const Color bgCard = Color(0xFF131B2E);
  static const Color bgSurface = Color(0xFF1E293B);
  static const Color bgInput = Color(0xFF0F172A);

  // Accent Colors
  static const Color accentEmerald = Color(0xFF10B981); // Pemasukan & Lunas
  static const Color accentRose = Color(0xFFF43F5E);    // Pengeluaran & Hutang
  static const Color accentCyan = Color(0xFF06B6D4);    // Saldo & Tabungan
  static const Color accentAmber = Color(0xFFF59E0B);   // Piutang & Peringatan
  static const Color accentPurple = Color(0xFF8B5CF6);  // Investasi & Kategori

  // Text Colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Border Colors
  static Color borderGlass = Colors.white.withValues(alpha: 0.1);
  static Color borderHighlight = Colors.white.withValues(alpha: 0.2);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      primaryColor: accentEmerald,
      colorScheme: const ColorScheme.dark(
        primary: accentEmerald,
        secondary: accentCyan,
        surface: bgCard,
        error: accentRose,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: bgDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardTheme(
        color: bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderGlass),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgCard,
        selectedItemColor: accentEmerald,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
      ),
    );
  }
}
