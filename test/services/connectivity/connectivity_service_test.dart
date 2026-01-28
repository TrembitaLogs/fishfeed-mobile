import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/services/connectivity/connectivity_service.dart';

class MockConnectivity extends Mock implements Connectivity {}

void main() {
  late MockConnectivity mockConnectivity;
  late ConnectivityService service;
  late StreamController<List<ConnectivityResult>> connectivityController;

  setUp(() {
    mockConnectivity = MockConnectivity();
    connectivityController = StreamController<List<ConnectivityResult>>.broadcast();

    when(() => mockConnectivity.checkConnectivity())
        .thenAnswer((_) async => [ConnectivityResult.wifi]);

    when(() => mockConnectivity.onConnectivityChanged)
        .thenAnswer((_) => connectivityController.stream);

    service = ConnectivityService(connectivity: mockConnectivity);
  });

  tearDown(() {
    service.dispose();
    connectivityController.close();
  });

  group('ConnectivityService', () {
    test('isOnline is true by default', () {
      expect(service.isOnline, isTrue);
    });

    test('isInitialized is false before initialize', () {
      expect(service.isInitialized, isFalse);
    });

    group('initialize', () {
      test('sets isInitialized to true', () async {
        await service.initialize();

        expect(service.isInitialized, isTrue);
      });

      test('checks initial connectivity', () async {
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);

        await service.initialize();

        expect(service.isOnline, isTrue);
        verify(() => mockConnectivity.checkConnectivity()).called(1);
      });

      test('sets offline when no connectivity', () async {
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);

        await service.initialize();

        expect(service.isOnline, isFalse);
      });

      test('only initializes once', () async {
        await service.initialize();
        await service.initialize();

        verify(() => mockConnectivity.checkConnectivity()).called(1);
      });
    });

    group('connectivity changes', () {
      test('emits status changes on stream', () async {
        await service.initialize();

        final statuses = <bool>[];
        service.statusStream.listen(statuses.add);

        connectivityController.add([ConnectivityResult.none]);
        await Future<void>.delayed(Duration.zero);

        expect(statuses, contains(false));
      });

      test('updates isOnline when connectivity changes', () async {
        await service.initialize();

        expect(service.isOnline, isTrue);

        connectivityController.add([ConnectivityResult.none]);
        await Future<void>.delayed(Duration.zero);

        expect(service.isOnline, isFalse);
      });

      test('does not emit when status stays the same', () async {
        await service.initialize();

        final statuses = <bool>[];
        service.statusStream.listen(statuses.add);

        connectivityController.add([ConnectivityResult.wifi]);
        await Future<void>.delayed(Duration.zero);

        // No change emitted since we were already online
        expect(statuses, isEmpty);
      });
    });

    group('checkConnectivity', () {
      test('returns current status', () async {
        await service.initialize();

        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);

        final result = await service.checkConnectivity();

        expect(result, isTrue);
      });

      test('updates isOnline', () async {
        await service.initialize();

        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);

        await service.checkConnectivity();

        expect(service.isOnline, isFalse);
      });
    });

    group('dispose', () {
      test('cancels subscription', () async {
        await service.initialize();

        service.dispose();

        expect(service.isInitialized, isFalse);
      });
    });
  });
}
