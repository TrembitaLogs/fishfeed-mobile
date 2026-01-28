import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/domain/entities/feeding_status.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/widgets/feeding/status_indicator.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  Widget buildTestWidget({
    required FeedingStatus status,
    StatusIndicatorSize size = StatusIndicatorSize.medium,
    bool showTooltip = false,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: Center(
          child: StatusIndicator(
            status: status,
            size: size,
            showTooltip: showTooltip,
          ),
        ),
      ),
    );
  }

  group('StatusIndicator', () {
    group('Status Icons', () {
      testWidgets('displays check icon for fed status', (tester) async {
        await tester.pumpWidget(buildTestWidget(status: FeedingStatus.fed));

        expect(find.byIcon(Icons.check), findsOneWidget);
      });

      testWidgets('displays close icon for missed status', (tester) async {
        await tester.pumpWidget(buildTestWidget(status: FeedingStatus.missed));

        expect(find.byIcon(Icons.close), findsOneWidget);
      });

      testWidgets('displays schedule icon for pending status', (tester) async {
        await tester.pumpWidget(buildTestWidget(status: FeedingStatus.pending));

        expect(find.byIcon(Icons.schedule), findsOneWidget);
      });
    });

    group('Status Colors', () {
      testWidgets('uses green color for fed status', (tester) async {
        await tester.pumpWidget(buildTestWidget(status: FeedingStatus.fed));

        final icon = tester.widget<Icon>(find.byIcon(Icons.check));
        expect(icon.color, equals(Colors.green));
      });

      testWidgets('uses red color for missed status', (tester) async {
        await tester.pumpWidget(buildTestWidget(status: FeedingStatus.missed));

        final icon = tester.widget<Icon>(find.byIcon(Icons.close));
        expect(icon.color, equals(Colors.red));
      });

      testWidgets('uses amber color for pending status', (tester) async {
        await tester.pumpWidget(buildTestWidget(status: FeedingStatus.pending));

        final icon = tester.widget<Icon>(find.byIcon(Icons.schedule));
        expect(icon.color, equals(Colors.amber.shade700));
      });
    });

    group('Static Helper Methods', () {
      test('getStatusColor returns correct colors', () {
        expect(StatusIndicator.getStatusColor(FeedingStatus.fed), Colors.green);
        expect(StatusIndicator.getStatusColor(FeedingStatus.missed), Colors.red);
        expect(
          StatusIndicator.getStatusColor(FeedingStatus.pending),
          Colors.amber.shade700,
        );
      });

      test('getStatusIcon returns correct icons', () {
        expect(StatusIndicator.getStatusIcon(FeedingStatus.fed), Icons.check);
        expect(StatusIndicator.getStatusIcon(FeedingStatus.missed), Icons.close);
        expect(
          StatusIndicator.getStatusIcon(FeedingStatus.pending),
          Icons.schedule,
        );
      });

      testWidgets('getPositiveMessage returns positive framing messages', (tester) async {
        await tester.pumpWidget(buildTestWidget(status: FeedingStatus.fed));
        await tester.pumpAndSettle();

        // Access l10n from widget context
        final context = tester.element(find.byType(StatusIndicator));
        final l10n = AppLocalizations.of(context)!;

        expect(
          StatusIndicator.getPositiveMessage(FeedingStatus.fed, l10n),
          'Great job!',
        );
        expect(
          StatusIndicator.getPositiveMessage(FeedingStatus.missed, l10n),
          'Next time will work!',
        );
        expect(
          StatusIndicator.getPositiveMessage(FeedingStatus.pending, l10n),
          'Pending feeding',
        );
      });
    });

    group('Size Variants', () {
      testWidgets('small size renders smaller dimensions', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          status: FeedingStatus.fed,
          size: StatusIndicatorSize.small,
        ));

        final animatedContainer = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );

        expect(animatedContainer.constraints?.maxWidth, equals(32));
        expect(animatedContainer.constraints?.maxHeight, equals(32));
      });

      testWidgets('medium size renders default dimensions', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          status: FeedingStatus.fed,
          size: StatusIndicatorSize.medium,
        ));

        final animatedContainer = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );

        expect(animatedContainer.constraints?.maxWidth, equals(40));
        expect(animatedContainer.constraints?.maxHeight, equals(40));
      });

      testWidgets('large size renders larger dimensions', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          status: FeedingStatus.fed,
          size: StatusIndicatorSize.large,
        ));

        final animatedContainer = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );

        expect(animatedContainer.constraints?.maxWidth, equals(56));
        expect(animatedContainer.constraints?.maxHeight, equals(56));
      });

      testWidgets('small size has smaller icon', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          status: FeedingStatus.fed,
          size: StatusIndicatorSize.small,
        ));

        final icon = tester.widget<Icon>(find.byIcon(Icons.check));
        expect(icon.size, equals(18));
      });

      testWidgets('large size has larger icon', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          status: FeedingStatus.fed,
          size: StatusIndicatorSize.large,
        ));

        final icon = tester.widget<Icon>(find.byIcon(Icons.check));
        expect(icon.size, equals(32));
      });
    });

    group('Tooltip', () {
      testWidgets('shows tooltip when enabled', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          status: FeedingStatus.fed,
          showTooltip: true,
        ));

        expect(find.byType(Tooltip), findsOneWidget);
      });

      testWidgets('hides tooltip when disabled', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          status: FeedingStatus.fed,
          showTooltip: false,
        ));

        expect(find.byType(Tooltip), findsNothing);
      });

      testWidgets('tooltip has positive message for fed status', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          status: FeedingStatus.fed,
          showTooltip: true,
        ));
        await tester.pumpAndSettle();

        final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
        expect(tooltip.message, equals('Great job!'));
      });

      testWidgets('tooltip has positive message for missed status', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          status: FeedingStatus.missed,
          showTooltip: true,
        ));
        await tester.pumpAndSettle();

        final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
        expect(tooltip.message, equals('Next time will work!'));
      });

      testWidgets('tooltip has message for pending status', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          status: FeedingStatus.pending,
          showTooltip: true,
        ));
        await tester.pumpAndSettle();

        final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
        expect(tooltip.message, equals('Pending feeding'));
      });
    });

    group('Animation', () {
      testWidgets('contains AnimatedContainer for transitions', (tester) async {
        await tester.pumpWidget(buildTestWidget(status: FeedingStatus.fed));

        expect(find.byType(AnimatedContainer), findsOneWidget);
      });

      testWidgets('contains AnimatedSwitcher for icon transitions', (tester) async {
        await tester.pumpWidget(buildTestWidget(status: FeedingStatus.fed));

        expect(find.byType(AnimatedSwitcher), findsOneWidget);
      });

      testWidgets('icon has ValueKey for animation', (tester) async {
        await tester.pumpWidget(buildTestWidget(status: FeedingStatus.fed));

        final icon = tester.widget<Icon>(find.byIcon(Icons.check));
        expect(icon.key, equals(const ValueKey(FeedingStatus.fed)));
      });

      testWidgets('animates smoothly between statuses', (tester) async {
        await tester.pumpWidget(buildTestWidget(status: FeedingStatus.pending));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.schedule), findsOneWidget);

        // Change status
        await tester.pumpWidget(buildTestWidget(status: FeedingStatus.fed));

        // During animation, might have both icons briefly
        await tester.pump(const Duration(milliseconds: 100));

        // After animation completes
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.check), findsOneWidget);
      });
    });

    group('Widget Structure', () {
      testWidgets('has rounded container', (tester) async {
        await tester.pumpWidget(buildTestWidget(status: FeedingStatus.fed));

        final animatedContainer = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );

        final decoration = animatedContainer.decoration as BoxDecoration;
        expect(decoration.borderRadius, isNotNull);
      });

      testWidgets('has semi-transparent background', (tester) async {
        await tester.pumpWidget(buildTestWidget(status: FeedingStatus.fed));

        final animatedContainer = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );

        final decoration = animatedContainer.decoration as BoxDecoration;
        final color = decoration.color!;

        // Check that alpha is approximately 0.15 (38/255)
        expect(color.a, closeTo(0.15, 0.01));
      });
    });
  });
}
