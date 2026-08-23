import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Mutable palette so Appearance (dark/light) can switch at runtime.
abstract final class AppColors {
  static bool isDark = true;

  static Color bg = _dBg;
  static Color panel = _dPanel;
  static Color card = _dCard;
  static Color cardAlt = _dCardAlt;
  static Color line = _dLine;
  static Color text = _dText;
  static Color muted = _dMuted;

  static const accent = Color(0xFF3B82F6);
  static const accentSoft = Color(0xFF2563EB);
  static const green = Color(0xFF22C55E);
  static const red = Color(0xFFEF4444);
  static const amber = Color(0xFFF59E0B);
  static const purple = Color(0xFFA855F7);
  static const cyan = Color(0xFF06B6D4);

  static const _dBg = Color(0xFF0B1220);
  static const _dPanel = Color(0xFF111827);
  static const _dCard = Color(0xFF1A2332);
  static const _dCardAlt = Color(0xFF1F2A3C);
  static const _dLine = Color(0xFF2A3648);
  static const _dText = Color(0xFFF8FAFC);
  static const _dMuted = Color(0xFF94A3B8);

  static const _lBg = Color(0xFFF1F5F9);
  static const _lPanel = Color(0xFFFFFFFF);
  static const _lCard = Color(0xFFFFFFFF);
  static const _lCardAlt = Color(0xFFF8FAFC);
  static const _lLine = Color(0xFFD0D7E2);
  static const _lText = Color(0xFF0F172A);
  static const _lMuted = Color(0xFF64748B);

  static void apply({required bool dark}) {
    isDark = dark;
    if (dark) {
      bg = _dBg;
      panel = _dPanel;
      card = _dCard;
      cardAlt = _dCardAlt;
      line = _dLine;
      text = _dText;
      muted = _dMuted;
    } else {
      bg = _lBg;
      panel = _lPanel;
      card = _lCard;
      cardAlt = _lCardAlt;
      line = _lLine;
      text = _lText;
      muted = _lMuted;
    }
  }
}

ThemeData buildRetailTheme({required bool dark}) {
  AppColors.apply(dark: dark);
  final brightness = dark ? Brightness.dark : Brightness.light;
  final base = GoogleFonts.interTextTheme(
    dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: AppColors.accent,
      onPrimary: Colors.white,
      secondary: AppColors.cyan,
      onSecondary: Colors.white,
      surface: AppColors.panel,
      onSurface: AppColors.text,
      error: AppColors.red,
      onError: Colors.white,
    ),
    textTheme: base.copyWith(
      headlineLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.text),
      headlineMedium: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.text),
      headlineSmall: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.text),
      titleLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text),
      titleMedium: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text),
      bodyLarge: GoogleFonts.inter(fontSize: 15, color: AppColors.muted),
      bodyMedium: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
      labelLarge: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        side: BorderSide(color: AppColors.line),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.accent),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.selected)) return Colors.white;
        return AppColors.muted;
      }),
      trackColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.selected)) return AppColors.accent;
        return AppColors.line;
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
      hintStyle: GoogleFonts.inter(color: AppColors.muted),
      labelStyle: GoogleFonts.inter(color: AppColors.muted),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.panel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.cardAlt,
      contentTextStyle: GoogleFonts.inter(color: AppColors.text, fontWeight: FontWeight.w600),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    dividerColor: AppColors.line,
    dataTableTheme: DataTableThemeData(
      headingRowColor: WidgetStatePropertyAll(AppColors.card),
      dataRowColor: WidgetStatePropertyAll(AppColors.panel),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(AppColors.panel),
      ),
    ),
  );
}

Color parseHexColor(String hex, {Color fallback = AppColors.accent}) {
  var value = hex.replaceAll('#', '').trim();
  if (value.length == 6) value = 'FF$value';
  final parsed = int.tryParse(value, radix: 16);
  if (parsed == null) return fallback;
  return Color(parsed);
}
