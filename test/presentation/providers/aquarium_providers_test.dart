import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/domain/entities/aquarium.dart';
import 'package:fishfeed/domain/entities/water_type.dart';
import 'package:fishfeed/domain/repositories/aquarium_repository.dart';
import 'package:fishfeed/presentation/providers/aquarium_providers.dart';

import '../../helpers/test_helpers.dart'
    show MockSyncService, createMockSyncService;

class MockAquariumRepository extends Mock implements AquariumRepository {}

void main() {
  late MockAquariumRepository mockRepository;
  late MockSyncService mockSyncService;

  final testAquarium = Aquarium(
    id: 'aq-1',
    userId: 'user-123',
    name: 'Living Room Tank',
    waterType: WaterType.freshwater,
    capacity: 50.0,
    createdAt: DateTime(2024, 1, 15),
  );

  final testAquarium2 = Aquarium(
    id: 'aq-2',
    userId: 'user-123',
    name: 'Bedroom Tank',
    waterType: WaterType.saltwater,
    createdAt: DateTime(2024, 2, 1),
  );

  setUp(() {
    mockRepository = MockAquariumRepository();
    mockSyncService = createMockSyncService();

    // Default: repository returns empty list
    when(
      () => mockRepository.getAquariums(),
    ).thenAnswer((_) async => const Right([]));
  });

  /// Helper to create notifier and wait for initial loadAquariums().
  Future<UserAquariumsNotifier> createNotifier({
    List<Aquarium> initialAquariums = const [],
  }) async {
    when(
      () => mockRepository.getAquariums(),
    ).thenAnswer((_) async => Right(initialAquariums));

    final notifier = UserAquariumsNotifier(
      aquariumRepository: mockRepository,
      syncService: mockSyncService,
    );

    // Wait for constructor's loadAquariums() to complete
    await Future<void>.delayed(Duration.zero);
    return notifier;
  }

  group('UserAquariumsNotifier', () {
    group('loadAquariums', () {
      test('should load aquariums on construction', () async {
        final notifier = await createNotifier(initialAquariums: [testAquarium]);

        expect(notifier.state.aquariums.length, 1);
        expect(notifier.state.aquariums[0].name, 'Living Room Tank');
        expect(notifier.state.isLoading, false);
      });

      test('should set error state on failure', () async {
        when(() => mockRepository.getAquariums()).thenAnswer(
          (_) async => const Left(CacheFailure(message: 'No aquariums cached')),
        );

        final notifier = UserAquariumsNotifier(
          aquariumRepository: mockRepository,
          syncService: mockSyncService,
        );

        await Future<void>.delayed(Duration.zero);

        expect(notifier.state.hasError, true);
        expect(notifier.state.error, 'No aquariums cached');
        expect(notifier.state.isLoading, false);
      });
    });

    group('refresh', () {
      test(
        'should call syncAll then reload aquariums from repository',
        () async {
          final notifier = await createNotifier();

          // After initial load, set up new data for refresh
          when(
            () => mockRepository.getAquariums(),
          ).thenAnswer((_) async => Right([testAquarium, testAquarium2]));

          await notifier.refresh();

          expect(notifier.state.aquariums.length, 2);
          expect(notifier.state.isRefreshing, false);
          verify(() => mockSyncService.syncAll()).called(1);
        },
      );

      test('should still reload aquariums when sync fails', () async {
        final notifier = await createNotifier();

        // Sync fails
        when(
          () => mockSyncService.syncAll(),
        ).thenThrow(Exception('Network error'));

        // But local repo returns data
        when(
          () => mockRepository.getAquariums(),
        ).thenAnswer((_) async => Right([testAquarium]));

        await notifier.refresh();

        expect(notifier.state.aquariums.length, 1);
        expect(notifier.state.aquariums[0].name, 'Living Room Tank');
        expect(notifier.state.isRefreshing, false);
        expect(notifier.state.hasError, false);
      });

      test('should set error state when repository fails after sync', () async {
        final notifier = await createNotifier();

        when(() => mockRepository.getAquariums()).thenAnswer(
          (_) async => const Left(CacheFailure(message: 'Cache error')),
        );

        await notifier.refresh();

        expect(notifier.state.error, 'Cache error');
        expect(notifier.state.isRefreshing, false);
      });

      test('should clear previous error on new refresh', () async {
        final notifier = await createNotifier();

        // First refresh fails
        when(
          () => mockRepository.getAquariums(),
        ).thenAnswer((_) async => const Left(CacheFailure(message: 'Error')));
        await notifier.refresh();
        expect(notifier.state.hasError, true);

        // Second refresh succeeds
        when(
          () => mockRepository.getAquariums(),
        ).thenAnswer((_) async => Right([testAquarium]));
        await notifier.refresh();

        expect(notifier.state.hasError, false);
        expect(notifier.state.aquariums.length, 1);
      });

      test('should use isRefreshing instead of isLoading', () async {
        final notifier = await createNotifier();

        final states = <UserAquariumsState>[];
        notifier.addListener((state) => states.add(state));

        when(
          () => mockRepository.getAquariums(),
        ).thenAnswer((_) async => const Right([]));

        await notifier.refresh();

        // First state change should have isRefreshing=true, isLoading=false
        final refreshingState = states.firstWhere(
          (s) => s.isRefreshing,
          orElse: () => const UserAquariumsState(),
        );
        expect(refreshingState.isRefreshing, true);
        expect(refreshingState.isLoading, false);

        // Final state should have isRefreshing=false
        expect(notifier.state.isRefreshing, false);
      });
    });

    group('createAquarium', () {
      test('should add new aquarium to state', () async {
        final notifier = await createNotifier();

        when(
          () => mockRepository.createAquarium(
            name: any(named: 'name'),
            waterType: any(named: 'waterType'),
            capacity: any(named: 'capacity'),
          ),
        ).thenAnswer((_) async => Right(testAquarium));

        final result = await notifier.createAquarium(name: 'Living Room Tank');

        expect(result, isNotNull);
        expect(result!.name, 'Living Room Tank');
        expect(notifier.state.aquariums.length, 1);
      });

      test('should return null and set error on failure', () async {
        final notifier = await createNotifier();

        when(
          () => mockRepository.createAquarium(
            name: any(named: 'name'),
            waterType: any(named: 'waterType'),
            capacity: any(named: 'capacity'),
          ),
        ).thenAnswer(
          (_) async =>
              const Left(AuthenticationFailure(message: 'Not logged in')),
        );

        final result = await notifier.createAquarium(name: 'Test');

        expect(result, isNull);
        expect(notifier.state.hasError, true);
      });
    });

    group('deleteAquarium', () {
      test('should remove aquarium from state', () async {
        final notifier = await createNotifier(
          initialAquariums: [testAquarium, testAquarium2],
        );

        when(
          () => mockRepository.deleteAquarium(any()),
        ).thenAnswer((_) async => const Right(unit));

        final result = await notifier.deleteAquarium('aq-1');

        expect(result, true);
        expect(notifier.state.aquariums.length, 1);
        expect(notifier.state.aquariums[0].id, 'aq-2');
      });
    });

    group('clearError', () {
      test('should clear error from state', () async {
        final notifier = await createNotifier();

        when(
          () => mockRepository.createAquarium(
            name: any(named: 'name'),
            waterType: any(named: 'waterType'),
            capacity: any(named: 'capacity'),
          ),
        ).thenAnswer((_) async => const Left(CacheFailure(message: 'Error')));

        await notifier.createAquarium(name: 'Test');
        expect(notifier.state.hasError, true);

        notifier.clearError();
        expect(notifier.state.hasError, false);
      });
    });
  });

  group('UserAquariumsState', () {
    test('isEmpty should be true when no aquariums and not loading', () {
      const state = UserAquariumsState();
      expect(state.isEmpty, true);
    });

    test('isEmpty should be false when loading', () {
      const state = UserAquariumsState(isLoading: true);
      expect(state.isEmpty, false);
    });

    test('isEmpty should be false when refreshing', () {
      const state = UserAquariumsState(isRefreshing: true);
      expect(state.isEmpty, false);
    });

    test('isEmpty should be false when has error', () {
      const state = UserAquariumsState(error: 'Some error');
      expect(state.isEmpty, false);
    });

    test('getById should return aquarium when found', () {
      final state = UserAquariumsState(aquariums: [testAquarium]);
      expect(state.getById('aq-1')?.name, 'Living Room Tank');
    });

    test('getById should return null when not found', () {
      final state = UserAquariumsState(aquariums: [testAquarium]);
      expect(state.getById('non-existent'), isNull);
    });

    test('count should return number of aquariums', () {
      final state = UserAquariumsState(
        aquariums: [testAquarium, testAquarium2],
      );
      expect(state.count, 2);
    });

    test('copyWith should clear error when new error is null', () {
      const state = UserAquariumsState(error: 'Old error');
      final updated = state.copyWith(error: null);
      // copyWith with error: null resets it because of how copyWith works
      expect(updated.error, isNull);
    });
  });
}
