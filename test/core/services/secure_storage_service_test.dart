import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/services/secure_storage_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late SecureStorageService secureStorageService;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    secureStorageService = SecureStorageService(storage: mockStorage);
  });

  group('SecureStorageService - Token Operations', () {
    test('getAccessToken should return stored token', () async {
      when(() => mockStorage.read(key: SecureStorageKeys.accessToken))
          .thenAnswer((_) async => 'test_access_token');

      final token = await secureStorageService.getAccessToken();

      expect(token, 'test_access_token');
      verify(() => mockStorage.read(key: SecureStorageKeys.accessToken))
          .called(1);
    });

    test('setAccessToken should write token to storage', () async {
      when(() => mockStorage.write(
            key: SecureStorageKeys.accessToken,
            value: 'new_token',
          )).thenAnswer((_) async {});

      await secureStorageService.setAccessToken('new_token');

      verify(() => mockStorage.write(
            key: SecureStorageKeys.accessToken,
            value: 'new_token',
          )).called(1);
    });

    test('hasTokens should return true when access token exists', () async {
      when(() => mockStorage.read(key: SecureStorageKeys.accessToken))
          .thenAnswer((_) async => 'valid_token');

      final result = await secureStorageService.hasTokens();

      expect(result, isTrue);
    });

    test('hasTokens should return false when access token is null', () async {
      when(() => mockStorage.read(key: SecureStorageKeys.accessToken))
          .thenAnswer((_) async => null);

      final result = await secureStorageService.hasTokens();

      expect(result, isFalse);
    });

    test('hasTokens should return false when access token is empty', () async {
      when(() => mockStorage.read(key: SecureStorageKeys.accessToken))
          .thenAnswer((_) async => '');

      final result = await secureStorageService.hasTokens();

      expect(result, isFalse);
    });

    test('clearTokens should delete both tokens', () async {
      when(() => mockStorage.delete(key: SecureStorageKeys.accessToken))
          .thenAnswer((_) async {});
      when(() => mockStorage.delete(key: SecureStorageKeys.refreshToken))
          .thenAnswer((_) async {});

      await secureStorageService.clearTokens();

      verify(() => mockStorage.delete(key: SecureStorageKeys.accessToken))
          .called(1);
      verify(() => mockStorage.delete(key: SecureStorageKeys.refreshToken))
          .called(1);
    });
  });

  group('SecureStorageService - Apple User Info', () {
    test('setAppleUserInfo should write all provided fields', () async {
      when(() => mockStorage.write(
            key: SecureStorageKeys.appleUserIdentifier,
            value: 'user123',
          )).thenAnswer((_) async {});
      when(() => mockStorage.write(
            key: SecureStorageKeys.appleUserEmail,
            value: 'test@example.com',
          )).thenAnswer((_) async {});
      when(() => mockStorage.write(
            key: SecureStorageKeys.appleUserGivenName,
            value: 'John',
          )).thenAnswer((_) async {});
      when(() => mockStorage.write(
            key: SecureStorageKeys.appleUserFamilyName,
            value: 'Doe',
          )).thenAnswer((_) async {});

      await secureStorageService.setAppleUserInfo(
        userIdentifier: 'user123',
        email: 'test@example.com',
        givenName: 'John',
        familyName: 'Doe',
      );

      verify(() => mockStorage.write(
            key: SecureStorageKeys.appleUserIdentifier,
            value: 'user123',
          )).called(1);
      verify(() => mockStorage.write(
            key: SecureStorageKeys.appleUserEmail,
            value: 'test@example.com',
          )).called(1);
      verify(() => mockStorage.write(
            key: SecureStorageKeys.appleUserGivenName,
            value: 'John',
          )).called(1);
      verify(() => mockStorage.write(
            key: SecureStorageKeys.appleUserFamilyName,
            value: 'Doe',
          )).called(1);
    });

    test('setAppleUserInfo should only write non-null fields', () async {
      when(() => mockStorage.write(
            key: SecureStorageKeys.appleUserIdentifier,
            value: 'user123',
          )).thenAnswer((_) async {});

      await secureStorageService.setAppleUserInfo(
        userIdentifier: 'user123',
      );

      verify(() => mockStorage.write(
            key: SecureStorageKeys.appleUserIdentifier,
            value: 'user123',
          )).called(1);
      verifyNever(() => mockStorage.write(
            key: SecureStorageKeys.appleUserEmail,
            value: any(named: 'value'),
          ));
      verifyNever(() => mockStorage.write(
            key: SecureStorageKeys.appleUserGivenName,
            value: any(named: 'value'),
          ));
      verifyNever(() => mockStorage.write(
            key: SecureStorageKeys.appleUserFamilyName,
            value: any(named: 'value'),
          ));
    });

    test('getAppleUserInfo should return stored user info', () async {
      when(() => mockStorage.read(key: SecureStorageKeys.appleUserIdentifier))
          .thenAnswer((_) async => 'user123');
      when(() => mockStorage.read(key: SecureStorageKeys.appleUserEmail))
          .thenAnswer((_) async => 'test@example.com');
      when(() => mockStorage.read(key: SecureStorageKeys.appleUserGivenName))
          .thenAnswer((_) async => 'John');
      when(() => mockStorage.read(key: SecureStorageKeys.appleUserFamilyName))
          .thenAnswer((_) async => 'Doe');

      final result = await secureStorageService.getAppleUserInfo();

      expect(result, isNotNull);
      expect(result!.userIdentifier, 'user123');
      expect(result.email, 'test@example.com');
      expect(result.givenName, 'John');
      expect(result.familyName, 'Doe');
    });

    test('getAppleUserInfo should return null when no user identifier stored',
        () async {
      when(() => mockStorage.read(key: SecureStorageKeys.appleUserIdentifier))
          .thenAnswer((_) async => null);

      final result = await secureStorageService.getAppleUserInfo();

      expect(result, isNull);
    });

    test('clearAppleUserInfo should delete all Apple user fields', () async {
      when(() => mockStorage.delete(key: SecureStorageKeys.appleUserIdentifier))
          .thenAnswer((_) async {});
      when(() => mockStorage.delete(key: SecureStorageKeys.appleUserEmail))
          .thenAnswer((_) async {});
      when(() => mockStorage.delete(key: SecureStorageKeys.appleUserGivenName))
          .thenAnswer((_) async {});
      when(() => mockStorage.delete(key: SecureStorageKeys.appleUserFamilyName))
          .thenAnswer((_) async {});

      await secureStorageService.clearAppleUserInfo();

      verify(() =>
              mockStorage.delete(key: SecureStorageKeys.appleUserIdentifier))
          .called(1);
      verify(() => mockStorage.delete(key: SecureStorageKeys.appleUserEmail))
          .called(1);
      verify(
              () => mockStorage.delete(key: SecureStorageKeys.appleUserGivenName))
          .called(1);
      verify(() =>
              mockStorage.delete(key: SecureStorageKeys.appleUserFamilyName))
          .called(1);
    });
  });

  group('AppleUserInfo', () {
    test('displayName should return full name when both parts present', () {
      const userInfo = AppleUserInfo(
        userIdentifier: 'user123',
        email: 'test@example.com',
        givenName: 'John',
        familyName: 'Doe',
      );

      expect(userInfo.displayName, 'John Doe');
    });

    test('displayName should return given name when family name is null', () {
      const userInfo = AppleUserInfo(
        userIdentifier: 'user123',
        givenName: 'John',
      );

      expect(userInfo.displayName, 'John');
    });

    test('displayName should return null when both name parts are null', () {
      const userInfo = AppleUserInfo(
        userIdentifier: 'user123',
        email: 'test@example.com',
      );

      expect(userInfo.displayName, isNull);
    });
  });
}
