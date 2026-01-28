import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/services/auth/google_auth_service.dart';

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

class MockGoogleSignInAuthentication extends Mock
    implements GoogleSignInAuthentication {}

void main() {
  late MockGoogleSignIn mockGoogleSignIn;
  late GoogleAuthService googleAuthService;

  setUp(() {
    mockGoogleSignIn = MockGoogleSignIn();
    googleAuthService = GoogleAuthService(googleSignIn: mockGoogleSignIn);
  });

  group('GoogleAuthService.signIn', () {
    test('should return GoogleSignInResult on successful sign-in', () async {
      final mockAccount = MockGoogleSignInAccount();
      final mockAuth = MockGoogleSignInAuthentication();

      when(() => mockGoogleSignIn.signIn())
          .thenAnswer((_) async => mockAccount);
      when(() => mockAccount.authentication)
          .thenAnswer((_) async => mockAuth);
      when(() => mockAuth.idToken).thenReturn('test_id_token');
      when(() => mockAccount.email).thenReturn('test@example.com');
      when(() => mockAccount.displayName).thenReturn('Test User');
      when(() => mockAccount.photoUrl)
          .thenReturn('https://example.com/photo.jpg');

      final result = await googleAuthService.signIn();

      expect(result.idToken, 'test_id_token');
      expect(result.email, 'test@example.com');
      expect(result.displayName, 'Test User');
      expect(result.photoUrl, 'https://example.com/photo.jpg');
      verify(() => mockGoogleSignIn.signIn()).called(1);
    });

    test('should throw GoogleAuthException with cancelled code when user cancels',
        () async {
      when(() => mockGoogleSignIn.signIn()).thenAnswer((_) async => null);

      expect(
        () => googleAuthService.signIn(),
        throwsA(
          isA<GoogleAuthException>().having(
            (e) => e.code,
            'code',
            GoogleAuthErrorCode.cancelled,
          ),
        ),
      );
    });

    test(
        'should throw GoogleAuthException with tokenError when idToken is null',
        () async {
      final mockAccount = MockGoogleSignInAccount();
      final mockAuth = MockGoogleSignInAuthentication();

      when(() => mockGoogleSignIn.signIn())
          .thenAnswer((_) async => mockAccount);
      when(() => mockAccount.authentication)
          .thenAnswer((_) async => mockAuth);
      when(() => mockAuth.idToken).thenReturn(null);

      expect(
        () => googleAuthService.signIn(),
        throwsA(
          isA<GoogleAuthException>().having(
            (e) => e.code,
            'code',
            GoogleAuthErrorCode.tokenError,
          ),
        ),
      );
    });

    test(
        'should throw GoogleAuthException with cancelled code on sign_in_canceled PlatformException',
        () async {
      when(() => mockGoogleSignIn.signIn()).thenThrow(
        PlatformException(code: 'sign_in_canceled'),
      );

      expect(
        () => googleAuthService.signIn(),
        throwsA(
          isA<GoogleAuthException>().having(
            (e) => e.code,
            'code',
            GoogleAuthErrorCode.cancelled,
          ),
        ),
      );
    });

    test(
        'should throw GoogleAuthException with networkError code on network_error PlatformException',
        () async {
      when(() => mockGoogleSignIn.signIn()).thenThrow(
        PlatformException(code: 'network_error', message: 'No internet'),
      );

      expect(
        () => googleAuthService.signIn(),
        throwsA(
          isA<GoogleAuthException>()
              .having((e) => e.code, 'code', GoogleAuthErrorCode.networkError)
              .having((e) => e.message, 'message', 'No internet'),
        ),
      );
    });

    test(
        'should throw GoogleAuthException with configurationError code on configuration error',
        () async {
      when(() => mockGoogleSignIn.signIn()).thenThrow(
        PlatformException(
          code: 'sign_in_failed',
          message: 'configuration error',
        ),
      );

      expect(
        () => googleAuthService.signIn(),
        throwsA(
          isA<GoogleAuthException>().having(
            (e) => e.code,
            'code',
            GoogleAuthErrorCode.configurationError,
          ),
        ),
      );
    });

    test('should throw GoogleAuthException with unknown code on other errors',
        () async {
      when(() => mockGoogleSignIn.signIn()).thenThrow(
        PlatformException(code: 'unknown_error', message: 'Something failed'),
      );

      expect(
        () => googleAuthService.signIn(),
        throwsA(
          isA<GoogleAuthException>().having(
            (e) => e.code,
            'code',
            GoogleAuthErrorCode.unknown,
          ),
        ),
      );
    });

    test('should throw GoogleAuthException with unknown code on generic errors',
        () async {
      when(() => mockGoogleSignIn.signIn()).thenThrow(Exception('Generic error'));

      expect(
        () => googleAuthService.signIn(),
        throwsA(
          isA<GoogleAuthException>().having(
            (e) => e.code,
            'code',
            GoogleAuthErrorCode.unknown,
          ),
        ),
      );
    });
  });

  group('GoogleAuthService.signInSilently', () {
    test('should return GoogleSignInResult on successful silent sign-in',
        () async {
      final mockAccount = MockGoogleSignInAccount();
      final mockAuth = MockGoogleSignInAuthentication();

      when(() => mockGoogleSignIn.signInSilently())
          .thenAnswer((_) async => mockAccount);
      when(() => mockAccount.authentication)
          .thenAnswer((_) async => mockAuth);
      when(() => mockAuth.idToken).thenReturn('test_id_token');
      when(() => mockAccount.email).thenReturn('test@example.com');
      when(() => mockAccount.displayName).thenReturn('Test User');
      when(() => mockAccount.photoUrl).thenReturn(null);

      final result = await googleAuthService.signInSilently();

      expect(result, isNotNull);
      expect(result!.idToken, 'test_id_token');
      expect(result.email, 'test@example.com');
      expect(result.displayName, 'Test User');
      expect(result.photoUrl, isNull);
    });

    test('should return null when no account is signed in', () async {
      when(() => mockGoogleSignIn.signInSilently())
          .thenAnswer((_) async => null);

      final result = await googleAuthService.signInSilently();

      expect(result, isNull);
    });

    test('should return null when idToken is null', () async {
      final mockAccount = MockGoogleSignInAccount();
      final mockAuth = MockGoogleSignInAuthentication();

      when(() => mockGoogleSignIn.signInSilently())
          .thenAnswer((_) async => mockAccount);
      when(() => mockAccount.authentication)
          .thenAnswer((_) async => mockAuth);
      when(() => mockAuth.idToken).thenReturn(null);

      final result = await googleAuthService.signInSilently();

      expect(result, isNull);
    });

    test('should return null on exception', () async {
      when(() => mockGoogleSignIn.signInSilently())
          .thenThrow(Exception('Silent sign-in failed'));

      final result = await googleAuthService.signInSilently();

      expect(result, isNull);
    });
  });

  group('GoogleAuthService.getIdToken', () {
    test('should return idToken when user is signed in', () async {
      final mockAccount = MockGoogleSignInAccount();
      final mockAuth = MockGoogleSignInAuthentication();

      when(() => mockGoogleSignIn.currentUser).thenReturn(mockAccount);
      when(() => mockAccount.authentication)
          .thenAnswer((_) async => mockAuth);
      when(() => mockAuth.idToken).thenReturn('fresh_id_token');

      final token = await googleAuthService.getIdToken();

      expect(token, 'fresh_id_token');
    });

    test(
        'should throw GoogleAuthException with tokenError when no user is signed in',
        () async {
      when(() => mockGoogleSignIn.currentUser).thenReturn(null);

      expect(
        () => googleAuthService.getIdToken(),
        throwsA(
          isA<GoogleAuthException>()
              .having((e) => e.code, 'code', GoogleAuthErrorCode.tokenError)
              .having((e) => e.message, 'message', 'No user is signed in'),
        ),
      );
    });

    test('should throw GoogleAuthException with tokenError when idToken is null',
        () async {
      final mockAccount = MockGoogleSignInAccount();
      final mockAuth = MockGoogleSignInAuthentication();

      when(() => mockGoogleSignIn.currentUser).thenReturn(mockAccount);
      when(() => mockAccount.authentication)
          .thenAnswer((_) async => mockAuth);
      when(() => mockAuth.idToken).thenReturn(null);

      expect(
        () => googleAuthService.getIdToken(),
        throwsA(
          isA<GoogleAuthException>().having(
            (e) => e.code,
            'code',
            GoogleAuthErrorCode.tokenError,
          ),
        ),
      );
    });

    test(
        'should throw GoogleAuthException with tokenError on authentication failure',
        () async {
      final mockAccount = MockGoogleSignInAccount();

      when(() => mockGoogleSignIn.currentUser).thenReturn(mockAccount);
      when(() => mockAccount.authentication)
          .thenThrow(Exception('Auth failed'));

      expect(
        () => googleAuthService.getIdToken(),
        throwsA(
          isA<GoogleAuthException>().having(
            (e) => e.code,
            'code',
            GoogleAuthErrorCode.tokenError,
          ),
        ),
      );
    });
  });

  group('GoogleAuthService.signOut', () {
    test('should call signOut on GoogleSignIn', () async {
      when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async => null);

      await googleAuthService.signOut();

      verify(() => mockGoogleSignIn.signOut()).called(1);
    });

    test('should not throw on signOut error', () async {
      when(() => mockGoogleSignIn.signOut())
          .thenThrow(Exception('Sign-out failed'));

      // Should not throw
      await googleAuthService.signOut();

      verify(() => mockGoogleSignIn.signOut()).called(1);
    });
  });

  group('GoogleAuthService.disconnect', () {
    test('should call disconnect on GoogleSignIn', () async {
      when(() => mockGoogleSignIn.disconnect()).thenAnswer((_) async => null);

      await googleAuthService.disconnect();

      verify(() => mockGoogleSignIn.disconnect()).called(1);
    });

    test('should not throw on disconnect error', () async {
      when(() => mockGoogleSignIn.disconnect())
          .thenThrow(Exception('Disconnect failed'));

      // Should not throw
      await googleAuthService.disconnect();

      verify(() => mockGoogleSignIn.disconnect()).called(1);
    });
  });

  group('GoogleAuthService.currentUser', () {
    test('should return current user from GoogleSignIn', () {
      final mockAccount = MockGoogleSignInAccount();
      when(() => mockGoogleSignIn.currentUser).thenReturn(mockAccount);

      expect(googleAuthService.currentUser, mockAccount);
    });

    test('should return null when no user is signed in', () {
      when(() => mockGoogleSignIn.currentUser).thenReturn(null);

      expect(googleAuthService.currentUser, isNull);
    });
  });

  group('GoogleAuthService.isSignedIn', () {
    test('should return true when user is signed in', () {
      final mockAccount = MockGoogleSignInAccount();
      when(() => mockGoogleSignIn.currentUser).thenReturn(mockAccount);

      expect(googleAuthService.isSignedIn, isTrue);
    });

    test('should return false when no user is signed in', () {
      when(() => mockGoogleSignIn.currentUser).thenReturn(null);

      expect(googleAuthService.isSignedIn, isFalse);
    });
  });

  group('GoogleAuthException', () {
    test('toString should include code', () {
      const exception = GoogleAuthException(GoogleAuthErrorCode.cancelled);
      expect(exception.toString(), 'GoogleAuthException(GoogleAuthErrorCode.cancelled)');
    });

    test('toString should include code and message', () {
      const exception = GoogleAuthException(
        GoogleAuthErrorCode.networkError,
        'No internet connection',
      );
      expect(
        exception.toString(),
        'GoogleAuthException(GoogleAuthErrorCode.networkError: No internet connection)',
      );
    });
  });
}
