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
import 'package:fishfeed/presentation/screens/feeding/feeding_cards_screen.dart';
import 'package:fishfeed/presentation/widgets/feeding/feeding_card.dart';
import 'package:fishfeed/services/sync/conflict_resolver.dart';
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

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final testAquarium = Aquarium(
    id: 'aq1',
    userId: 'user1',
    name: 'Living Room Tank',
    capacity: 120,
    waterType: WaterType.freshwater,
    createdAt: DateTime(2024, 1, 1),
  );

  // Feedings grouped across two time slots: 09:00 and 18:00
  final testFeedings = [
    ComputedFeedingEvent(
      scheduleId: 's1',
      fishId: 'fish1',
      aquariumId: 'aq1',
      scheduledFor: today.add(const Duration(hours: 9)),
      time: '09:00',
      foodType: 'Flakes',
      status: EventStatus.fed,
      fishName: 'Guppy',
      aquariumName: 'Living Room Tank',
      fishQuantity: 5,
    ),
    ComputedFeedingEvent(
      scheduleId: 's2',
      fishId: 'fish2',
      aquariumId: 'aq1',
      scheduledFor: today.add(const Duration(hours: 9)),
      time: '09:00',
      foodType: 'Pellets',
      status: EventStatus.pending,
      fishName: 'Betta',
      aquariumName: 'Living Room Tank',
      fishQuantity: 3,
    ),
    ComputedFeedingEvent(
      scheduleId: 's3',
      fishId: 'fish1',
      aquariumId: 'aq1',
      scheduledFor: today.add(const Duration(hours: 18)),
      time: '18:00',
      foodType: 'Flakes',
      status: EventStatus.pending,
      fishName: 'Guppy',
      aquariumName: 'Living Room Tank',
      fishQuantity: 5,
    ),
  ];

  Widget buildTestWidget({
    TodayFeedingsState? state,
    List<Aquarium>? aquariums,
    MockSyncService? syncService,
  }) {
    final feedingsState =
        state ?? TodayFeedingsState(feedings: testFeedings, isLoading: false);
    final mockAquariums = aquariums ?? [testAquarium];
    final sync = syncService ?? mockSyncService;

    return ProviderScope(
      overrides: [
        todayFeedingsProvider.overrideWith((ref) {
          return _MockTodayFeedingsNotifier(feedingsState);
        }),
        userAquariumsProvider.overrideWith((ref) {
          return _MockUserAquariumsNotifier(
            UserAquariumsState(aquariums: mockAquariums, isLoading: false),
          );
        }),
        syncServiceProvider.overrideWithValue(sync),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const FeedingCardsScreen(aquariumId: 'aq1'),
      ),
    );
  }

  group('FeedingCardsScreen', () {
    group('AppBar', () {
      testWidgets('displays aquarium name in title', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Aquarium name appears in AppBar title AND in FeedingCard's aquariumName
        // Verify it appears in the AppBar by finding ancestor
        final appBarTitle = find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Living Room Tank'),
        );
        expect(appBarTitle, findsOneWidget);
      });

      testWidgets('displays settings icon in actions', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      });

      testWidgets('displays fallback label when aquarium not found', (
        tester,
      ) async {
        await tester.pumpWidget(buildTestWidget(aquariums: []));
        await tester.pumpAndSettle();

        // Should show feedingLabel as fallback in AppBar
        final appBarTitle = find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Feeding'),
        );
        expect(appBarTitle, findsOneWidget);
      });
    });

    group('Time Group Headers', () {
      testWidgets('displays time group headers for each time slot', (
        tester,
      ) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Time text appears in both headers and FeedingCard time column.
        // 09:00: 1 header + 2 cards = 3, 18:00: 1 header + 1 card = 2
        expect(find.textContaining('09:00'), findsNWidgets(3));
        expect(find.textContaining('18:00'), findsNWidgets(2));
      });
    });

    group('Feeding Cards', () {
      testWidgets('displays FeedingCard for each fish in time group', (
        tester,
      ) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Should have 3 FeedingCards total (2 at 09:00, 1 at 18:00)
        expect(find.byType(FeedingCard), findsNWidgets(3));
      });

      testWidgets('displays fish names on cards', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Guppy'), findsNWidgets(2)); // Two Guppy feedings
        expect(find.text('Betta'), findsOneWidget);
      });
    });

    group('Empty State', () {
      testWidgets('shows empty state when no feedings', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            state: const TodayFeedingsState(feedings: [], isLoading: false),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('No feedings scheduled'), findsOneWidget);
        expect(find.byIcon(Icons.no_food_outlined), findsOneWidget);
        expect(find.byType(FeedingCard), findsNothing);
      });
    });

    group('Pull-to-Refresh', () {
      testWidgets('RefreshIndicator is present', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(RefreshIndicator), findsOneWidget);
      });

      testWidgets('RefreshIndicator is present in empty state', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            state: const TodayFeedingsState(feedings: [], isLoading: false),
          ),
        );
        await tester.pumpAndSettle();

        // Empty state also wrapped in RefreshIndicator via ListView
        expect(find.byType(RefreshIndicator), findsOneWidget);
      });
    });

    group('Conflict Toast', () {
      testWidgets('shows styled toast when conflict is received', (
        tester,
      ) async {
        final conflictController =
            StreamController<SyncConflict<Map<String, dynamic>>>();
        addTearDown(conflictController.close);

        final localSync = MockSyncService();
        when(
          () => localSync.feedingConflictStream,
        ).thenAnswer((_) => conflictController.stream);
        when(() => localSync.syncNow()).thenAnswer((_) async => 0);

        await tester.pumpWidget(buildTestWidget(syncService: localSync));
        await tester.pumpAndSettle();

        // Emit a conflict for this aquarium
        conflictController.add(
          SyncConflict<Map<String, dynamic>>(
            entityId: 'log-1',
            entityType: 'feeding_log',
            localVersion: const <String, dynamic>{},
            serverVersion: <String, dynamic>{
              'aquarium_id': 'aq1',
              'acted_by_user_name': 'Jane',
              'acted_at': DateTime(2024, 1, 15, 14, 30).toIso8601String(),
            },
            localUpdatedAt: DateTime(2024, 1, 15, 14, 25),
            serverUpdatedAt: DateTime(2024, 1, 15, 14, 30),
            resolution: ConflictResolution.useServer,
          ),
        );
        // Give time for stream to deliver event and SnackBar to animate
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Styled toast should appear with people icon
        expect(find.byIcon(Icons.people_alt), findsOneWidget);
        expect(find.textContaining('Jane'), findsOneWidget);
      });

      testWidgets('filters conflicts for other aquariums', (tester) async {
        final conflictController =
            StreamController<SyncConflict<Map<String, dynamic>>>();
        addTearDown(conflictController.close);

        final localSync = MockSyncService();
        when(
          () => localSync.feedingConflictStream,
        ).thenAnswer((_) => conflictController.stream);
        when(() => localSync.syncNow()).thenAnswer((_) async => 0);

        await tester.pumpWidget(buildTestWidget(syncService: localSync));
        await tester.pumpAndSettle();

        // Emit a conflict for a DIFFERENT aquarium
        conflictController.add(
          SyncConflict<Map<String, dynamic>>(
            entityId: 'log-2',
            entityType: 'feeding_log',
            localVersion: const <String, dynamic>{},
            serverVersion: <String, dynamic>{
              'aquarium_id': 'other-aq',
              'acted_by_user_name': 'Bob',
              'acted_at': DateTime(2024, 1, 15, 14, 30).toIso8601String(),
            },
            localUpdatedAt: DateTime(2024, 1, 15, 14, 25),
            serverUpdatedAt: DateTime(2024, 1, 15, 14, 30),
            resolution: ConflictResolution.useServer,
          ),
        );
        await tester.pump();

        // Toast should NOT appear for another aquarium
        expect(find.byIcon(Icons.people_alt), findsNothing);
      });
    });
  });
}

/// Mock notifier for TodayFeedingsNotifier.
class _MockTodayFeedingsNotifier extends StateNotifier<TodayFeedingsState>
    implements TodayFeedingsNotifier {
  _MockTodayFeedingsNotifier(super.initialState);

  @override
  Future<void> loadFeedings() async {}

  @override
  Future<void> refresh() async {}

  @override
  Future<void> markAsFed(String scheduleId) async {}

  @override
  Future<void> markAsMissed(String scheduleId) async {}

  @override
  void updateFeedingStatus(String scheduleId, EventStatus newStatus) {}

  @override
  void clearError() {}
}

/// Mock notifier for UserAquariumsNotifier.
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
  }) async => null;

  @override
  Future<Aquarium?> updateAquarium({
    required String aquariumId,
    String? name,
    WaterType? waterType,
    double? capacity,
    String? photoKey,
    bool clearPhotoKey = false,
  }) async => null;

  @override
  Future<bool> deleteAquarium(String aquariumId) async => false;

  @override
  void clearError() {}
}
