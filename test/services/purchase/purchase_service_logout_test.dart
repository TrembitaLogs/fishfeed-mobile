import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fishfeed/services/purchase/purchase_service.dart';

/// Channel used by purchases_flutter 8.11.0 for every static `Purchases.*`
/// call (see purchases_flutter.dart: `const MethodChannel('purchases_flutter')`).
const MethodChannel _purchasesChannel = MethodChannel('purchases_flutter');

/// Minimal `EntitlementInfo` JSON accepted by
/// `_$$EntitlementInfoImplFromJson`.
Map<String, Object?> _entitlementJson(String identifier) => <String, Object?>{
  'identifier': identifier,
  'isActive': true,
  'willRenew': true,
  'latestPurchaseDate': '2026-07-01T00:00:00Z',
  'originalPurchaseDate': '2026-07-01T00:00:00Z',
  'productIdentifier': 'premium_monthly',
  'isSandbox': false,
  'ownershipType': 'PURCHASED',
  'store': 'PLAY_STORE',
  'periodType': 'NORMAL',
  'expirationDate': '2026-08-01T00:00:00Z',
  'verification': 'NOT_REQUESTED',
};

/// Minimal `CustomerInfo` JSON accepted by `_$$CustomerInfoImplFromJson`.
Map<String, Object?> _customerInfoJson({
  required String appUserId,
  required bool premium,
}) {
  final entitlements = premium
      ? <String, Object?>{
          PurchaseEntitlements.premium: _entitlementJson(
            PurchaseEntitlements.premium,
          ),
        }
      : <String, Object?>{};

  return <String, Object?>{
    'entitlements': <String, Object?>{
      'all': entitlements,
      'active': entitlements,
      'verification': 'NOT_REQUESTED',
    },
    'allPurchaseDates': <String, Object?>{},
    'activeSubscriptions': <String>[],
    'allPurchasedProductIdentifiers': <String>[],
    'nonSubscriptionTransactions': <Object?>[],
    'firstSeen': '2026-01-01T00:00:00Z',
    'originalAppUserId': appUserId,
    'allExpirationDates': <String, Object?>{},
    'requestDate': '2026-07-21T00:00:00Z',
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Every method name the service pushed onto the platform channel.
  final List<String> methodCalls = <String>[];

  /// Identity reported by `getCustomerInfo` / `logIn`.
  String appUserId = 'user-123';

  /// Whether the reported customer holds the premium entitlement.
  bool premium = true;

  /// When set, `getCustomerInfo` fails with this error.
  PlatformException? getCustomerInfoError;

  late PurchaseService service;

  setUpAll(() async {
    // No dotenv setup on purpose: passing the key to initialize() must be
    // enough, which is what makes this file platform-independent.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_purchasesChannel, (call) async {
          methodCalls.add(call.method);
          switch (call.method) {
            case 'getCustomerInfo':
              final error = getCustomerInfoError;
              if (error != null) {
                throw error;
              }
              return _customerInfoJson(appUserId: appUserId, premium: premium);
            case 'logIn':
              return <String, Object?>{
                'customerInfo': _customerInfoJson(
                  appUserId: appUserId,
                  premium: premium,
                ),
                'created': false,
              };
            case 'logOut':
              // RevenueCat resets the device to a fresh anonymous alias.
              return _customerInfoJson(
                appUserId: r'$RCAnonymousID:fresh',
                premium: false,
              );
            default:
              return null;
          }
        });

    service = PurchaseService.instance;
    // Explicit key: the platform lookup returns null on a Linux CI runner.
    await service.initialize(apiKey: 'fake-test-key');
    expect(service.isInitialized, isTrue);
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_purchasesChannel, null);
  });

  setUp(() {
    methodCalls.clear();
    appUserId = 'user-123';
    premium = true;
    getCustomerInfoError = null;
  });

  group('PurchaseService.logOut', () {
    test('still calls Purchases.logOut and drops entitlements when the '
        'anonymous probe fails with UnknownBackendError', () async {
      await service.logIn('user-123');
      expect(
        service.isPremium(),
        isTrue,
        reason: 'precondition: previous account is premium',
      );

      methodCalls.clear();
      // The exact production Sentry failure: PlatformException(16,
      // "There was an unknown backend error.", UnknownBackendError).
      getCustomerInfoError = PlatformException(
        code: '16',
        message: 'There was an unknown backend error.',
        details: <String, String>{'readableErrorCode': 'UnknownBackendError'},
      );

      await service.logOut();

      expect(
        methodCalls,
        contains('logOut'),
        reason:
            'a failing probe must not abort the logout, otherwise the '
            'previous account stays bound to this device',
      );
      expect(
        service.isPremium(),
        isFalse,
        reason: 'the next user must not inherit entitlements',
      );
    });

    test('logs out and clears entitlements on the happy path', () async {
      await service.logIn('user-123');
      expect(service.isPremium(), isTrue);

      methodCalls.clear();
      await service.logOut();

      expect(methodCalls, contains('logOut'));
      expect(service.isPremium(), isFalse);
    });

    test(
      'skips Purchases.logOut when the customer is already anonymous',
      () async {
        appUserId = r'$RCAnonymousID:existing';
        premium = false;

        await service.logOut();

        expect(methodCalls, contains('getCustomerInfo'));
        expect(methodCalls, isNot(contains('logOut')));
        expect(service.isPremium(), isFalse);
      },
    );
  });
}
