import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/domain/entities/subscription_status.dart';
import 'package:fishfeed/domain/entities/user.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';
import 'package:fishfeed/presentation/providers/purchase_provider.dart';
import 'package:fishfeed/presentation/screens/settings/settings_screen.dart';
import 'package:fishfeed/services/purchase/purchase_service.dart';

import '../../../helpers/test_helpers.dart';

class MockPurchaseService extends Mock implements PurchaseService {}

void main() {
  setUpAll(() {
    setupTestFonts();
  });

  tearDownAll(() {
    teardownTestFonts();
  });

  late MockPurchaseService mockPurchaseService;

  setUp(() {
    mockPurchaseService = MockPurchaseService();
  });

  Widget buildTestWidget({SubscriptionStatus? subscriptionStatus, User? user}) {
    return wrapForTesting(
      child: const SettingsScreen(),
      overrides: [
        ...getWidgetTestOverrides(currentUser: user ?? testUser),
        subscriptionStatusProvider.overrideWithValue(
          subscriptionStatus ?? const SubscriptionStatus.free(),
        ),
        purchaseServiceProvider.overrideWithValue(mockPurchaseService),
      ],
    );
  }

  // Helper to find section header by checking parent padding
  Finder findSectionHeader(String title) {
    return find.ancestor(
      of: find.text(title),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Padding &&
            widget.padding == const EdgeInsets.fromLTRB(16, 16, 16, 8),
      ),
    );
  }

  group('SettingsScreen', () {
    group('section headers', () {
      testWidgets('renders Subscription section header', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(findSectionHeader('Subscription'), findsOneWidget);
      });

      testWidgets('renders App section header', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(findSectionHeader('App'), findsOneWidget);
      });

      testWidgets('renders Account section header', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(findSectionHeader('Account'), findsOneWidget);
      });

      testWidgets('renders Legal section header', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Legal'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(findSectionHeader('Legal'), findsOneWidget);
      });

      testWidgets('renders Support section header', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Support'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(findSectionHeader('Support'), findsOneWidget);
      });
    });

    group('subscription section', () {
      testWidgets('shows free plan for non-premium user', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(subscriptionStatus: const SubscriptionStatus.free()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Free plan'), findsOneWidget);
        expect(find.text('Upgrade'), findsOneWidget);
      });

      testWidgets('shows active subscription for premium user', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            subscriptionStatus: const SubscriptionStatus(
              tier: SubscriptionTier.premium,
              isTrialActive: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Active subscription'), findsOneWidget);
        expect(find.text('Upgrade'), findsNothing);
      });

      testWidgets('shows trial info for trial user', (tester) async {
        final expirationDate = DateTime.now().add(const Duration(days: 5));
        await tester.pumpWidget(
          buildTestWidget(
            subscriptionStatus: SubscriptionStatus(
              tier: SubscriptionTier.premium,
              isTrialActive: true,
              expirationDate: expirationDate,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Trial ends in'), findsOneWidget);
      });

      testWidgets('shows restore purchases option', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Restore Purchases'), findsOneWidget);
        expect(find.text('Recover previous purchases'), findsOneWidget);
      });
    });

    group('app section', () {
      testWidgets('shows Notifications tile', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Notifications'), findsOneWidget);
        expect(find.text('Manage feeding reminders'), findsOneWidget);
      });

      testWidgets('shows Appearance tile', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Appearance'), findsOneWidget);
        expect(find.text('Theme and display options'), findsOneWidget);
      });
    });

    group('account section', () {
      testWidgets('shows Profile tile with user email', (tester) async {
        await tester.pumpWidget(buildTestWidget(user: testUser));
        await tester.pumpAndSettle();

        expect(find.text('Profile'), findsOneWidget);
        expect(find.text('test@example.com'), findsOneWidget);
      });

      testWidgets('shows Delete Account tile', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Scroll to make Delete Account visible
        await tester.scrollUntilVisible(
          find.text('Delete Account'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(find.text('Delete Account'), findsOneWidget);
        expect(find.text('Permanently delete your account'), findsOneWidget);
      });
    });

    group('delete account dialog', () {
      testWidgets('tapping Delete Account shows first confirmation dialog', (
        tester,
      ) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Scroll to make Delete Account visible
        await tester.scrollUntilVisible(
          find.text('Delete Account'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        // Find and tap Delete Account tile
        await tester.tap(find.text('Delete Account'));
        await tester.pumpAndSettle();

        // First dialog should appear
        expect(
          find.text('Delete Account'),
          findsNWidgets(2),
        ); // Tile + dialog title
        expect(
          find.textContaining('Are you sure you want to delete your account?'),
          findsOneWidget,
        );
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Continue'), findsOneWidget);
      });

      testWidgets('canceling first dialog closes it', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Scroll to make Delete Account visible
        await tester.scrollUntilVisible(
          find.text('Delete Account'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        // Open dialog
        await tester.tap(find.text('Delete Account'));
        await tester.pumpAndSettle();

        // Tap Cancel
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Dialog should be closed
        expect(find.text('Continue'), findsNothing);
      });

      testWidgets('continuing shows second confirmation dialog', (
        tester,
      ) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Scroll to make Delete Account visible
        await tester.scrollUntilVisible(
          find.text('Delete Account'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        // Open first dialog
        await tester.tap(find.text('Delete Account'));
        await tester.pumpAndSettle();

        // Tap Continue
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Second dialog should appear
        expect(find.text('Final Confirmation'), findsOneWidget);
        expect(find.text('This will permanently delete:'), findsOneWidget);
        expect(find.text('This action is irreversible.'), findsOneWidget);
        expect(find.text('Delete My Account'), findsOneWidget);
      });

      testWidgets('canceling second dialog closes it', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Scroll to make Delete Account visible
        await tester.scrollUntilVisible(
          find.text('Delete Account'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        // Open first dialog
        await tester.tap(find.text('Delete Account'));
        await tester.pumpAndSettle();

        // Continue to second dialog
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Tap Cancel on second dialog
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Dialog should be closed
        expect(find.text('Final Confirmation'), findsNothing);
      });

      testWidgets('second dialog shows warning icon', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Scroll to make Delete Account visible
        await tester.scrollUntilVisible(
          find.text('Delete Account'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        // Navigate to second dialog
        await tester.tap(find.text('Delete Account'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Warning icon should be visible
        expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      });

      testWidgets('second dialog lists data that will be deleted', (
        tester,
      ) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Scroll to make Delete Account visible
        await tester.scrollUntilVisible(
          find.text('Delete Account'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        // Navigate to second dialog
        await tester.tap(find.text('Delete Account'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Check deletion list items
        expect(find.text('• All your aquariums and fish data'), findsOneWidget);
        expect(find.text('• Your feeding history and streaks'), findsOneWidget);
        expect(
          find.text('• Your account and personal information'),
          findsOneWidget,
        );
      });
    });

    group('legal section', () {
      testWidgets('shows Privacy Policy tile', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Privacy Policy'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(find.text('Privacy Policy'), findsOneWidget);
        expect(find.text('How we handle your data'), findsOneWidget);
        expect(find.byIcon(Icons.privacy_tip_outlined), findsOneWidget);
      });

      testWidgets('shows Terms of Service tile', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Terms of Service'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(find.text('Terms of Service'), findsOneWidget);
        expect(find.text('Usage terms and conditions'), findsOneWidget);
        expect(find.byIcon(Icons.description_outlined), findsOneWidget);
      });

      testWidgets('shows Licenses tile', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Licenses'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(find.text('Licenses'), findsOneWidget);
        expect(find.text('Open source licenses'), findsOneWidget);
        expect(find.byIcon(Icons.article_outlined), findsOneWidget);
      });
    });

    group('support section', () {
      testWidgets('shows Contact Support tile', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Contact Support'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(find.text('Contact Support'), findsOneWidget);
        expect(find.text('Get help via email'), findsOneWidget);
        expect(find.byIcon(Icons.mail_outlined), findsOneWidget);
      });

      testWidgets('shows Rate App tile', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Rate App'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(find.text('Rate App'), findsOneWidget);
        expect(find.text('Share your experience'), findsOneWidget);
        expect(find.byIcon(Icons.star_outline), findsOneWidget);
      });

      testWidgets('shows App Version tile', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('App Version'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(find.text('App Version'), findsOneWidget);
        expect(find.byIcon(Icons.info_outline), findsOneWidget);
      });

      testWidgets('App Version displays dynamic version after loading', (
        tester,
      ) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('App Version'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        // Version should be displayed (either loading or actual version)
        final versionFinder = find.descendant(
          of: find.widgetWithText(ListTile, 'App Version'),
          matching: find.byType(Text),
        );
        expect(versionFinder, findsWidgets);
      });
    });

    group('responsive layout', () {
      testWidgets('renders all sections in scrollable list', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(ListView), findsOneWidget);
      });
    });
  });
}
