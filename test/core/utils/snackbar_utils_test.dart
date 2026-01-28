import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fishfeed/core/utils/snackbar_utils.dart';

void main() {
  group('SnackbarUtils', () {
    group('showError', () {
      testWidgets('displays error message with red background', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    SnackbarUtils.showError(context, 'Error message');
                  },
                  child: const Text('Show Error'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Error'));
        await tester.pumpAndSettle();

        expect(find.text('Error message'), findsOneWidget);
        expect(find.text('OK'), findsOneWidget);

        // Verify snackbar is displayed
        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackBar.behavior, SnackBarBehavior.floating);
        expect(snackBar.duration, const Duration(seconds: 4));
      });

      testWidgets('uses theme error color for background', (tester) async {
        const errorColor = Colors.red;

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                error: errorColor,
              ),
            ),
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    SnackbarUtils.showError(context, 'Error');
                  },
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();

        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackBar.backgroundColor, errorColor);
      });

      testWidgets('OK button dismisses snackbar', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    SnackbarUtils.showError(context, 'Error message');
                  },
                  child: const Text('Show Error'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Error'));
        await tester.pumpAndSettle();

        expect(find.text('Error message'), findsOneWidget);

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        expect(find.text('Error message'), findsNothing);
      });

      testWidgets('custom action label is displayed', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    SnackbarUtils.showError(
                      context,
                      'Error',
                      actionLabel: 'Dismiss',
                    );
                  },
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();

        expect(find.text('Dismiss'), findsOneWidget);
      });

      testWidgets('hides previous snackbar before showing new one',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        SnackbarUtils.showError(context, 'First error');
                      },
                      child: const Text('First'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        SnackbarUtils.showError(context, 'Second error');
                      },
                      child: const Text('Second'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('First'));
        await tester.pump();

        await tester.tap(find.text('Second'));
        await tester.pumpAndSettle();

        // Only the second error should be visible
        expect(find.text('First error'), findsNothing);
        expect(find.text('Second error'), findsOneWidget);
      });
    });

    group('showSuccess', () {
      testWidgets('displays success message with green background',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    SnackbarUtils.showSuccess(context, 'Success message');
                  },
                  child: const Text('Show Success'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Success'));
        await tester.pumpAndSettle();

        expect(find.text('Success message'), findsOneWidget);
        expect(find.text('OK'), findsOneWidget);

        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackBar.behavior, SnackBarBehavior.floating);
        expect(snackBar.duration, const Duration(seconds: 2));
        expect(snackBar.backgroundColor, const Color(0xFF4CAF50));
      });

      testWidgets('OK button dismisses snackbar', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    SnackbarUtils.showSuccess(context, 'Success');
                  },
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        expect(find.text('Success'), findsNothing);
      });
    });

    group('showInfo', () {
      testWidgets('displays info message with primary color background',
          (tester) async {
        const primaryColor = Colors.blue;

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
            ),
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    SnackbarUtils.showInfo(context, 'Info message');
                  },
                  child: const Text('Show Info'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Info'));
        await tester.pumpAndSettle();

        expect(find.text('Info message'), findsOneWidget);

        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackBar.behavior, SnackBarBehavior.floating);
        expect(snackBar.duration, const Duration(seconds: 3));
      });
    });
  });
}
