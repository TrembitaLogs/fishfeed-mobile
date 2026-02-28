import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/domain/entities/aquarium.dart';
import 'package:fishfeed/domain/entities/feeding_event.dart';
import 'package:fishfeed/domain/entities/water_type.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/aquarium_providers.dart';
import 'package:fishfeed/presentation/providers/feeding_providers.dart';
import 'package:fishfeed/presentation/providers/purchase_provider.dart';
import 'package:fishfeed/presentation/screens/home/today_view.dart';
import 'package:fishfeed/presentation/widgets/feeding/aquarium_status_card.dart';
import 'package:fishfeed/services/sync/sync_service.dart';

class MockSyncService extends Mock implements SyncService {}

void main() {
  late MockSyncService mockSyncService;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
  });

  setUp(() {
    mockSyncService = MockSyncService();
    when(
      () => mockSyncService.feedingConflictStream,
    ).thenAnswer((_) => const Stream.empty());
    when(() => mockSyncService.syncNow()).thenAnswer((_) async => 0);
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  // Default mock aquariums for tests
  final defaultAquariums = <Aquarium>[
    Aquarium(
      id: 'aq1',
      userId: 'user1',
      name: 'Living Room Tank',
      createdAt: DateTime(2024, 1, 1),
    ),
    Aquarium(
      id: 'aq2',
      userId: 'user1',
      name: 'Bedroom Aquarium',
      createdAt: DateTime(2024, 1, 2),
    ),
  ];

  Widget buildTestWidget({
    TodayFeedingsState? state,
    bool isPremium = true,
    List<Aquarium>? aquariums,
  }) {
    final mockAquariums = aquariums ?? defaultAquariums;

    return ProviderScope(
      overrides: [
        if (state != null)
          todayFeedingsProvider.overrideWith((ref) {
            return _MockTodayFeedingsNotifier(state);
          }),
        isPremiumProvider.overrideWithValue(isPremium),
        userAquariumsProvider.overrideWith((ref) {
          return _MockUserAquariumsNotifier(
            UserAquariumsState(aquariums: mockAquariums, isLoading: false),
          );
        }),
        syncServiceProvider.overrideWithValue(mockSyncService),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: TodayView()),
      ),
    );
  }

  group('TodayView', () {
    group('Loading State', () {
      testWidgets('displays shimmer loading when isLoading is true', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(state: const TodayFeedingsState(isLoading: true)),
        );

        // Should show shimmer placeholders (multiple cards with gradient boxes)
        // Shimmer shows 5 placeholder cards
        expect(find.byType(ListView), findsOneWidget);
      });
    });

    group('Empty State', () {
      testWidgets(
        'displays aquarium status cards with no fish when no feedings',
        (tester) async {
          await tester.pumpWidget(
            buildTestWidget(
              state: const TodayFeedingsState(feedings: [], isLoading: false),
            ),
          );
          await tester.pumpAndSettle();

          // TodayView now shows AquariumStatusCard per aquarium
          // Each card shows "No fish" when no feedings
          expect(find.byType(AquariumStatusCard), findsNWidgets(2));
          expect(find.text('No fish'), findsNWidgets(2));
        },
      );
    });

    group('Error State', () {
      testWidgets('displays error state with message', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            state: const TodayFeedingsState(
              isLoading: false,
              error: 'Network error',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Uses localized strings and ErrorStateWidget
        expect(find.text('Oops!'), findsOneWidget);
        expect(find.text('Network error'), findsOneWidget);
        expect(find.text('Try Again'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      });

      testWidgets('retry button with refresh icon is displayed', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            state: const TodayFeedingsState(
              isLoading: false,
              error: 'Test error',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify button is present by checking for refresh icon and text
        expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
        expect(find.text('Try Again'), findsOneWidget);
      });
    });

    group('Aquarium Status Cards', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final mockFeedings = [
        ComputedFeedingEvent(
          scheduleId: '1',
          fishId: 'fish1',
          aquariumId: 'aq1',
          scheduledFor: today.add(const Duration(hours: 8)),
          time: '08:00',
          foodType: 'Flakes',
          status: EventStatus.fed,
          fishName: 'Guppy',
          aquariumName: 'Living Room Tank',
          fishQuantity: 3,
        ),
        ComputedFeedingEvent(
          scheduleId: '2',
          fishId: 'fish2',
          aquariumId: 'aq1',
          scheduledFor: today.add(const Duration(hours: 14)),
          time: '14:00',
          foodType: 'Pellets',
          status: EventStatus.pending,
          fishName: 'Betta',
          aquariumName: 'Living Room Tank',
          fishQuantity: 2,
        ),
        ComputedFeedingEvent(
          scheduleId: '3',
          fishId: 'fish3',
          aquariumId: 'aq2',
          scheduledFor: today.add(const Duration(hours: 19)),
          time: '19:00',
          foodType: 'Flakes',
          status: EventStatus.pending,
          fishName: 'Goldfish',
          aquariumName: 'Bedroom Aquarium',
          fishQuantity: 4,
        ),
      ];

      testWidgets('displays aquarium names in status cards', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            state: TodayFeedingsState(feedings: mockFeedings, isLoading: false),
          ),
        );
        await tester.pumpAndSettle();

        // Each aquarium name appears once in its status card
        expect(find.text('Living Room Tank'), findsOneWidget);
        expect(find.text('Bedroom Aquarium'), findsOneWidget);
      });

      testWidgets('displays AquariumStatusCard for each aquarium', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            state: TodayFeedingsState(feedings: mockFeedings, isLoading: false),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AquariumStatusCard), findsNWidgets(2));
      });

      testWidgets('displays water drop icon in each aquarium card', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            state: TodayFeedingsState(feedings: mockFeedings, isLoading: false),
          ),
        );
        await tester.pumpAndSettle();

        // Each AquariumStatusCard has a water drop icon
        expect(find.byIcon(Icons.water_drop_outlined), findsNWidgets(2));
      });

      testWidgets('displays fish count per aquarium', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            state: TodayFeedingsState(feedings: mockFeedings, isLoading: false),
          ),
        );
        await tester.pumpAndSettle();

        // aq1: fish1 qty=3 + fish2 qty=2 = 5 fish
        expect(find.text('5 fish'), findsOneWidget);
        // aq2: fish3 qty=4 = 4 fish
        expect(find.text('4 fish'), findsOneWidget);
      });

      testWidgets('displays add aquarium button at the bottom', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            state: TodayFeedingsState(feedings: mockFeedings, isLoading: false),
          ),
        );
        await tester.pumpAndSettle();

        // Should show "Add Another Aquarium" button
        expect(find.text('Add Another Aquarium'), findsOneWidget);
      });
    });

    group('Pull to Refresh', () {
      testWidgets('RefreshIndicator is present', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            state: const TodayFeedingsState(feedings: [], isLoading: false),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(RefreshIndicator), findsOneWidget);
      });
    });

    group('Status Card Interaction', () {
      testWidgets('aquarium status card has InkWell for tap', (tester) async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final pendingFeeding = [
          ComputedFeedingEvent(
            scheduleId: '1',
            fishId: 'fish1',
            aquariumId: 'aq1',
            scheduledFor: today.add(const Duration(hours: 19)),
            time: '19:00',
            foodType: 'Flakes',
            status: EventStatus.pending,
            fishName: 'Guppy',
            aquariumName: 'Living Room Tank',
          ),
        ];

        await tester.pumpWidget(
          buildTestWidget(
            state: TodayFeedingsState(
              feedings: pendingFeeding,
              isLoading: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Find the AquariumStatusCards (2 aquariums)
        expect(find.byType(AquariumStatusCard), findsNWidgets(2));

        // Verify each card contains an InkWell for tap navigation
        final inkWells = find.descendant(
          of: find.byType(AquariumStatusCard),
          matching: find.byType(InkWell),
        );
        expect(inkWells, findsNWidgets(2));
      });
    });
  });

  group('TodayFeedingsState', () {
    test('isEmpty returns true when empty and not loading', () {
      const state = TodayFeedingsState(feedings: [], isLoading: false);
      expect(state.isEmpty, isTrue);
    });

    test('isEmpty returns false when loading', () {
      const state = TodayFeedingsState(feedings: [], isLoading: true);
      expect(state.isEmpty, isFalse);
    });

    test('isEmpty returns false when has error', () {
      const state = TodayFeedingsState(
        feedings: [],
        isLoading: false,
        error: 'Error',
      );
      expect(state.isEmpty, isFalse);
    });

    test('hasError returns true when error is set', () {
      const state = TodayFeedingsState(error: 'Network error');
      expect(state.hasError, isTrue);
    });

    test('hasError returns false when error is null', () {
      const state = TodayFeedingsState();
      expect(state.hasError, isFalse);
    });
  });
}

/// Mock notifier that extends StateNotifier directly to avoid constructor deps.
class _MockTodayFeedingsNotifier extends StateNotifier<TodayFeedingsState>
    implements TodayFeedingsNotifier {
  _MockTodayFeedingsNotifier(super.initialState);

  @override
  Future<void> loadFeedings() async {}

  @override
  Future<void> refresh() async {}

  @override
  Future<void> markAsFed(String scheduleId) async {
    final updatedFeedings = state.feedings.map((f) {
      if (f.scheduleId == scheduleId) {
        return f.copyWith(status: EventStatus.fed);
      }
      return f;
    }).toList();
    state = state.copyWith(feedings: updatedFeedings);
  }

  @override
  Future<void> markAsMissed(String scheduleId) async {
    final updatedFeedings = state.feedings.map((f) {
      if (f.scheduleId == scheduleId) {
        return f.copyWith(status: EventStatus.skipped);
      }
      return f;
    }).toList();
    state = state.copyWith(feedings: updatedFeedings);
  }

  @override
  void updateFeedingStatus(String scheduleId, EventStatus newStatus) {
    final updatedFeedings = state.feedings.map((f) {
      if (f.scheduleId == scheduleId) {
        return f.copyWith(status: newStatus);
      }
      return f;
    }).toList();
    state = state.copyWith(feedings: updatedFeedings);
  }

  @override
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Mock notifier for user aquariums.
class _MockUserAquariumsNotifier extends StateNotifier<UserAquariumsState>
    implements UserAquariumsNotifier {
  _MockUserAquariumsNotifier(super.initialState);

  @override
  Future<void> loadAquariums() async {}

  @override
  Future<void> refresh() async {}

  @override
  Future<Aquarium?> createAquarium({
    required String name,
    WaterType? waterType,
    double? capacity,
  }) async {
    return null;
  }

  @override
  Future<Aquarium?> updateAquarium({
    required String aquariumId,
    String? name,
    WaterType? waterType,
    double? capacity,
    String? photoKey,
    bool clearPhotoKey = false,
  }) async {
    return null;
  }

  @override
  Future<bool> deleteAquarium(String aquariumId) async {
    return false;
  }

  @override
  void clearError() {}
}
