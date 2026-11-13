import 'package:flutter/material.dart';

/// Shared Menti surface, color and touch-target contract for every app route.
abstract final class MentiDesign {
  static const canvas = Color(0xFF0C0A10);
  static const surface = Color(0xFF21182B);
  static const orange = Color(0xFFFF9E2C);
  static const violet = Color(0xFFB58BE6);
  static const mint = Color(0xFF76E4B8);
  static const pagePadding = 16.0;
  static const sectionGap = 12.0;
  static final _buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  );
  static ThemeData get theme => ThemeData(
    brightness: Brightness.dark,
    fontFamilyFallback: const ['MentiEmoji'],
    scaffoldBackgroundColor: canvas,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: violet,
          brightness: Brightness.dark,
        ).copyWith(
          primary: const Color(0xFFFFC477),
          onPrimary: const Color(0xFF2C1A06),
          secondary: violet,
          surface: surface,
          onSurface: const Color(0xFFF0E8F3),
        ),
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.25,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, height: 1.45),
      bodySmall: TextStyle(fontSize: 12, height: 1.4),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: canvas,
      foregroundColor: Colors.white,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF3A2B46)),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF493552),
      thickness: 1,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surface,
      selectedColor: const Color(0xFF4B2959),
      side: const BorderSide(color: Color(0xFF60436C)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: violet,
      linearTrackColor: surface,
      linearMinHeight: 6,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF17111E),
      indicatorColor: const Color(0xFF4B2959),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, color: Colors.white),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        shape: _buttonShape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: _buttonShape,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF60436C)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF493552)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: orange, width: 1.6),
      ),
    ),
  );
}
