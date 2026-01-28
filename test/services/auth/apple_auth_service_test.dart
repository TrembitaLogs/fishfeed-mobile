import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/services/secure_storage_service.dart';
import 'package:fishfeed/services/auth/apple_auth_service.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late MockSecureStorageService mockStorageService;
  late AppleAuthService appleAuthService;

  setUp(() {
    mockStorageService = MockSecureStorageService();
  });

  group('AppleAuthService.isAvailable', () {
    test('should return true when override is true', () async {
      appleAuthService = AppleAuthService(
        storageService: mockStorageService,
        isAvailableOverride: true,
      );

      final result = await appleAuthService.isAvailable();

      expect(result, isTrue);
    });

    test('should return false when override is false', () async {
      appleAuthService = AppleAuthService(
        storageService: mockStorageService,
        isAvailableOverride: false,
      );

      final result = await appleAuthService.isAvailable();

      expect(result, isFalse);
    });
  });

  group('AppleAuthService.signIn', () {
    test(
      'should throw notAvailable when Sign in with Apple is not available',
      () async {
        appleAuthService = AppleAuthService(
          storageService: mockStorageService,
          isAvailableOverride: false,
        );

        expect(
          () => appleAuthService.signIn(),
          throwsA(
            isA<AppleAuthException>()
                .having((e) => e.code, 'code', AppleAuthErrorCode.notAvailable)
                .having(
                  (e) => e.message,
                  'message',
                  'Sign in with Apple is not available on this device',
                ),
          ),
        );
      },
    );
  });

  group('AppleAuthService.getIdToken', () {
    test('should throw tokenError when no cached credential', () {
      appleAuthService = AppleAuthService(
        storageService: mockStorageService,
        isAvailableOverride: true,
      );

      expect(
        () => appleAuthService.getIdToken(),
        throwsA(
          isA<AppleAuthException>()
              .having((e) => e.code, 'code', AppleAuthErrorCode.tokenError)
              .having(
                (e) => e.message,
                'message',
                'No cached credential available. Call signIn() first.',
              ),
        ),
      );
    });
  });

  group('AppleAuthService.signOut', () {
    test('should clear cached credential without throwing', () {
      appleAuthService = AppleAuthService(
        storageService: mockStorageService,
        isAvailableOverride: true,
      );

      // Should not throw
      appleAuthService.signOut();

      // Verify getIdToken throws after signOut
      expect(
        () => appleAuthService.getIdToken(),
        throwsA(isA<AppleAuthException>()),
      );
    });
  });

  group('AppleAuthService.clearStoredUserInfo', () {
    test('should call clearAppleUserInfo on storage service', () async {
      appleAuthService = AppleAuthService(
        storageService: mockStorageService,
        isAvailableOverride: true,
      );

      when(
        () => mockStorageService.clearAppleUserInfo(),
      ).thenAnswer((_) async {});

      await appleAuthService.clearStoredUserInfo();

      verify(() => mockStorageService.clearAppleUserInfo()).called(1);
    });

    test('should not throw when storage service is null', () async {
      appleAuthService = AppleAuthService(
        storageService: null,
        isAvailableOverride: true,
      );

      // Should not throw
      await appleAuthService.clearStoredUserInfo();
    });

    test('should not throw when clearAppleUserInfo fails', () async {
      appleAuthService = AppleAuthService(
        storageService: mockStorageService,
        isAvailableOverride: true,
      );

      when(
        () => mockStorageService.clearAppleUserInfo(),
      ).thenThrow(Exception('Storage error'));

      // Should not throw
      await appleAuthService.clearStoredUserInfo();
    });
  });

  group('AppleAuthException', () {
    test('toString should include code', () {
      const exception = AppleAuthException(AppleAuthErrorCode.cancelled);
      expect(
        exception.toString(),
        'AppleAuthException(AppleAuthErrorCode.cancelled)',
      );
    });

    test('toString should include code and message', () {
      const exception = AppleAuthException(
        AppleAuthErrorCode.notAvailable,
        'Not available on this platform',
      );
      expect(
        exception.toString(),
        'AppleAuthException(AppleAuthErrorCode.notAvailable: Not available on this platform)',
      );
    });
  });

  group('AppleSignInResult', () {
    test('displayName should return full name when both parts are present', () {
      const result = AppleSignInResult(
        identityToken: 'token',
        authorizationCode: 'code',
        userIdentifier: 'user123',
        email: 'test@example.com',
        givenName: 'John',
        familyName: 'Doe',
      );

      expect(result.displayName, 'John Doe');
    });

    test(
      'displayName should return given name when only given name is present',
      () {
        const result = AppleSignInResult(
          identityToken: 'token',
          authorizationCode: 'code',
          userIdentifier: 'user123',
          givenName: 'John',
        );

        expect(result.displayName, 'John');
      },
    );

    test(
      'displayName should return family name when only family name is present',
      () {
        const result = AppleSignInResult(
          identityToken: 'token',
          authorizationCode: 'code',
          userIdentifier: 'user123',
          familyName: 'Doe',
        );

        expect(result.displayName, 'Doe');
      },
    );

    test('displayName should return null when no name parts are present', () {
      const result = AppleSignInResult(
        identityToken: 'token',
        authorizationCode: 'code',
        userIdentifier: 'user123',
      );

      expect(result.displayName, isNull);
    });
  });
}
