import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/widgets/notifications/notification_settings_banner.dart';

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

  group('NotificationSettingsBanner', () {
    group('UI rendering', () {
      testWidgets('renders all elements', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            child: const NotificationSettingsBanner(),
          ),
        );

        await tester.pumpAndSettle();

        // Verify notification off icon
        expect(find.byIcon(Icons.notifications_off_outlined), findsOneWidget);

        // Verify title
        expect(find.text('Notifications Disabled'), findsOneWidget);

        // Verify description
        expect(
          find.text('Enable notifications to receive feeding reminders'),
          findsOneWidget,
        );

        // Verify enable button
        expect(find.text('Enable'), findsOneWidget);
      });

      testWidgets('shows dismiss button by default', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            child: const NotificationSettingsBanner(),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.close), findsOneWidget);
      });

      testWidgets('hides dismiss button when showDismissButton is false',
          (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            child: const NotificationSettingsBanner(showDismissButton: false),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.close), findsNothing);
      });
    });

    group('interactions', () {
      testWidgets('calls onEnablePressed when enable button is tapped',
          (tester) async {
        var enablePressed = false;

        await tester.pumpWidget(
          buildTestWidget(
            child: NotificationSettingsBanner(
              onEnablePressed: () => enablePressed = true,
            ),
          ),
        );

        await tester.pumpAndSettle();

        await tester.tap(find.text('Enable'));
        await tester.pumpAndSettle();

        expect(enablePressed, isTrue);
      });

      testWidgets('calls onEnablePressed when banner is tapped',
          (tester) async {
        var enablePressed = false;

        await tester.pumpWidget(
          buildTestWidget(
            child: NotificationSettingsBanner(
              onEnablePressed: () => enablePressed = true,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap on the banner itself (not the button)
        await tester.tap(find.byType(InkWell).first);
        await tester.pumpAndSettle();

        expect(enablePressed, isTrue);
      });

      testWidgets('calls onDismissed when dismiss button is tapped',
          (tester) async {
        var dismissed = false;

        await tester.pumpWidget(
          buildTestWidget(
            child: NotificationSettingsBanner(
              onDismissed: () => dismissed = true,
            ),
          ),
        );

        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        expect(dismissed, isTrue);
      });
    });

    group('styling', () {
      testWidgets('has rounded corners', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            child: const NotificationSettingsBanner(),
          ),
        );

        await tester.pumpAndSettle();

        final container = tester.widget<Container>(
          find.byType(Container).first,
        );
        final decoration = container.decoration as BoxDecoration?;
        expect(decoration?.borderRadius, isNotNull);
      });
    });
  });

  group('NotificationSettingsTile', () {
    group('UI rendering', () {
      testWidgets('renders all elements', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            child: const NotificationSettingsTile(),
          ),
        );

        await tester.pumpAndSettle();

        // Verify notification off icon
        expect(find.byIcon(Icons.notifications_off), findsOneWidget);

        // Verify title
        expect(find.text('Notifications'), findsOneWidget);

        // Verify hint text
        expect(
          find.text(
            'Notifications are disabled. Tap to open settings and enable them.',
          ),
          findsOneWidget,
        );

        // Verify open settings button
        expect(find.text('Open Settings'), findsOneWidget);
      });

      testWidgets('renders as ListTile', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            child: const NotificationSettingsTile(),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(ListTile), findsOneWidget);
      });
    });

    group('interactions', () {
      testWidgets('calls onTap when open settings button is tapped',
          (tester) async {
        var tapped = false;

        await tester.pumpWidget(
          buildTestWidget(
            child: NotificationSettingsTile(
              onTap: () => tapped = true,
            ),
          ),
        );

        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Settings'));
        await tester.pumpAndSettle();

        expect(tapped, isTrue);
      });

      testWidgets('calls onTap when tile is tapped', (tester) async {
        var tapped = false;

        await tester.pumpWidget(
          buildTestWidget(
            child: NotificationSettingsTile(
              onTap: () => tapped = true,
            ),
          ),
        );

        await tester.pumpAndSettle();

        await tester.tap(find.byType(ListTile));
        await tester.pumpAndSettle();

        expect(tapped, isTrue);
      });
    });
  });
}
