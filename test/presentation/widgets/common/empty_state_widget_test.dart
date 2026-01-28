import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/presentation/widgets/common/empty_state_widget.dart';

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
        body: child,
      ),
    );
  }

  group('EmptyStateWidget', () {
    testWidgets('renders icon, title and description', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const EmptyStateWidget(
            icon: Icons.inbox,
            title: 'No items',
            description: 'Add some items to get started',
            animate: false,
          ),
        ),
      );

      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.text('No items'), findsOneWidget);
      expect(find.text('Add some items to get started'), findsOneWidget);
    });

    testWidgets('shows action button when actionLabel and onAction provided',
        (tester) async {
      var actionPressed = false;

      await tester.pumpWidget(
        buildTestWidget(
          EmptyStateWidget(
            icon: Icons.inbox,
            title: 'No items',
            description: 'Add some items to get started',
            actionLabel: 'Add Item',
            onAction: () => actionPressed = true,
            animate: false,
          ),
        ),
      );

      expect(find.text('Add Item'), findsOneWidget);

      await tester.tap(find.text('Add Item'));
      expect(actionPressed, isTrue);
    });

    testWidgets('does not show action button when actionLabel is null',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          EmptyStateWidget(
            icon: Icons.inbox,
            title: 'No items',
            description: 'Add some items to get started',
            onAction: () {},
            animate: false,
          ),
        ),
      );

      expect(find.text('Add Item'), findsNothing);
    });

    testWidgets('does not show action button when onAction is null',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const EmptyStateWidget(
            icon: Icons.inbox,
            title: 'No items',
            description: 'Add some items to get started',
            actionLabel: 'Add Item',
            animate: false,
          ),
        ),
      );

      expect(find.text('Add Item'), findsNothing);
    });

    testWidgets('uses custom illustration when provided', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const EmptyStateWidget(
            icon: Icons.inbox,
            title: 'No items',
            description: 'Add some items to get started',
            illustration: Icon(Icons.star, key: Key('custom_illustration')),
            animate: false,
          ),
        ),
      );

      expect(find.byKey(const Key('custom_illustration')), findsOneWidget);
      // The default icon should not be in a circular container
      expect(
          find.byWidgetPredicate((widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).shape == BoxShape.circle),
          findsNothing);
    });

    testWidgets('renders correctly with theme colors', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const EmptyStateWidget(
            icon: Icons.inbox,
            title: 'No items',
            description: 'Add some items to get started',
            animate: false,
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.inbox));
      expect(icon.color, AppTheme.lightTheme.colorScheme.primary);
    });
  });

  group('ScrollableEmptyState', () {
    testWidgets('renders EmptyStateWidget inside CustomScrollView',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const ScrollableEmptyState(
            icon: Icons.inbox,
            title: 'No items',
            description: 'Add some items to get started',
            animate: false,
          ),
        ),
      );

      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.byType(EmptyStateWidget), findsOneWidget);
      expect(find.text('No items'), findsOneWidget);
    });

    testWidgets('supports pull to refresh with RefreshIndicator',
        (tester) async {
      var refreshed = false;

      await tester.pumpWidget(
        buildTestWidget(
          RefreshIndicator(
            onRefresh: () async => refreshed = true,
            child: const ScrollableEmptyState(
              icon: Icons.inbox,
              title: 'No items',
              description: 'Add some items to get started',
              animate: false,
            ),
          ),
        ),
      );

      // Fling down to trigger refresh
      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      expect(refreshed, isTrue);
    });
  });
}
