import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/presentation/widgets/common/app_button.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('AppButton', () {
    group('primary button', () {
      testWidgets('renders correctly with label', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            AppButton(
              label: 'Test Button',
              onPressed: () {},
            ),
          ),
        );

        expect(find.text('Test Button'), findsOneWidget);
        expect(find.byType(ElevatedButton), findsOneWidget);
      });

      testWidgets('calls onPressed when tapped', (tester) async {
        var pressed = false;

        await tester.pumpWidget(
          buildTestWidget(
            AppButton(
              label: 'Test',
              onPressed: () => pressed = true,
            ),
          ),
        );

        await tester.tap(find.byType(ElevatedButton));
        expect(pressed, isTrue);
      });

      testWidgets('is disabled when onPressed is null', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            const AppButton(
              label: 'Disabled',
              onPressed: null,
            ),
          ),
        );

        final button = tester.widget<ElevatedButton>(
          find.byType(ElevatedButton),
        );
        expect(button.onPressed, isNull);
      });

      testWidgets('shows loading indicator when isLoading is true',
          (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            AppButton(
              label: 'Loading',
              onPressed: () {},
              isLoading: true,
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Loading'), findsNothing);
      });

      testWidgets('is disabled when loading', (tester) async {
        var pressed = false;

        await tester.pumpWidget(
          buildTestWidget(
            AppButton(
              label: 'Loading',
              onPressed: () => pressed = true,
              isLoading: true,
            ),
          ),
        );

        await tester.tap(find.byType(ElevatedButton));
        expect(pressed, isFalse);
      });

      testWidgets('renders with icon', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            AppButton(
              label: 'With Icon',
              onPressed: () {},
              icon: Icons.add,
            ),
          ),
        );

        expect(find.byIcon(Icons.add), findsOneWidget);
        expect(find.text('With Icon'), findsOneWidget);
      });
    });

    group('secondary button', () {
      testWidgets('renders as OutlinedButton', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            AppButton(
              label: 'Secondary',
              onPressed: () {},
              buttonType: AppButtonType.secondary,
            ),
          ),
        );

        expect(find.byType(OutlinedButton), findsOneWidget);
        expect(find.text('Secondary'), findsOneWidget);
      });

      testWidgets('is disabled when onPressed is null', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            const AppButton(
              label: 'Disabled Secondary',
              onPressed: null,
              buttonType: AppButtonType.secondary,
            ),
          ),
        );

        final button = tester.widget<OutlinedButton>(
          find.byType(OutlinedButton),
        );
        expect(button.onPressed, isNull);
      });

      testWidgets('shows loading indicator when isLoading is true',
          (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            AppButton(
              label: 'Loading',
              onPressed: () {},
              buttonType: AppButtonType.secondary,
              isLoading: true,
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('text button', () {
      testWidgets('renders as TextButton', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            AppButton(
              label: 'Text Button',
              onPressed: () {},
              buttonType: AppButtonType.text,
            ),
          ),
        );

        expect(find.byType(TextButton), findsOneWidget);
        expect(find.text('Text Button'), findsOneWidget);
      });

      testWidgets('is disabled when onPressed is null', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            const AppButton(
              label: 'Disabled Text',
              onPressed: null,
              buttonType: AppButtonType.text,
            ),
          ),
        );

        final button = tester.widget<TextButton>(
          find.byType(TextButton),
        );
        expect(button.onPressed, isNull);
      });

      testWidgets('shows loading indicator when isLoading is true',
          (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            AppButton(
              label: 'Loading',
              onPressed: () {},
              buttonType: AppButtonType.text,
              isLoading: true,
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });
  });
}
