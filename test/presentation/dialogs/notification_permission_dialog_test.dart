import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/dialogs/notification_permission_dialog.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  Widget buildTestWidget({required Widget child}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  group('NotificationPermissionDialog', () {
    group('UI rendering', () {
      testWidgets('renders dialog with all elements', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => const NotificationPermissionDialog(),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        );

        // Open dialog
        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Verify dialog is shown
        expect(find.byType(Dialog), findsOneWidget);

        // Verify title and button (both have "Enable Notifications" text)
        expect(find.text('Enable Notifications'), findsNWidgets(2));

        // Verify description
        expect(find.textContaining('Get timely reminders'), findsOneWidget);

        // Verify enable button
        expect(
          find.widgetWithText(FilledButton, 'Enable Notifications'),
          findsOneWidget,
        );

        // Verify later button
        expect(find.widgetWithText(TextButton, 'Later'), findsOneWidget);

        // Verify icons
        expect(find.byIcon(Icons.set_meal), findsOneWidget);
        expect(find.byIcon(Icons.notifications), findsOneWidget);
      });

      testWidgets('renders with correct theme styling', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => const NotificationPermissionDialog(),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Verify dialog has rounded corners
        final dialog = tester.widget<Dialog>(find.byType(Dialog));
        expect(dialog.shape, isA<RoundedRectangleBorder>());
      });
    });

    group('interactions', () {
      testWidgets('returns enable result when enable button is tapped', (
        tester,
      ) async {
        NotificationPermissionDialogResult? result;

        await tester.pumpWidget(
          buildTestWidget(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await NotificationPermissionDialog.show(context);
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        await tester.tap(
          find.widgetWithText(FilledButton, 'Enable Notifications'),
        );
        await tester.pumpAndSettle();

        expect(result, equals(NotificationPermissionDialogResult.enable));
      });

      testWidgets('returns later result when later button is tapped', (
        tester,
      ) async {
        NotificationPermissionDialogResult? result;

        await tester.pumpWidget(
          buildTestWidget(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await NotificationPermissionDialog.show(context);
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(TextButton, 'Later'));
        await tester.pumpAndSettle();

        expect(result, equals(NotificationPermissionDialogResult.later));
      });

      testWidgets('returns later result when dialog is dismissed', (
        tester,
      ) async {
        NotificationPermissionDialogResult? result;

        await tester.pumpWidget(
          buildTestWidget(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await NotificationPermissionDialog.show(context);
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Tap outside the dialog to dismiss
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        expect(result, equals(NotificationPermissionDialogResult.later));
      });
    });

    group('static show method', () {
      testWidgets('show method displays dialog and returns result', (
        tester,
      ) async {
        NotificationPermissionDialogResult? result;

        await tester.pumpWidget(
          buildTestWidget(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await NotificationPermissionDialog.show(context);
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Dialog should be visible
        expect(find.byType(NotificationPermissionDialog), findsOneWidget);

        // Close dialog
        await tester.tap(
          find.widgetWithText(FilledButton, 'Enable Notifications'),
        );
        await tester.pumpAndSettle();

        expect(result, isNotNull);
      });
    });
  });

  group('NotificationPermissionDialogResult', () {
    test('has enable value', () {
      expect(NotificationPermissionDialogResult.enable, isNotNull);
      expect(NotificationPermissionDialogResult.enable.name, equals('enable'));
    });

    test('has later value', () {
      expect(NotificationPermissionDialogResult.later, isNotNull);
      expect(NotificationPermissionDialogResult.later.name, equals('later'));
    });

    test('has exactly 2 values', () {
      expect(NotificationPermissionDialogResult.values, hasLength(2));
    });
  });
}
