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

  Widget buildTestWidget(Widget child, {bool darkMode = false}) {
    return MaterialApp(
      theme: darkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
      home: Scaffold(
        body: Center(
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
  }

  group('PasswordField', () {
    group('Initial state', () {
      testWidgets('renders with default label when no label provided', (
        tester,
      ) async {
        final controller = TextEditingController();

        await tester.pumpWidget(
          buildTestWidget(PasswordField(controller: controller)),
        );

        expect(find.text('Password'), findsOneWidget);
      });

      testWidgets('renders with custom label', (tester) async {
        final controller = TextEditingController();

        await tester.pumpWidget(
          buildTestWidget(
            PasswordField(controller: controller, label: 'Enter Password'),
          ),
        );

        expect(find.text('Enter Password'), findsOneWidget);
      });

      testWidgets('renders with hint text', (tester) async {
        final controller = TextEditingController();

        await tester.pumpWidget(
          buildTestWidget(
            PasswordField(
              controller: controller,
              hint: 'At least 8 characters',
            ),
          ),
        );

        expect(find.text('At least 8 characters'), findsOneWidget);
      });

      testWidgets('has lock icon as prefix', (tester) async {
        final controller = TextEditingController();

        await tester.pumpWidget(
          buildTestWidget(PasswordField(controller: controller)),
        );

        expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      });

      testWidgets('has visibility_outlined icon as suffix initially', (
        tester,
      ) async {
        final controller = TextEditingController();

        await tester.pumpWidget(
          buildTestWidget(PasswordField(controller: controller)),
        );

        expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
        expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);
      });

      testWidgets('text is obscured by default', (tester) async {
        final controller = TextEditingController(text: 'secret123');

        await tester.pumpWidget(
          buildTestWidget(PasswordField(controller: controller)),
        );

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.obscureText, isTrue);
      });
    });

    group('Toggle visibility', () {
      testWidgets('tap on eye icon shows password', (tester) async {
        final controller = TextEditingController(text: 'secret123');

        await tester.pumpWidget(
          buildTestWidget(PasswordField(controller: controller)),
        );

        // Initially obscured
        var textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.obscureText, isTrue);
        expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

        // Tap to show password
        await tester.tap(find.byIcon(Icons.visibility_outlined));
        await tester.pump();

        // Password should now be visible
        textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.obscureText, isFalse);
        expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      });

      testWidgets('tap twice returns to hidden state', (tester) async {
        final controller = TextEditingController(text: 'secret123');

        await tester.pumpWidget(
          buildTestWidget(PasswordField(controller: controller)),
        );

        // Tap to show
        await tester.tap(find.byIcon(Icons.visibility_outlined));
        await tester.pump();

        // Tap to hide again
        await tester.tap(find.byIcon(Icons.visibility_off_outlined));
        await tester.pump();

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.obscureText, isTrue);
        expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      });
    });

    group('Validation', () {
      testWidgets('validator is called on form validation', (tester) async {
        final controller = TextEditingController();
        final formKey = GlobalKey<FormState>();
        var validatorCalled = false;

        await tester.pumpWidget(
          buildTestWidget(
            Form(
              key: formKey,
              child: PasswordField(
                controller: controller,
                validator: (value) {
                  validatorCalled = true;
                  return null;
                },
              ),
            ),
          ),
        );

        formKey.currentState!.validate();
        await tester.pump();

        expect(validatorCalled, isTrue);
      });

      testWidgets('displays validation error message', (tester) async {
        final controller = TextEditingController();
        final formKey = GlobalKey<FormState>();

        await tester.pumpWidget(
          buildTestWidget(
            Form(
              key: formKey,
              child: PasswordField(
                controller: controller,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  return null;
                },
              ),
            ),
          ),
        );

        formKey.currentState!.validate();
        await tester.pump();

        expect(find.text('Password is required'), findsOneWidget);
      });

      testWidgets('displays errorText when provided', (tester) async {
        final controller = TextEditingController();

        await tester.pumpWidget(
          buildTestWidget(
            PasswordField(
              controller: controller,
              errorText: 'Invalid password',
            ),
          ),
        );

        expect(find.text('Invalid password'), findsOneWidget);
      });
    });

    group('Keyboard settings', () {
      testWidgets('has correct keyboard type', (tester) async {
        final controller = TextEditingController();

        await tester.pumpWidget(
          buildTestWidget(PasswordField(controller: controller)),
        );

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.keyboardType, TextInputType.visiblePassword);
      });

      testWidgets('has suggestions disabled', (tester) async {
        final controller = TextEditingController();

        await tester.pumpWidget(
          buildTestWidget(PasswordField(controller: controller)),
        );

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.enableSuggestions, isFalse);
      });

      testWidgets('has autocorrect disabled', (tester) async {
        final controller = TextEditingController();

        await tester.pumpWidget(
          buildTestWidget(PasswordField(controller: controller)),
        );

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.autocorrect, isFalse);
      });

      testWidgets('uses provided textInputAction', (tester) async {
        final controller = TextEditingController();

        await tester.pumpWidget(
          buildTestWidget(
            PasswordField(
              controller: controller,
              textInputAction: TextInputAction.done,
            ),
          ),
        );

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.textInputAction, TextInputAction.done);
      });
    });

    group('Callbacks', () {
      testWidgets('onChanged is called when text changes', (tester) async {
        final controller = TextEditingController();
        String? changedValue;

        await tester.pumpWidget(
          buildTestWidget(
            PasswordField(
              controller: controller,
              onChanged: (value) => changedValue = value,
            ),
          ),
        );

        await tester.enterText(find.byType(TextField), 'newpassword');
        expect(changedValue, 'newpassword');
      });

      testWidgets('onSubmitted is called when submitted', (tester) async {
        final controller = TextEditingController();
        String? submittedValue;

        await tester.pumpWidget(
          buildTestWidget(
            PasswordField(
              controller: controller,
              onSubmitted: (value) => submittedValue = value,
            ),
          ),
        );

        await tester.enterText(find.byType(TextField), 'mypassword');
        await tester.testTextInput.receiveAction(TextInputAction.done);

        expect(submittedValue, 'mypassword');
      });
    });

    group('Autofocus', () {
      testWidgets('does not autofocus by default', (tester) async {
        final controller = TextEditingController();

        await tester.pumpWidget(
          buildTestWidget(PasswordField(controller: controller)),
        );

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.autofocus, isFalse);
      });

      testWidgets('autofocuses when autofocus is true', (tester) async {
        final controller = TextEditingController();

        await tester.pumpWidget(
          buildTestWidget(
            PasswordField(controller: controller, autofocus: true),
          ),
        );

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.autofocus, isTrue);
      });
    });

    group('Accessibility', () {
      testWidgets('toggle button has tooltip for hidden state', (tester) async {
        final controller = TextEditingController();

        await tester.pumpWidget(
          buildTestWidget(PasswordField(controller: controller)),
        );

        final iconButton = tester.widget<IconButton>(find.byType(IconButton));
        expect(iconButton.tooltip, 'Show password');
      });

      testWidgets('toggle button has tooltip for visible state', (
        tester,
      ) async {
        final controller = TextEditingController();

        await tester.pumpWidget(
          buildTestWidget(PasswordField(controller: controller)),
        );

        await tester.tap(find.byIcon(Icons.visibility_outlined));
        await tester.pump();

        final iconButton = tester.widget<IconButton>(find.byType(IconButton));
        expect(iconButton.tooltip, 'Hide password');
      });

      testWidgets('toggle button has semantics label', (tester) async {
        final controller = TextEditingController();

        await tester.pumpWidget(
          buildTestWidget(PasswordField(controller: controller)),
        );

        expect(find.bySemanticsLabel('Show password'), findsOneWidget);
      });
    });

    group('Theme integration', () {
      testWidgets('uses theme input decoration in light mode', (tester) async {
        final controller = TextEditingController();

        await tester.pumpWidget(
          buildTestWidget(
            PasswordField(controller: controller),
            darkMode: false,
          ),
        );

        // Widget should render without errors with light theme
        expect(find.byType(PasswordField), findsOneWidget);
      });

      testWidgets('uses theme input decoration in dark mode', (tester) async {
        final controller = TextEditingController();

        await tester.pumpWidget(
          buildTestWidget(
            PasswordField(controller: controller),
            darkMode: true,
          ),
        );

        // Widget should render without errors with dark theme
        expect(find.byType(PasswordField), findsOneWidget);
      });
    });
  });
}
