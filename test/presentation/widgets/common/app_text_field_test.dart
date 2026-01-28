import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/presentation/widgets/common/app_text_field.dart';

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
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }

  group('AppTextField', () {
    testWidgets('renders TextFormField', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AppTextField(),
        ),
      );

      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('displays label text', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AppTextField(
            label: 'Email',
          ),
        ),
      );

      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('displays hint text', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AppTextField(
            hint: 'Enter your email',
          ),
        ),
      );

      expect(find.text('Enter your email'), findsOneWidget);
    });

    testWidgets('displays error text', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AppTextField(
            errorText: 'Invalid email',
          ),
        ),
      );

      expect(find.text('Invalid email'), findsOneWidget);
    });

    testWidgets('displays prefix icon', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AppTextField(
            prefixIcon: Icon(Icons.email),
          ),
        ),
      );

      expect(find.byIcon(Icons.email), findsOneWidget);
    });

    testWidgets('displays suffix icon', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AppTextField(
            suffixIcon: Icon(Icons.visibility),
          ),
        ),
      );

      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('obscures text when obscureText is true', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AppTextField(
            obscureText: true,
          ),
        ),
      );

      final editableText = tester.widget<EditableText>(
        find.byType(EditableText),
      );
      expect(editableText.obscureText, isTrue);
    });

    testWidgets('calls onChanged when text changes', (tester) async {
      String? changedValue;

      await tester.pumpWidget(
        buildTestWidget(
          AppTextField(
            onChanged: (value) => changedValue = value,
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'test input');
      expect(changedValue, 'test input');
    });

    testWidgets('calls validator when validating', (tester) async {
      final formKey = GlobalKey<FormState>();
      String? validationResult;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Form(
              key: formKey,
              child: AppTextField(
                validator: (value) {
                  validationResult = value;
                  if (value == null || value.isEmpty) {
                    return 'Required field';
                  }
                  return null;
                },
              ),
            ),
          ),
        ),
      );

      formKey.currentState!.validate();
      await tester.pump();

      expect(validationResult, '');
      expect(find.text('Required field'), findsOneWidget);
    });

    testWidgets('is disabled when enabled is false', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AppTextField(
            enabled: false,
          ),
        ),
      );

      final textField = tester.widget<TextFormField>(
        find.byType(TextFormField),
      );
      expect(textField.enabled, isFalse);
    });

    testWidgets('uses controller', (tester) async {
      final controller = TextEditingController(text: 'Initial value');

      await tester.pumpWidget(
        buildTestWidget(
          AppTextField(
            controller: controller,
          ),
        ),
      );

      expect(find.text('Initial value'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('calls onSubmitted when submitted', (tester) async {
      String? submittedValue;

      await tester.pumpWidget(
        buildTestWidget(
          AppTextField(
            onSubmitted: (value) => submittedValue = value,
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'submitted text');
      await tester.testTextInput.receiveAction(TextInputAction.done);

      expect(submittedValue, 'submitted text');
    });
  });
}
