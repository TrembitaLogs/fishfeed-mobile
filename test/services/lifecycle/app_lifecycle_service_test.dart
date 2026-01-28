import 'package:flutter_test/flutter_test.dart';

import 'package:fishfeed/services/lifecycle/app_lifecycle_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLifecycleService service;

  setUp(() {
    service = AppLifecycleService();
  });

  tearDown(() {
    service.dispose();
  });

  group('AppLifecycleService', () {
    group('initialization', () {
      test('isInitialized is false before initialize', () {
        expect(service.isInitialized, isFalse);
      });

      test('isInitialized is true after initialize', () {
        service.initialize();

        expect(service.isInitialized, isTrue);
      });

      test('only initializes once', () {
        service.initialize();
        service.initialize();

        expect(service.isInitialized, isTrue);
      });
    });

    group('dispose', () {
      test('sets isInitialized to false', () {
        service.initialize();

        expect(service.isInitialized, isTrue);

        service.dispose();

        expect(service.isInitialized, isFalse);
      });
    });

    group('eventStream', () {
      test('emits events as stream', () {
        service.initialize();

        expect(service.eventStream, isA<Stream<LifecycleEventData>>());
      });
    });
  });

  group('LifecycleEventData', () {
    test('creates with required parameters', () {
      final data = LifecycleEventData(
        event: AppLifecycleEvent.resumed,
        timestamp: DateTime.now(),
      );

      expect(data.event, AppLifecycleEvent.resumed);
      expect(data.previousTimestamp, isNull);
      expect(data.previousTimezoneOffset, isNull);
    });

    test('creates with all parameters', () {
      final now = DateTime.now();
      final previous = now.subtract(const Duration(hours: 2));
      const offset = Duration(hours: 1);

      final data = LifecycleEventData(
        event: AppLifecycleEvent.resumed,
        timestamp: now,
        previousTimestamp: previous,
        previousTimezoneOffset: offset,
      );

      expect(data.event, AppLifecycleEvent.resumed);
      expect(data.timestamp, now);
      expect(data.previousTimestamp, previous);
      expect(data.previousTimezoneOffset, offset);
    });

    group('backgroundDuration', () {
      test('returns null for non-resumed events', () {
        final data = LifecycleEventData(
          event: AppLifecycleEvent.paused,
          timestamp: DateTime.now(),
        );

        expect(data.backgroundDuration, isNull);
      });

      test('returns null when previousTimestamp is null', () {
        final data = LifecycleEventData(
          event: AppLifecycleEvent.resumed,
          timestamp: DateTime.now(),
        );

        expect(data.backgroundDuration, isNull);
      });

      test('returns duration for resumed events with previousTimestamp', () {
        final now = DateTime.now();
        final previous = now.subtract(const Duration(hours: 2));

        final data = LifecycleEventData(
          event: AppLifecycleEvent.resumed,
          timestamp: now,
          previousTimestamp: previous,
        );

        expect(data.backgroundDuration, const Duration(hours: 2));
      });
    });
  });

  group('AppLifecycleEvent', () {
    test('has all expected values', () {
      expect(AppLifecycleEvent.values, contains(AppLifecycleEvent.resumed));
      expect(AppLifecycleEvent.values, contains(AppLifecycleEvent.paused));
      expect(
        AppLifecycleEvent.values,
        contains(AppLifecycleEvent.midnightCrossed),
      );
      expect(
        AppLifecycleEvent.values,
        contains(AppLifecycleEvent.dstTransition),
      );
    });
  });
}
