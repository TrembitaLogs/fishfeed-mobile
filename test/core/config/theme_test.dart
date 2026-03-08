import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fishfeed/core/config/theme.dart';

void main() {
  setUpAll(() {
    // Disable Google Fonts HTTP fetching in tests
    GoogleFonts.config.allowRuntimeFetching = false;
    // Use default fonts for testing
    AppTheme.useDefaultFonts = true;
  });

  tearDownAll(() {
    // Reset to default
    AppTheme.useDefaultFonts = false;
  });

  group('AppTheme', () {
    group('lightTheme', () {
      test('returns a valid ThemeData', () {
        final theme = AppTheme.lightTheme;

        expect(theme, isA<ThemeData>());
        expect(theme.brightness, Brightness.light);
        expect(theme.useMaterial3, true);
      });

      test('has correct primary color (deep blue)', () {
        final theme = AppTheme.lightTheme;

        expect(theme.colorScheme.primary, const Color(0xFF1565C0));
      });

      test('has correct secondary color (sea green)', () {
        final theme = AppTheme.lightTheme;

        expect(theme.colorScheme.secondary, const Color(0xFF00796B));
      });

      test('has white surface color', () {
        final theme = AppTheme.lightTheme;

        expect(theme.colorScheme.surface, const Color(0xFFFFFFFF));
      });

      test('has correct error color', () {
        final theme = AppTheme.lightTheme;

        expect(theme.colorScheme.error, const Color(0xFFD32F2F));
      });

      test('has correct on-primary color for accessibility', () {
        final theme = AppTheme.lightTheme;

        expect(theme.colorScheme.onPrimary, const Color(0xFFFFFFFF));
      });

      test('has correct on-secondary color for accessibility', () {
        final theme = AppTheme.lightTheme;

        expect(theme.colorScheme.onSecondary, const Color(0xFFFFFFFF));
      });
    });

    group('darkTheme', () {
      test('returns a valid ThemeData', () {
        final theme = AppTheme.darkTheme;

        expect(theme, isA<ThemeData>());
        expect(theme.brightness, Brightness.dark);
        expect(theme.useMaterial3, true);
      });

      test('has correct primary color (Nord Frost cyan for dark mode)', () {
        final theme = AppTheme.darkTheme;

        expect(theme.colorScheme.primary, const Color(0xFF88C0D0));
      });

      test('has correct secondary color (Nord Aurora green for dark mode)', () {
        final theme = AppTheme.darkTheme;

        expect(theme.colorScheme.secondary, const Color(0xFFA3BE8C));
      });

      test('has dark surface color (Nord Polar Night)', () {
        final theme = AppTheme.darkTheme;

        expect(theme.colorScheme.surface, const Color(0xFF3B4252));
      });

      test('has correct error color (Nord Aurora red)', () {
        final theme = AppTheme.darkTheme;

        expect(theme.colorScheme.error, const Color(0xFFBF616A));
      });
    });

    group('theme components', () {
      test('lightTheme has configured AppBarTheme', () {
        final theme = AppTheme.lightTheme;

        expect(theme.appBarTheme.elevation, 0);
        expect(theme.appBarTheme.backgroundColor, theme.colorScheme.surface);
      });

      test('darkTheme has configured AppBarTheme', () {
        final theme = AppTheme.darkTheme;

        expect(theme.appBarTheme.elevation, 0);
        expect(theme.appBarTheme.backgroundColor, theme.colorScheme.surface);
      });

      test('lightTheme has configured CardTheme', () {
        final theme = AppTheme.lightTheme;

        expect(theme.cardTheme.elevation, 0);
        expect(theme.cardTheme.shape, isA<RoundedRectangleBorder>());
      });

      test('darkTheme has configured CardTheme', () {
        final theme = AppTheme.darkTheme;

        expect(theme.cardTheme.elevation, 0);
        expect(theme.cardTheme.shape, isA<RoundedRectangleBorder>());
      });

      test('lightTheme has configured InputDecorationTheme', () {
        final theme = AppTheme.lightTheme;

        expect(theme.inputDecorationTheme.filled, true);
        expect(theme.inputDecorationTheme.border, isA<OutlineInputBorder>());
      });

      test('darkTheme has configured InputDecorationTheme', () {
        final theme = AppTheme.darkTheme;

        expect(theme.inputDecorationTheme.filled, true);
        expect(theme.inputDecorationTheme.border, isA<OutlineInputBorder>());
      });

      test('lightTheme has configured ElevatedButtonTheme', () {
        final theme = AppTheme.lightTheme;

        expect(theme.elevatedButtonTheme.style, isNotNull);
      });

      test('darkTheme has configured ElevatedButtonTheme', () {
        final theme = AppTheme.darkTheme;

        expect(theme.elevatedButtonTheme.style, isNotNull);
      });
    });

    group('widget integration', () {
      testWidgets('lightTheme applies correctly to MaterialApp', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(body: Text('Test')),
          ),
        );

        final context = tester.element(find.byType(Scaffold));
        final theme = Theme.of(context);

        expect(theme.brightness, Brightness.light);
        expect(theme.colorScheme.primary, const Color(0xFF1565C0));
      });

      testWidgets('darkTheme applies correctly to MaterialApp', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(body: Text('Test')),
          ),
        );

        final context = tester.element(find.byType(Scaffold));
        final theme = Theme.of(context);

        expect(theme.brightness, Brightness.dark);
        expect(theme.colorScheme.primary, const Color(0xFF88C0D0));
      });

      testWidgets('theme switching works correctly', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            home: const Scaffold(body: Text('Test')),
          ),
        );

        var context = tester.element(find.byType(Scaffold));
        var theme = Theme.of(context);
        expect(theme.brightness, Brightness.light);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: const Scaffold(body: Text('Test')),
          ),
        );
        await tester.pumpAndSettle();

        context = tester.element(find.byType(Scaffold));
        theme = Theme.of(context);
        expect(theme.brightness, Brightness.dark);
      });
    });

    group('accessibility - contrast ratios', () {
      test('light theme primary on surface has sufficient contrast', () {
        final theme = AppTheme.lightTheme;
        final contrastRatio = _calculateContrastRatio(
          theme.colorScheme.primary,
          theme.colorScheme.surface,
        );
        // WCAG AA requires 4.5:1 for normal text
        expect(contrastRatio, greaterThanOrEqualTo(4.5));
      });

      test('light theme onPrimary on primary has sufficient contrast', () {
        final theme = AppTheme.lightTheme;
        final contrastRatio = _calculateContrastRatio(
          theme.colorScheme.onPrimary,
          theme.colorScheme.primary,
        );
        expect(contrastRatio, greaterThanOrEqualTo(4.5));
      });

      test('light theme onSecondary on secondary has sufficient contrast', () {
        final theme = AppTheme.lightTheme;
        final contrastRatio = _calculateContrastRatio(
          theme.colorScheme.onSecondary,
          theme.colorScheme.secondary,
        );
        expect(contrastRatio, greaterThanOrEqualTo(4.5));
      });

      test('light theme onSurface on surface has sufficient contrast', () {
        final theme = AppTheme.lightTheme;
        final contrastRatio = _calculateContrastRatio(
          theme.colorScheme.onSurface,
          theme.colorScheme.surface,
        );
        expect(contrastRatio, greaterThanOrEqualTo(4.5));
      });

      test('dark theme onPrimary on primary has sufficient contrast', () {
        final theme = AppTheme.darkTheme;
        final contrastRatio = _calculateContrastRatio(
          theme.colorScheme.onPrimary,
          theme.colorScheme.primary,
        );
        expect(contrastRatio, greaterThanOrEqualTo(4.5));
      });

      test('dark theme onSecondary on secondary has sufficient contrast', () {
        final theme = AppTheme.darkTheme;
        final contrastRatio = _calculateContrastRatio(
          theme.colorScheme.onSecondary,
          theme.colorScheme.secondary,
        );
        expect(contrastRatio, greaterThanOrEqualTo(4.5));
      });

      test('dark theme onSurface on surface has sufficient contrast', () {
        final theme = AppTheme.darkTheme;
        final contrastRatio = _calculateContrastRatio(
          theme.colorScheme.onSurface,
          theme.colorScheme.surface,
        );
        expect(contrastRatio, greaterThanOrEqualTo(4.5));
      });
    });
  });
}

/// Calculates the contrast ratio between two colors according to WCAG 2.1.
/// Returns a value between 1 and 21.
double _calculateContrastRatio(Color foreground, Color background) {
  final l1 = _calculateRelativeLuminance(foreground);
  final l2 = _calculateRelativeLuminance(background);

  final lighter = l1 > l2 ? l1 : l2;
  final darker = l1 > l2 ? l2 : l1;

  return (lighter + 0.05) / (darker + 0.05);
}

/// Calculates the relative luminance of a color according to WCAG 2.1.
double _calculateRelativeLuminance(Color color) {
  final r = _linearize(color.r);
  final g = _linearize(color.g);
  final b = _linearize(color.b);

  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// Linearizes an sRGB color channel value.
double _linearize(double value) {
  if (value <= 0.03928) {
    return value / 12.92;
  }
  return math.pow((value + 0.055) / 1.055, 2.4).toDouble();
}
