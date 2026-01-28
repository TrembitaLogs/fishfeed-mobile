import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/domain/entities/subscription_status.dart';
import 'package:fishfeed/presentation/providers/purchase_provider.dart';
import 'package:fishfeed/presentation/screens/paywall/paywall_screen.dart';
import 'package:fishfeed/services/purchase/purchase_service.dart';

class MockPurchaseService extends Mock implements PurchaseService {}

class MockOfferings extends Mock implements Offerings {}

class MockOffering extends Mock implements Offering {}

class MockPackage extends Mock implements Package {}

class MockStoreProduct extends Mock implements StoreProduct {}

class MockCustomerInfo extends Mock implements CustomerInfo {}

class MockEntitlementInfos extends Mock implements EntitlementInfos {}

class MockEntitlementInfo extends Mock implements EntitlementInfo {}

void main() {
  late MockPurchaseService mockPurchaseService;
  late MockOfferings mockOfferings;
  late MockOffering mockOffering;
  late MockPackage mockMonthlyPackage;
  late MockPackage mockAnnualPackage;
  late MockStoreProduct mockMonthlyProduct;
  late MockStoreProduct mockAnnualProduct;
  late MockCustomerInfo mockCustomerInfo;
  late MockEntitlementInfos mockEntitlementInfos;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
    registerFallbackValue(MockPackage());
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  setUp(() {
    mockPurchaseService = MockPurchaseService();
    mockOfferings = MockOfferings();
    mockOffering = MockOffering();
    mockMonthlyPackage = MockPackage();
    mockAnnualPackage = MockPackage();
    mockMonthlyProduct = MockStoreProduct();
    mockAnnualProduct = MockStoreProduct();
    mockCustomerInfo = MockCustomerInfo();
    mockEntitlementInfos = MockEntitlementInfos();

    // Setup default mocks for products
    when(() => mockMonthlyProduct.identifier).thenReturn('premium_monthly');
    when(() => mockMonthlyProduct.title).thenReturn('Monthly');
    when(() => mockMonthlyProduct.priceString).thenReturn('\$3.99');
    when(() => mockMonthlyProduct.price).thenReturn(3.99);
    when(() => mockMonthlyProduct.currencyCode).thenReturn('USD');

    when(() => mockAnnualProduct.identifier).thenReturn('premium_annual');
    when(() => mockAnnualProduct.title).thenReturn('Annual');
    when(() => mockAnnualProduct.priceString).thenReturn('\$29.99');
    when(() => mockAnnualProduct.price).thenReturn(29.99);
    when(() => mockAnnualProduct.currencyCode).thenReturn('USD');

    // Setup packages
    when(() => mockMonthlyPackage.storeProduct).thenReturn(mockMonthlyProduct);
    when(() => mockMonthlyPackage.packageType).thenReturn(PackageType.monthly);

    when(() => mockAnnualPackage.storeProduct).thenReturn(mockAnnualProduct);
    when(() => mockAnnualPackage.packageType).thenReturn(PackageType.annual);

    // Setup offering
    when(() => mockOffering.monthly).thenReturn(mockMonthlyPackage);
    when(() => mockOffering.annual).thenReturn(mockAnnualPackage);

    // Setup offerings
    when(() => mockOfferings.current).thenReturn(mockOffering);

    // Setup customer info
    when(() => mockEntitlementInfos.active).thenReturn({});
    when(() => mockCustomerInfo.entitlements).thenReturn(mockEntitlementInfos);

    // Default service initialization
    when(() => mockPurchaseService.isInitialized).thenReturn(true);
    when(() => mockPurchaseService.getSubscriptionStatus())
        .thenReturn(const SubscriptionStatus.free());

    // Default: remove ads package not available
    when(() => mockPurchaseService.getRemoveAdsPackage())
        .thenAnswer((_) async => const Left(ProductNotAvailableFailure(productId: 'remove_ads')));
  });

  Widget buildTestWidget({
    List<Override> additionalOverrides = const [],
    bool startAtPaywall = true,
  }) {
    final router = GoRouter(
      initialLocation: startAtPaywall ? '/paywall' : '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Home')),
          routes: [
            GoRoute(
              path: 'paywall',
              builder: (context, state) => const PaywallScreen(),
            ),
          ],
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        purchaseServiceProvider.overrideWithValue(mockPurchaseService),
        ...additionalOverrides,
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    );
  }

  group('PaywallScreen', () {
    group('loading state', () {
      testWidgets('screen starts in loading state with _isLoadingOfferings=true', (tester) async {
        // Use a completer to control when the future completes
        final completer = Completer<Either<Failure, Offerings>>();
        when(() => mockPurchaseService.getOfferings())
            .thenAnswer((_) => completer.future);

        await tester.pumpWidget(buildTestWidget());
        await tester.pump(); // Allow initState to run

        // Should show loading indicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Complete the future to avoid pending timers
        completer.complete(Right(mockOfferings));
        await tester.pumpAndSettle();
      });
    });

    group('content rendering', () {
      testWidgets('renders hero section with premium badge', (tester) async {
        when(() => mockPurchaseService.getOfferings())
            .thenAnswer((_) async => Right(mockOfferings));

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Unlock Premium'), findsOneWidget);
        expect(find.byIcon(Icons.workspace_premium), findsOneWidget);
      });

      testWidgets('renders all premium benefits', (tester) async {
        when(() => mockPurchaseService.getOfferings())
            .thenAnswer((_) async => Right(mockOfferings));

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('No Ads'), findsOneWidget);
        expect(find.text('Unlimited AI Fish Scans'), findsOneWidget);
        expect(find.text('Extended Statistics (6 months)'), findsOneWidget);
        expect(find.text('Family Mode (5+ users)'), findsOneWidget);
        expect(find.text('Multiple Aquariums'), findsOneWidget);
      });

      testWidgets('renders trial banner', (tester) async {
        when(() => mockPurchaseService.getOfferings())
            .thenAnswer((_) async => Right(mockOfferings));

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('7 Days Free'), findsOneWidget);
      });

      testWidgets('renders product options', (tester) async {
        when(() => mockPurchaseService.getOfferings())
            .thenAnswer((_) async => Right(mockOfferings));

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Choose Your Plan'), findsOneWidget);
        expect(find.text('\$3.99'), findsOneWidget);
        expect(find.text('\$29.99'), findsOneWidget);
      });

      testWidgets('renders CTA button', (tester) async {
        when(() => mockPurchaseService.getOfferings())
            .thenAnswer((_) async => Right(mockOfferings));

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Start 7-Day Free Trial'), findsOneWidget);
      });

      testWidgets('renders restore purchases link', (tester) async {
        when(() => mockPurchaseService.getOfferings())
            .thenAnswer((_) async => Right(mockOfferings));

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // The scrollable should contain restore purchases
        final scrollableFinder = find.byType(SingleChildScrollView);
        expect(scrollableFinder, findsOneWidget);

        // Scroll down to find the restore purchases link
        await tester.dragUntilVisible(
          find.text('Restore Purchases'),
          scrollableFinder,
          const Offset(0, -200),
        );
        await tester.pumpAndSettle();

        expect(find.text('Restore Purchases'), findsOneWidget);
      });
    });

    group('error state', () {
      testWidgets('shows error message when offerings fail to load', (tester) async {
        when(() => mockPurchaseService.getOfferings())
            .thenAnswer((_) async => const Left(PurchaseFailure(message: 'Network error')));

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Network error'), findsOneWidget);
      });

      testWidgets('shows fallback products when offerings fail', (tester) async {
        when(() => mockPurchaseService.getOfferings())
            .thenAnswer((_) async => const Left(PurchaseFailure(message: 'Error')));

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Should still show fallback product options
        expect(find.text('Choose Your Plan'), findsOneWidget);
      });
    });

    group('navigation', () {
      testWidgets('close button pops the screen', (tester) async {
        when(() => mockPurchaseService.getOfferings())
            .thenAnswer((_) async => Right(mockOfferings));

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Should navigate away from paywall
        expect(find.byType(PaywallScreen), findsNothing);
      });
    });

    group('product selection', () {
      testWidgets('product cards are rendered and tappable', (tester) async {
        when(() => mockPurchaseService.getOfferings())
            .thenAnswer((_) async => Right(mockOfferings));

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Both products should be rendered
        expect(find.text('Monthly'), findsOneWidget);
        expect(find.text('Annual'), findsOneWidget);
        expect(find.text('\$3.99'), findsOneWidget);
        expect(find.text('\$29.99'), findsOneWidget);
      });
    });

    group('purchase flow', () {
      testWidgets('CTA button calls purchasePackage', (tester) async {
        // Setup with premium entitlement so pop succeeds
        final mockEntitlements = <String, dynamic>{'premium': {}};
        when(() => mockEntitlementInfos.active).thenReturn({});
        when(() => mockCustomerInfo.entitlements).thenReturn(mockEntitlementInfos);

        when(() => mockPurchaseService.getOfferings())
            .thenAnswer((_) async => Right(mockOfferings));
        when(() => mockPurchaseService.purchasePackage(any()))
            .thenAnswer((_) async => Right(mockCustomerInfo));

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Find CTA button
        final scrollableFinder = find.byType(SingleChildScrollView);
        await tester.dragUntilVisible(
          find.text('Start 7-Day Free Trial'),
          scrollableFinder,
          const Offset(0, -200),
        );
        await tester.pumpAndSettle();

        expect(find.text('Start 7-Day Free Trial'), findsOneWidget);

        // Tapping the button should call purchasePackage
        await tester.tap(find.text('Start 7-Day Free Trial'));
        await tester.pump();

        verify(() => mockPurchaseService.purchasePackage(any())).called(1);
      });
    });

    group('restore purchases', () {
      testWidgets('calls restore purchases on tap', (tester) async {
        when(() => mockPurchaseService.getOfferings())
            .thenAnswer((_) async => Right(mockOfferings));
        when(() => mockPurchaseService.restorePurchases())
            .thenAnswer((_) async => Right(mockCustomerInfo));

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Scroll to make the link visible
        final scrollableFinder = find.byType(SingleChildScrollView);
        await tester.dragUntilVisible(
          find.text('Restore Purchases'),
          scrollableFinder,
          const Offset(0, -200),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Restore Purchases'));
        await tester.pump();

        verify(() => mockPurchaseService.restorePurchases()).called(1);
      });

      testWidgets('shows no purchases message when restore finds nothing', (tester) async {
        when(() => mockPurchaseService.getOfferings())
            .thenAnswer((_) async => Right(mockOfferings));
        when(() => mockPurchaseService.restorePurchases())
            .thenAnswer((_) async => Right(mockCustomerInfo));

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Scroll to make the link visible
        final scrollableFinder = find.byType(SingleChildScrollView);
        await tester.dragUntilVisible(
          find.text('Restore Purchases'),
          scrollableFinder,
          const Offset(0, -200),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Restore Purchases'));
        await tester.pumpAndSettle();

        expect(find.text('No previous purchases found'), findsOneWidget);
      });
    });

    group('app bar', () {
      testWidgets('has correct title', (tester) async {
        when(() => mockPurchaseService.getOfferings())
            .thenAnswer((_) async => Right(mockOfferings));
        when(() => mockPurchaseService.getRemoveAdsPackage())
            .thenAnswer((_) async => const Left(ProductNotAvailableFailure(productId: 'remove_ads')));

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Premium'), findsOneWidget);
      });

      testWidgets('has close button', (tester) async {
        when(() => mockPurchaseService.getOfferings())
            .thenAnswer((_) async => Right(mockOfferings));
        when(() => mockPurchaseService.getRemoveAdsPackage())
            .thenAnswer((_) async => const Left(ProductNotAvailableFailure(productId: 'remove_ads')));

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.close), findsOneWidget);
      });
    });

    group('remove ads section', () {
      late MockPackage mockRemoveAdsPackage;
      late MockStoreProduct mockRemoveAdsProduct;

      setUp(() {
        mockRemoveAdsPackage = MockPackage();
        mockRemoveAdsProduct = MockStoreProduct();

        when(() => mockRemoveAdsProduct.identifier).thenReturn('remove_ads_forever');
        when(() => mockRemoveAdsProduct.title).thenReturn('Remove Ads');
        when(() => mockRemoveAdsProduct.priceString).thenReturn('\$3.99');
        when(() => mockRemoveAdsProduct.price).thenReturn(3.99);
        when(() => mockRemoveAdsProduct.currencyCode).thenReturn('USD');

        when(() => mockRemoveAdsPackage.storeProduct).thenReturn(mockRemoveAdsProduct);
        when(() => mockRemoveAdsPackage.packageType).thenReturn(PackageType.lifetime);
      });

      testWidgets('shows remove ads section when package is available', (tester) async {
        when(() => mockPurchaseService.getOfferings())
            .thenAnswer((_) async => Right(mockOfferings));
        when(() => mockPurchaseService.getRemoveAdsPackage())
            .thenAnswer((_) async => Right(mockRemoveAdsPackage));

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Scroll to make the remove ads section visible
        final scrollableFinder = find.byType(SingleChildScrollView);
        await tester.dragUntilVisible(
          find.text('Remove Ads'),
          scrollableFinder,
          const Offset(0, -200),
        );
        await tester.pumpAndSettle();

        expect(find.text('Remove Ads'), findsOneWidget);
        expect(find.text('or'), findsOneWidget);
      });

      testWidgets('does not show remove ads section when package is not available', (tester) async {
        when(() => mockPurchaseService.getOfferings())
            .thenAnswer((_) async => Right(mockOfferings));
        when(() => mockPurchaseService.getRemoveAdsPackage())
            .thenAnswer((_) async => const Left(ProductNotAvailableFailure(productId: 'remove_ads')));

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // The 'or' divider should not be present
        expect(find.text('or'), findsNothing);
      });

      testWidgets('calls purchasePackage when remove ads card is tapped', (tester) async {
        when(() => mockPurchaseService.getOfferings())
            .thenAnswer((_) async => Right(mockOfferings));
        when(() => mockPurchaseService.getRemoveAdsPackage())
            .thenAnswer((_) async => Right(mockRemoveAdsPackage));
        when(() => mockPurchaseService.purchasePackage(mockRemoveAdsPackage))
            .thenAnswer((_) async => Right(mockCustomerInfo));

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Scroll to make the remove ads section visible
        final scrollableFinder = find.byType(SingleChildScrollView);
        await tester.dragUntilVisible(
          find.text('One-time purchase'),
          scrollableFinder,
          const Offset(0, -200),
        );
        await tester.pumpAndSettle();

        // Tap on the remove ads card (find by price since Remove Ads text might conflict)
        await tester.tap(find.text('\$3.99').last);
        await tester.pump();

        verify(() => mockPurchaseService.purchasePackage(mockRemoveAdsPackage)).called(1);
      });

      testWidgets('shows success message after purchasing remove ads', (tester) async {
        when(() => mockPurchaseService.getOfferings())
            .thenAnswer((_) async => Right(mockOfferings));
        when(() => mockPurchaseService.getRemoveAdsPackage())
            .thenAnswer((_) async => Right(mockRemoveAdsPackage));
        when(() => mockPurchaseService.purchasePackage(mockRemoveAdsPackage))
            .thenAnswer((_) async => Right(mockCustomerInfo));

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Scroll to make the remove ads section visible
        final scrollableFinder = find.byType(SingleChildScrollView);
        await tester.dragUntilVisible(
          find.text('One-time purchase'),
          scrollableFinder,
          const Offset(0, -200),
        );
        await tester.pumpAndSettle();

        // Tap on the remove ads card
        await tester.tap(find.text('\$3.99').last);
        await tester.pumpAndSettle();

        expect(find.text('Ads removed successfully!'), findsOneWidget);
      });
    });

    group('restore purchases with remove_ads', () {
      testWidgets('shows success when restore finds remove_ads entitlement', (tester) async {
        final mockRemoveAdsEntitlement = MockEntitlementInfo();
        when(() => mockEntitlementInfos.active).thenReturn({
          'remove_ads': mockRemoveAdsEntitlement,
        });

        when(() => mockPurchaseService.getOfferings())
            .thenAnswer((_) async => Right(mockOfferings));
        when(() => mockPurchaseService.getRemoveAdsPackage())
            .thenAnswer((_) async => const Left(ProductNotAvailableFailure(productId: 'remove_ads')));
        when(() => mockPurchaseService.restorePurchases())
            .thenAnswer((_) async => Right(mockCustomerInfo));

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Scroll to make the restore purchases link visible
        final scrollableFinder = find.byType(SingleChildScrollView);
        await tester.dragUntilVisible(
          find.text('Restore Purchases'),
          scrollableFinder,
          const Offset(0, -200),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Restore Purchases'));
        await tester.pumpAndSettle();

        expect(find.text('Ads removed successfully!'), findsOneWidget);
      });
    });
  });
}
