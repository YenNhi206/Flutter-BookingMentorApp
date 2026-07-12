import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand palette lifted from the ProInterview reference project
/// (frontend/src/styles/brand.css): purple + lime, black text, soft
/// rounded cards.
class AppTheme {
  static const Color primary = Color(0xFF8037F4); // --pi-purple
  static const Color primarySoft = Color(0x1F8037F4); // --pi-purple-soft
  static const Color accentLime = Color(0xFF93F72B); // --pi-lime
  static const Color accentLimeSoft = Color(0x2493F72B); // --pi-lime-soft
  static const Color deepGreen = Color(0xFF28552A); // --pi-green-dark
  static const Color ink = Color(0xFF000000);
  static const Color background = Color(0xFFF5F4F8); // near-white lavender

  static ThemeData get light {
    final base = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      secondary: accentLime,
      onSecondary: ink,
    );
    final textTheme = GoogleFonts.lexendTextTheme().apply(
      bodyColor: ink,
      displayColor: ink,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      textTheme: textTheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: ink,
        titleTextStyle: GoogleFonts.lexend(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: GoogleFonts.lexend(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: GoogleFonts.lexend(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primarySoft,
        labelStyle: const TextStyle(color: primary, fontWeight: FontWeight.w600),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: primarySoft,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.lexend(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? primary : Colors.black54,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? primary : Colors.black54);
        }),
      ),
    );
  }
}
