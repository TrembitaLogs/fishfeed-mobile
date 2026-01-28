import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/presentation/widgets/auth/password_field.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  Widget buildGoldenWidget(Widget child, {bool darkMode = false}) {
    return MaterialApp(
      theme: darkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 350,
            child: Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        ),
      ),
    );
  }

  group('PasswordField Golden Tests', () {
    testWidgets('hidden state - light mode', (tester) async {
      final controller = TextEditingController(text: 'secretpassword');

      await tester.pumpWidget(
        buildGoldenWidget(
          PasswordField(controller: controller, label: 'Password'),
          darkMode: false,
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/password_field_hidden_light.png'),
      );
    });

    testWidgets('visible state - light mode', (tester) async {
      final controller = TextEditingController(text: 'secretpassword');

      await tester.pumpWidget(
        buildGoldenWidget(
          PasswordField(controller: controller, label: 'Password'),
          darkMode: false,
        ),
      );
      await tester.pumpAndSettle();

      // Toggle visibility
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/password_field_visible_light.png'),
      );
    });

    testWidgets('hidden state - dark mode', (tester) async {
      final controller = TextEditingController(text: 'secretpassword');

      await tester.pumpWidget(
        buildGoldenWidget(
          PasswordField(controller: controller, label: 'Password'),
          darkMode: true,
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/password_field_hidden_dark.png'),
      );
    });

    testWidgets('visible state - dark mode', (tester) async {
      final controller = TextEditingController(text: 'secretpassword');

      await tester.pumpWidget(
        buildGoldenWidget(
          PasswordField(controller: controller, label: 'Password'),
          darkMode: true,
        ),
      );
      await tester.pumpAndSettle();

      // Toggle visibility
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/password_field_visible_dark.png'),
      );
    });

    testWidgets('error state - light mode', (tester) async {
      final controller = TextEditingController(text: 'short');

      await tester.pumpWidget(
        buildGoldenWidget(
          PasswordField(
            controller: controller,
            label: 'Password',
            errorText: 'Password must be at least 8 characters',
          ),
          darkMode: false,
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/password_field_error_light.png'),
      );
    });

    testWidgets('error state - dark mode', (tester) async {
      final controller = TextEditingController(text: 'short');

      await tester.pumpWidget(
        buildGoldenWidget(
          PasswordField(
            controller: controller,
            label: 'Password',
            errorText: 'Password must be at least 8 characters',
          ),
          darkMode: true,
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/password_field_error_dark.png'),
      );
    });
  });
}
