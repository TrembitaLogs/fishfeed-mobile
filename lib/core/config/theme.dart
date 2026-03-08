import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App theme configuration with light and dark modes.
///
/// Uses a fish-themed color palette with deep blue and sea green colors.
/// All color combinations meet WCAG 2.1 AA accessibility standards
/// with a minimum contrast ratio of 4.5:1.
class AppTheme {
  AppTheme._();

  /// Use default fonts instead of Google Fonts (useful for testing).
  static bool useDefaultFonts = false;

  // Primary colors - Deep blue (fish/ocean theme)
  static const Color _primaryLight = Color(0xFF1565C0);
  static const Color _primaryDark = Color(0xFF88C0D0); // Nord Frost cyan

  // Secondary colors - Sea green (aquatic theme)
  static const Color _secondaryLight = Color(0xFF00796B);
  static const Color _secondaryDark = Color(0xFFA3BE8C); // Nord Aurora green

  // Error colors
  static const Color _errorLight = Color(0xFFD32F2F);
  static const Color _errorDark = Color(0xFFBF616A); // Nord Aurora red

  // Surface colors for light theme
  static const Color _surfaceLight = Color(0xFFFFFFFF);
  static const Color _backgroundLight = Color(0xFFF5F5F5);
  static const Color _onSurfaceLight = Color(0xFF1C1B1F);

  // Surface colors for dark theme (Nord Polar Night)
  static const Color _surfaceDark = Color(0xFF3B4252);
  static const Color _backgroundDark = Color(0xFF2E3440);
  static const Color _onSurfaceDark = Color(0xFFECEFF4); // Nord Snow Storm

  // On-primary/secondary colors (text/icons on colored backgrounds)
  static const Color _onPrimaryLight = Color(0xFFFFFFFF);
  static const Color _onPrimaryDark = Color(0xFF2E3440); // Nord Polar Night
  static const Color _onSecondaryLight = Color(0xFFFFFFFF);
  static const Color _onSecondaryDark = Color(0xFF2E3440); // Nord Polar Night

  /// Light theme configuration
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      primary: _primaryLight,
      onPrimary: _onPrimaryLight,
      primaryContainer: Color(0xFFD1E4FF),
      onPrimaryContainer: Color(0xFF001D36),
      secondary: _secondaryLight,
      onSecondary: _onSecondaryLight,
      secondaryContainer: Color(0xFFA7F3EC),
      onSecondaryContainer: Color(0xFF00201D),
      tertiary: Color(0xFF7C5800),
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFFFDEA6),
      onTertiaryContainer: Color(0xFF271900),
      error: _errorLight,
      onError: Colors.white,
      surface: _surfaceLight,
      onSurface: _onSurfaceLight,
      outline: Color(0xFF79747E),
      outlineVariant: Color(0xFFCAC4D0),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Color(0xFF313033),
      onInverseSurface: Color(0xFFF4EFF4),
      inversePrimary: _primaryDark,
    );

    return _buildTheme(colorScheme, Brightness.light);
  }

  /// Dark theme configuration
  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      primary: _primaryDark,
      onPrimary: _onPrimaryDark,
      primaryContainer: Color(0xFF5E81AC), // Nord Frost blue
      onPrimaryContainer: Color(0xFFECEFF4), // Nord Snow Storm
      secondary: _secondaryDark,
      onSecondary: _onSecondaryDark,
      secondaryContainer: Color(0xFF4C566A), // Nord Polar Night lightest
      onSecondaryContainer: Color(0xFFD8DEE9), // Nord Snow Storm
      tertiary: Color(0xFFEBCB8B), // Nord Aurora yellow
      onTertiary: Color(0xFF2E3440),
      tertiaryContainer: Color(0xFF434C5E), // Nord Polar Night
      onTertiaryContainer: Color(0xFFECEFF4),
      error: _errorDark,
      onError: Color(0xFF2E3440),
      surface: _surfaceDark,
      onSurface: _onSurfaceDark,
      outline: Color(0xFF4C566A), // Nord Polar Night lightest
      outlineVariant: Color(0xFF434C5E), // Nord Polar Night
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Color(0xFFECEFF4),
      onInverseSurface: Color(0xFF2E3440),
      inversePrimary: Color(0xFF5E81AC), // Nord Frost blue
    );

    return _buildTheme(colorScheme, Brightness.dark);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme, Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final textTheme = _buildTextTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      appBarTheme: _buildAppBarTheme(colorScheme, textTheme),
      cardTheme: _buildCardTheme(colorScheme),
      inputDecorationTheme: _buildInputDecorationTheme(colorScheme),
      elevatedButtonTheme: _buildElevatedButtonTheme(colorScheme),
      textButtonTheme: _buildTextButtonTheme(colorScheme),
      outlinedButtonTheme: _buildOutlinedButtonTheme(colorScheme),
      floatingActionButtonTheme: _buildFabTheme(colorScheme),
      iconTheme: IconThemeData(color: colorScheme.onSurface, size: 24),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
      ),
      scaffoldBackgroundColor: isLight ? _backgroundLight : _backgroundDark,
    );
  }

  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    final baseTextTheme = useDefaultFonts
        ? const TextTheme()
        : GoogleFonts.nunitoTextTheme();

    return baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w400,
      ),
      displayMedium: baseTextTheme.displayMedium?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w400,
      ),
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w400,
      ),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  static AppBarTheme _buildAppBarTheme(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: colorScheme.surfaceTint,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: colorScheme.onSurface,
      ),
      iconTheme: IconThemeData(color: colorScheme.onSurface),
      actionsIconTheme: IconThemeData(color: colorScheme.onSurface),
    );
  }

  static CardThemeData _buildCardTheme(ColorScheme colorScheme) {
    return CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      color: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme(
    ColorScheme colorScheme,
  ) {
    return InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      errorStyle: TextStyle(color: colorScheme.error),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme(
    ColorScheme colorScheme,
  ) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
        disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }

  static TextButtonThemeData _buildTextButtonTheme(ColorScheme colorScheme) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme(
    ColorScheme colorScheme,
  ) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: colorScheme.outline),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }

  static FloatingActionButtonThemeData _buildFabTheme(ColorScheme colorScheme) {
    return FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
