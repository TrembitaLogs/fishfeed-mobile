import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/data/datasources/local/auth_local_ds.dart';
import 'package:fishfeed/data/models/user_model.dart';
import 'package:fishfeed/domain/entities/subscription_status.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockBox extends Mock implements Box<dynamic> {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late AuthLocalDataSource authLocalDataSource;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    authLocalDataSource = AuthLocalDataSource(storage: mockStorage);
  });

  group('AuthStorageKeys', () {
    test('should have correct key names', () {
      expect(AuthStorageKeys.accessToken, 'access_token');
      expect(AuthStorageKeys.refreshToken, 'refresh_token');
      expect(AuthStorageKeys.tokenExpiry, 'token_expiry');
    });
  });

  group('saveTokens', () {
    const testAccessToken = 'test_access_token_123';
    const testRefreshToken = 'test_refresh_token_456';
    final testExpiry = DateTime(2025, 12, 31, 23, 59, 59);

    test('should save all tokens to secure storage', () async {
      when(
        () => mockStorage.write(
          key: any<String>(named: 'key'),
          value: any<String?>(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      await authLocalDataSource.saveTokens(
        accessToken: testAccessToken,
        refreshToken: testRefreshToken,
        expiry: testExpiry,
      );

      verify(
        () => mockStorage.write(
          key: AuthStorageKeys.accessToken,
          value: testAccessToken,
        ),
      ).called(1);

      verify(
        () => mockStorage.write(
          key: AuthStorageKeys.refreshToken,
          value: testRefreshToken,
        ),
      ).called(1);

      verify(
        () => mockStorage.write(
          key: AuthStorageKeys.tokenExpiry,
          value: testExpiry.toIso8601String(),
        ),
      ).called(1);
    });
  });

  group('getAccessToken', () {
    test('should return access token when exists', () async {
      const expectedToken = 'stored_access_token';
      when(
        () => mockStorage.read(key: AuthStorageKeys.accessToken),
      ).thenAnswer((_) async => expectedToken);

      final result = await authLocalDataSource.getAccessToken();

      expect(result, expectedToken);
      verify(
        () => mockStorage.read(key: AuthStorageKeys.accessToken),
      ).called(1);
    });

    test('should return null when no access token exists', () async {
      when(
        () => mockStorage.read(key: AuthStorageKeys.accessToken),
      ).thenAnswer((_) async => null);

      final result = await authLocalDataSource.getAccessToken();

      expect(result, isNull);
    });
  });

  group('getRefreshToken', () {
    test('should return refresh token when exists', () async {
      const expectedToken = 'stored_refresh_token';
      when(
        () => mockStorage.read(key: AuthStorageKeys.refreshToken),
      ).thenAnswer((_) async => expectedToken);

      final result = await authLocalDataSource.getRefreshToken();

      expect(result, expectedToken);
      verify(
        () => mockStorage.read(key: AuthStorageKeys.refreshToken),
      ).called(1);
    });

    test('should return null when no refresh token exists', () async {
      when(
        () => mockStorage.read(key: AuthStorageKeys.refreshToken),
      ).thenAnswer((_) async => null);

      final result = await authLocalDataSource.getRefreshToken();

      expect(result, isNull);
    });
  });

  group('getTokenExpiry', () {
    test('should return DateTime when valid expiry exists', () async {
      final expectedExpiry = DateTime(2025, 12, 31, 23, 59, 59);
      when(
        () => mockStorage.read(key: AuthStorageKeys.tokenExpiry),
      ).thenAnswer((_) async => expectedExpiry.toIso8601String());

      final result = await authLocalDataSource.getTokenExpiry();

      expect(result, expectedExpiry);
      verify(
        () => mockStorage.read(key: AuthStorageKeys.tokenExpiry),
      ).called(1);
    });

    test('should return null when no expiry exists', () async {
      when(
        () => mockStorage.read(key: AuthStorageKeys.tokenExpiry),
      ).thenAnswer((_) async => null);

      final result = await authLocalDataSource.getTokenExpiry();

      expect(result, isNull);
    });

    test('should return null when expiry string is invalid', () async {
      when(
        () => mockStorage.read(key: AuthStorageKeys.tokenExpiry),
      ).thenAnswer((_) async => 'invalid_date_string');

      final result = await authLocalDataSource.getTokenExpiry();

      expect(result, isNull);
    });
  });

  group('isTokenValid', () {
    test('should return true when token exists and not expired', () async {
      const testAccessToken = 'valid_access_token';
      final futureExpiry = DateTime.now().add(const Duration(hours: 1));

      when(
        () => mockStorage.read(key: AuthStorageKeys.accessToken),
      ).thenAnswer((_) async => testAccessToken);
      when(
        () => mockStorage.read(key: AuthStorageKeys.tokenExpiry),
      ).thenAnswer((_) async => futureExpiry.toIso8601String());

      final result = await authLocalDataSource.isTokenValid();

      expect(result, isTrue);
    });

    test('should return false when no access token exists', () async {
      when(
        () => mockStorage.read(key: AuthStorageKeys.accessToken),
      ).thenAnswer((_) async => null);

      final result = await authLocalDataSource.isTokenValid();

      expect(result, isFalse);
    });

    test('should return false when no expiry exists', () async {
      when(
        () => mockStorage.read(key: AuthStorageKeys.accessToken),
      ).thenAnswer((_) async => 'some_token');
      when(
        () => mockStorage.read(key: AuthStorageKeys.tokenExpiry),
      ).thenAnswer((_) async => null);

      final result = await authLocalDataSource.isTokenValid();

      expect(result, isFalse);
    });

    test('should return false when token has expired', () async {
      const testAccessToken = 'expired_access_token';
      final pastExpiry = DateTime.now().subtract(const Duration(hours: 1));

      when(
        () => mockStorage.read(key: AuthStorageKeys.accessToken),
      ).thenAnswer((_) async => testAccessToken);
      when(
        () => mockStorage.read(key: AuthStorageKeys.tokenExpiry),
      ).thenAnswer((_) async => pastExpiry.toIso8601String());

      final result = await authLocalDataSource.isTokenValid();

      expect(result, isFalse);
    });

    test('should return false when expiry is exactly now', () async {
      const testAccessToken = 'edge_case_token';
      final exactlyNow = DateTime.now();

      when(
        () => mockStorage.read(key: AuthStorageKeys.accessToken),
      ).thenAnswer((_) async => testAccessToken);
      when(
        () => mockStorage.read(key: AuthStorageKeys.tokenExpiry),
      ).thenAnswer((_) async => exactlyNow.toIso8601String());

      final result = await authLocalDataSource.isTokenValid();

      expect(result, isFalse);
    });
  });

  group('clearTokens', () {
    test('should delete all tokens from secure storage', () async {
      when(
        () => mockStorage.delete(key: any<String>(named: 'key')),
      ).thenAnswer((_) async {});

      await authLocalDataSource.clearTokens();

      verify(
        () => mockStorage.delete(key: AuthStorageKeys.accessToken),
      ).called(1);
      verify(
        () => mockStorage.delete(key: AuthStorageKeys.refreshToken),
      ).called(1);
      verify(
        () => mockStorage.delete(key: AuthStorageKeys.tokenExpiry),
      ).called(1);
    });
  });

  group('AuthLocalDataSource constructor', () {
    test('should create instance with default storage when none provided', () {
      final ds = AuthLocalDataSource();
      expect(ds, isA<AuthLocalDataSource>());
    });

    test('should use provided storage instance', () async {
      when(
        () => mockStorage.read(key: AuthStorageKeys.accessToken),
      ).thenAnswer((_) async => 'custom_token');

      final result = await authLocalDataSource.getAccessToken();

      expect(result, 'custom_token');
      verify(
        () => mockStorage.read(key: AuthStorageKeys.accessToken),
      ).called(1);
    });
  });

  group('User Data Methods', () {
    late MockBox mockUsersBox;
    late AuthLocalDataSource authDsWithUsersBox;

    final testUser = UserModel(
      id: 'user_123',
      email: 'test@example.com',
      displayName: 'Test User',
      createdAt: DateTime(2025, 1, 1),
      subscriptionStatus: const SubscriptionStatus.free(),
      freeAiScansRemaining: 5,
    );

    setUp(() {
      mockUsersBox = MockBox();
      authDsWithUsersBox = AuthLocalDataSource(
        storage: mockStorage,
        usersBox: mockUsersBox,
      );
    });

    group('saveUserLocally', () {
      test('should save user to Hive box', () async {
        when(
          () => mockUsersBox.put(any<dynamic>(), any<dynamic>()),
        ).thenAnswer((_) async {});

        await authDsWithUsersBox.saveUserLocally(testUser);

        verify(() => mockUsersBox.put('current_user', testUser)).called(1);
      });
    });

    group('getCurrentUser', () {
      test('should return user when exists', () {
        when(() => mockUsersBox.get('current_user')).thenReturn(testUser);

        final result = authDsWithUsersBox.getCurrentUser();

        expect(result, testUser);
        expect(result?.id, 'user_123');
        expect(result?.email, 'test@example.com');
      });

      test('should return null when no user exists', () {
        when(() => mockUsersBox.get('current_user')).thenReturn(null);

        final result = authDsWithUsersBox.getCurrentUser();

        expect(result, isNull);
      });

      test('should return null when stored value is not UserModel', () {
        when(() => mockUsersBox.get('current_user')).thenReturn('invalid_data');

        final result = authDsWithUsersBox.getCurrentUser();

        expect(result, isNull);
      });
    });

    group('updateUserLocally', () {
      test('should save user to local storage', () async {
        when(
          () => mockUsersBox.put(any<dynamic>(), any<dynamic>()),
        ).thenAnswer((_) async {});

        final updatedUser = UserModel(
          id: 'user_123',
          email: 'updated@example.com',
          displayName: 'Updated Name',
          createdAt: DateTime(2025, 1, 1),
          subscriptionStatus: SubscriptionStatus.premium(),
          freeAiScansRemaining: 10,
        );

        await authDsWithUsersBox.updateUserLocally(updatedUser);

        verify(() => mockUsersBox.put('current_user', updatedUser)).called(1);
      });

      test('should save user even when no user previously exists', () async {
        when(
          () => mockUsersBox.put(any<dynamic>(), any<dynamic>()),
        ).thenAnswer((_) async {});

        await authDsWithUsersBox.updateUserLocally(testUser);

        verify(() => mockUsersBox.put('current_user', testUser)).called(1);
      });
    });

    group('clearUserData', () {
      test('should delete user from Hive box', () async {
        when(
          () => mockUsersBox.delete(any<dynamic>()),
        ).thenAnswer((_) async {});

        await authDsWithUsersBox.clearUserData();

        verify(() => mockUsersBox.delete('current_user')).called(1);
      });
    });

    group('clearAll', () {
      test('should clear both tokens and user data', () async {
        when(
          () => mockStorage.delete(key: any<String>(named: 'key')),
        ).thenAnswer((_) async {});
        when(
          () => mockUsersBox.delete(any<dynamic>()),
        ).thenAnswer((_) async {});

        await authDsWithUsersBox.clearAll();

        verify(
          () => mockStorage.delete(key: AuthStorageKeys.accessToken),
        ).called(1);
        verify(
          () => mockStorage.delete(key: AuthStorageKeys.refreshToken),
        ).called(1);
        verify(
          () => mockStorage.delete(key: AuthStorageKeys.tokenExpiry),
        ).called(1);
        verify(() => mockUsersBox.delete('current_user')).called(1);
      });
    });
  });
}
