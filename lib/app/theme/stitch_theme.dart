import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StitchTheme {
  static const Color background = Color(0xFFF5F5F3);
  static const Color surface = Color(0xFFF5F5F3);
  static const Color surfaceLow = Color(0xFFEDEDE9);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF1B263B);
  static const Color primaryContainer = Color(0xFF2A3B57);
  static const Color secondary = Color(0xFF606872);
  static const Color onSurface = Color(0xFF1E1E1E);
  static const Color outline = Color(0xFF7F7F78);
  static const Color jotterpadOrange = Color(0xFFFF9800);
  static const Color jotterpadOrangeSoft = Color(0xFFFFE0B2);

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryContainer,
      onPrimaryContainer: Color(0xFF9EADC5),
      secondary: secondary,
      onSecondary: Colors.white,
      tertiary: Color(0xFF38270A),
      onTertiary: Colors.white,
      surface: surface,
      onSurface: onSurface,
      error: Color(0xFFBA1A1A),
      onError: Colors.white,
      outline: outline,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme, scheme),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: jotterpadOrange,
        selectionColor: jotterpadOrangeSoft,
        selectionHandleColor: jotterpadOrange,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: onSurface,
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: primary, width: 1),
        ),
        hintStyle: GoogleFonts.manrope(color: outline),
        labelStyle: GoogleFonts.manrope(color: secondary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: primary,
        contentTextStyle: GoogleFonts.manrope(color: Colors.white),
      ),
      dividerTheme: const DividerThemeData(space: 1, thickness: 0.6),
    );
  }

  static TextTheme _textTheme(TextTheme base, ColorScheme scheme) {
    final serif = GoogleFonts.loraTextTheme(base);
    final sans = GoogleFonts.manropeTextTheme(base);

    return serif.copyWith(
      displayLarge: serif.displayLarge?.copyWith(color: scheme.onSurface),
      displayMedium: serif.displayMedium?.copyWith(color: scheme.onSurface),
      displaySmall: serif.displaySmall?.copyWith(color: scheme.onSurface),
      headlineLarge: serif.headlineLarge?.copyWith(color: scheme.onSurface),
      headlineMedium: serif.headlineMedium?.copyWith(color: scheme.onSurface),
      headlineSmall: serif.headlineSmall?.copyWith(color: scheme.onSurface),
      titleLarge: serif.titleLarge?.copyWith(color: scheme.onSurface),
      titleMedium: serif.titleMedium?.copyWith(color: scheme.onSurface),
      titleSmall: serif.titleSmall?.copyWith(color: scheme.onSurface),
      bodyLarge: serif.bodyLarge?.copyWith(
        color: scheme.onSurface,
        fontSize: 16,
        height: 1.6,
      ),
      bodyMedium: serif.bodyMedium?.copyWith(
        color: scheme.onSurface,
        fontSize: 16,
        height: 1.6,
      ),
      bodySmall: sans.bodySmall?.copyWith(color: secondary),
      labelLarge: sans.labelLarge?.copyWith(color: scheme.onSurface),
      labelMedium: sans.labelMedium?.copyWith(color: secondary),
      labelSmall: sans.labelSmall?.copyWith(color: secondary),
    );
  }
}
