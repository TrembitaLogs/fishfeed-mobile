import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/presentation/widgets/auth/oauth_button.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  Widget buildTestWidget(Widget child, {bool darkMode = false}) {
    return MaterialApp(
      theme: darkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('OAuthButton', () {
    group('Google provider', () {
      testWidgets('renders correctly with Google text', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            OAuthButton(
              provider: OAuthProvider.google,
              onPressed: () {},
            ),
          ),
        );

        expect(find.text('Continue with Google'), findsOneWidget);
      });

      testWidgets('calls onPressed when tapped', (tester) async {
        var pressed = false;

        await tester.pumpWidget(
          buildTestWidget(
            OAuthButton(
              provider: OAuthProvider.google,
              onPressed: () => pressed = true,
            ),
          ),
        );

        await tester.tap(find.byType(InkWell));
        expect(pressed, isTrue);
      });

      testWidgets('is disabled when onPressed is null', (tester) async {
        const pressed = false;

        await tester.pumpWidget(
          buildTestWidget(
            const OAuthButton(
              provider: OAuthProvider.google,
              onPressed: null,
            ),
          ),
        );

        await tester.tap(find.byType(InkWell));
        expect(pressed, isFalse);
      });

      testWidgets('shows loading indicator when isLoading is true',
          (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            OAuthButton(
              provider: OAuthProvider.google,
              onPressed: () {},
              isLoading: true,
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Continue with Google'), findsNothing);
      });

      testWidgets('is not tappable when loading', (tester) async {
        var pressed = false;

        await tester.pumpWidget(
          buildTestWidget(
            OAuthButton(
              provider: OAuthProvider.google,
              onPressed: () => pressed = true,
              isLoading: true,
            ),
          ),
        );

        await tester.tap(find.byType(InkWell));
        expect(pressed, isFalse);
      });

      testWidgets('has white background in light mode', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            OAuthButton(
              provider: OAuthProvider.google,
              onPressed: () {},
            ),
            darkMode: false,
          ),
        );

        final container = tester.widget<Container>(find.byType(Container));
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, equals(Colors.white));
      });
    });

    group('Apple provider', () {
      testWidgets('renders correctly with Apple text', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            OAuthButton(
              provider: OAuthProvider.apple,
              onPressed: () {},
            ),
          ),
        );

        expect(find.text('Sign in with Apple'), findsOneWidget);
        expect(find.byIcon(Icons.apple), findsOneWidget);
      });

      testWidgets('calls onPressed when tapped', (tester) async {
        var pressed = false;

        await tester.pumpWidget(
          buildTestWidget(
            OAuthButton(
              provider: OAuthProvider.apple,
              onPressed: () => pressed = true,
            ),
          ),
        );

        await tester.tap(find.byType(InkWell));
        expect(pressed, isTrue);
      });

      testWidgets('shows loading indicator when isLoading is true',
          (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            OAuthButton(
              provider: OAuthProvider.apple,
              onPressed: () {},
              isLoading: true,
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Sign in with Apple'), findsNothing);
      });

      testWidgets('has black background in light mode (Apple HIG)',
          (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            OAuthButton(
              provider: OAuthProvider.apple,
              onPressed: () {},
            ),
            darkMode: false,
          ),
        );

        final container = tester.widget<Container>(find.byType(Container));
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, equals(Colors.black));
      });

      testWidgets('has white background in dark mode (Apple HIG)',
          (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            OAuthButton(
              provider: OAuthProvider.apple,
              onPressed: () {},
            ),
            darkMode: true,
          ),
        );

        final container = tester.widget<Container>(find.byType(Container));
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, equals(Colors.white));
      });
    });
  });

  group('OAuthButtonsRow', () {
    testWidgets('renders Google button', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          OAuthButtonsRow(
            onGooglePressed: () {},
            showAppleButton: false,
          ),
        ),
      );

      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('shows Apple button when showAppleButton is true',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          OAuthButtonsRow(
            onGooglePressed: () {},
            onApplePressed: () {},
            showAppleButton: true,
          ),
        ),
      );

      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Sign in with Apple'), findsOneWidget);
    });

    testWidgets('hides Apple button when showAppleButton is false',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          OAuthButtonsRow(
            onGooglePressed: () {},
            onApplePressed: () {},
            showAppleButton: false,
          ),
        ),
      );

      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Sign in with Apple'), findsNothing);
    });

    testWidgets('calls correct callbacks when buttons are tapped',
        (tester) async {
      var googlePressed = false;
      var applePressed = false;

      await tester.pumpWidget(
        buildTestWidget(
          OAuthButtonsRow(
            onGooglePressed: () => googlePressed = true,
            onApplePressed: () => applePressed = true,
            showAppleButton: true,
          ),
        ),
      );

      await tester.tap(find.text('Continue with Google'));
      expect(googlePressed, isTrue);

      await tester.tap(find.text('Sign in with Apple'));
      expect(applePressed, isTrue);
    });

    testWidgets('shows loading state on both buttons', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          OAuthButtonsRow(
            onGooglePressed: () {},
            onApplePressed: () {},
            isLoading: true,
            showAppleButton: true,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsNWidgets(2));
      expect(find.text('Continue with Google'), findsNothing);
      expect(find.text('Sign in with Apple'), findsNothing);
    });

    testWidgets('has proper spacing between buttons', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          OAuthButtonsRow(
            onGooglePressed: () {},
            onApplePressed: () {},
            showAppleButton: true,
          ),
        ),
      );

      // Verify there is a SizedBox with height 12 between buttons
      final column = tester.widget<Column>(find.byType(Column).first);
      expect(
        column.children.any((widget) =>
            widget is SizedBox && widget.height == 12),
        isTrue,
      );
    });
  });
}
