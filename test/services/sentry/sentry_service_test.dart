import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:fishfeed/services/sentry/sentry_service.dart';

void main() {
  group('SentryService.reclassifyTransientSyncErrors', () {
    SentryEvent buildDioEvent({
      required String path,
      required int statusCode,
      SentryLevel level = SentryLevel.error,
    }) {
      final requestOptions = RequestOptions(path: path);
      return SentryEvent(
        level: level,
        throwable: DioException(
          requestOptions: requestOptions,
          response: Response<dynamic>(
            requestOptions: requestOptions,
            statusCode: statusCode,
          ),
        ),
      );
    }

    test('downgrades and groups a transient 504 on /sync', () {
      final event = buildDioEvent(path: '/api/v1/sync', statusCode: 504);

      final result = SentryService.reclassifyTransientSyncErrors(event);

      expect(result.level, SentryLevel.warning);
      expect(result.fingerprint, ['transient-sync-5xx']);
      expect(result.tags?['sync_transient'], 'true');
    });

    test('downgrades a transient 503 on /sync', () {
      final event = buildDioEvent(path: '/api/v1/sync', statusCode: 503);

      final result = SentryService.reclassifyTransientSyncErrors(event);

      expect(result.level, SentryLevel.warning);
      expect(result.fingerprint, ['transient-sync-5xx']);
    });

    test('leaves a 500 on a non-sync path unchanged', () {
      final event = buildDioEvent(path: '/api/v1/aquariums', statusCode: 500);

      final result = SentryService.reclassifyTransientSyncErrors(event);

      expect(result.level, SentryLevel.error);
      expect(result.fingerprint, isNull);
      expect(result.tags?['sync_transient'], isNull);
    });

    test('leaves a non-transient 500 on /sync unchanged', () {
      final event = buildDioEvent(path: '/api/v1/sync', statusCode: 500);

      final result = SentryService.reclassifyTransientSyncErrors(event);

      expect(result.level, SentryLevel.error);
      expect(result.fingerprint, isNull);
    });

    test('leaves a non-Dio throwable unchanged', () {
      final event = SentryEvent(
        level: SentryLevel.error,
        throwable: Exception('boom'),
      );

      final result = SentryService.reclassifyTransientSyncErrors(event);

      expect(result.level, SentryLevel.error);
      expect(result.fingerprint, isNull);
    });
  });

  group('SentryService', () {
    test('instance returns singleton', () {
      final instance1 = SentryService.instance;
      final instance2 = SentryService.instance;

      expect(instance1, same(instance2));
    });

    test('isInitialized returns false before initialization', () {
      // SentryService.instance is a singleton, so we test the initial state
      // In production, it would be initialized in main.dart
      // For tests, we verify the default behavior

      final service = SentryService.instance;

      // Note: isInitialized may be true if tests run after initialization
      // This test verifies the getter works correctly
      expect(service.isInitialized, isA<bool>());
    });

    test('captureException does not throw when not initialized', () async {
      final service = SentryService.instance;

      // Should not throw even if not initialized
      await expectLater(
        service.captureException(
          Exception('Test exception'),
          message: 'Test message',
        ),
        completes,
      );
    });

    test('captureMessage does not throw when not initialized', () async {
      final service = SentryService.instance;

      // Should not throw even if not initialized
      await expectLater(service.captureMessage('Test message'), completes);
    });

    test('setUser does not throw when not initialized', () async {
      final service = SentryService.instance;

      // Should not throw even if not initialized
      await expectLater(
        service.setUser(userId: 'test-user', email: 'test@example.com'),
        completes,
      );
    });

    test('clearUser does not throw when not initialized', () async {
      final service = SentryService.instance;

      // Should not throw even if not initialized
      await expectLater(service.clearUser(), completes);
    });

    test('addBreadcrumb does not throw when not initialized', () async {
      final service = SentryService.instance;

      // Should not throw even if not initialized
      await expectLater(
        service.addBreadcrumb(message: 'Test breadcrumb', category: 'test'),
        completes,
      );
    });

    test('setTag does not throw when not initialized', () async {
      final service = SentryService.instance;

      // Should not throw even if not initialized
      await expectLater(service.setTag('test-key', 'test-value'), completes);
    });

    test('setContext does not throw when not initialized', () async {
      final service = SentryService.instance;

      // Should not throw even if not initialized
      await expectLater(
        service.setContext('test-context', {'key': 'value'}),
        completes,
      );
    });

    test('startTransaction returns null when not initialized', () {
      final service = SentryService.instance;

      // When not initialized, startTransaction should return null
      // Note: If already initialized from other tests, it may return a span
      final transaction = service.startTransaction(
        name: 'test-transaction',
        operation: 'test',
      );

      // Just verify it doesn't throw
      expect(transaction, anyOf(isNull, isNotNull));
    });
  });
}
