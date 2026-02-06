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

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final testAquariums = [
    Aquarium(
      id: 'aq1',
      userId: 'user1',
      name: 'Living Room Tank',
      capacity: 120,
      waterType: WaterType.freshwater,
      createdAt: DateTime(2024, 1, 1),
    ),
    Aquarium(
      id: 'aq2',
      userId: 'user1',
      name: 'Office Tank',
      createdAt: DateTime(2024, 1, 2),
    ),
  ];

  // Feedings for aq1: 2 unique fish (Guppy qty=5, Betta qty=3)
  // with multiple schedule times
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
      status: EventStatus.fed,
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
    // Feedings for aq2: 1 fish (Goldfish qty=2), all pending
    ComputedFeedingEvent(
      scheduleId: 's4',
      fishId: 'fish3',
      aquariumId: 'aq2',
      scheduledFor: today.add(const Duration(hours: 12)),
      time: '12:00',
      foodType: 'Flakes',
      status: EventStatus.pending,
      fishName: 'Goldfish',
      aquariumName: 'Office Tank',
      fishQuantity: 2,
    ),
  ];

  /// Builds a standalone AquariumStatusCard for widget testing.
  Widget buildStatusCard({
    required Aquarium aquarium,
    required List<ComputedFeedingEvent> feedings,
    TodayFeedingsState? feedingsState,
  }) {
    final allFeedings = feedingsState?.feedings ?? feedings;

    return ProviderScope(
      overrides: [
        todayFeedingsProvider.overrideWith((ref) {
          return _MockTodayFeedingsNotifier(
            TodayFeedingsState(feedings: allFeedings, isLoading: false),
          );
        }),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AquariumStatusCard(aquarium: aquarium, feedings: feedings),
        ),
      ),
    );
  }

  /// Builds TodayView for integration testing.
  Widget buildTodayView({
    TodayFeedingsState? state,
    List<Aquarium>? aquariums,
    bool isPremium = true,
  }) {
    final mockAquariums = aquariums ?? testAquariums;
    final feedingsState =
        state ?? TodayFeedingsState(feedings: testFeedings, isLoading: false);

    return ProviderScope(
      overrides: [
        todayFeedingsProvider.overrideWith((ref) {
          return _MockTodayFeedingsNotifier(feedingsState);
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

  group('AquariumStatusCard', () {
    testWidgets('displays aquarium name', (tester) async {
      await tester.pumpWidget(
        buildStatusCard(
          aquarium: testAquariums[0],
          feedings: testFeedings.where((f) => f.aquariumId == 'aq1').toList(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Living Room Tank'), findsOneWidget);
    });

    testWidgets('displays fish count as SUM of unique fish quantities', (
      tester,
    ) async {
      // aq1 has fish1 (qty=5) + fish2 (qty=3) = 8 fish total
      await tester.pumpWidget(
        buildStatusCard(
          aquarium: testAquariums[0],
          feedings: testFeedings.where((f) => f.aquariumId == 'aq1').toList(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('8 fish'), findsOneWidget);
    });

    testWidgets('displays volume when capacity is set', (tester) async {
      await tester.pumpWidget(
        buildStatusCard(
          aquarium: testAquariums[0], // capacity: 120
          feedings: testFeedings.where((f) => f.aquariumId == 'aq1').toList(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('120L'), findsOneWidget);
    });

    testWidgets('does not display volume when capacity is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildStatusCard(
          aquarium: testAquariums[1], // no capacity
          feedings: testFeedings.where((f) => f.aquariumId == 'aq2').toList(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('L'), findsNothing);
    });

    testWidgets('displays allFed status when all feedings are completed', (
      tester,
    ) async {
      final allFedFeedings = [
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
      ];

      await tester.pumpWidget(
        buildStatusCard(
          aquarium: testAquariums[0],
          feedings: allFedFeedings,
          feedingsState: TodayFeedingsState(
            feedings: allFedFeedings,
            isLoading: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('All fed'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('displays pendingFeeding status when overdue feedings exist', (
      tester,
    ) async {
      final overdueFeedings = [
        ComputedFeedingEvent(
          scheduleId: 's1',
          fishId: 'fish1',
          aquariumId: 'aq1',
          scheduledFor: today.add(const Duration(hours: 6)), // Past time
          time: '06:00',
          foodType: 'Flakes',
          status: EventStatus.overdue,
          fishName: 'Guppy',
          aquariumName: 'Living Room Tank',
          fishQuantity: 5,
        ),
      ];

      await tester.pumpWidget(
        buildStatusCard(
          aquarium: testAquariums[0],
          feedings: overdueFeedings,
          feedingsState: TodayFeedingsState(
            feedings: overdueFeedings,
            isLoading: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Pending feeding at'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('displays nextAt status when next feeding is in the future', (
      tester,
    ) async {
      final futureFeedings = [
        ComputedFeedingEvent(
          scheduleId: 's1',
          fishId: 'fish1',
          aquariumId: 'aq1',
          scheduledFor: today.add(const Duration(hours: 23)),
          time: '23:00',
          foodType: 'Flakes',
          status: EventStatus.pending,
          fishName: 'Guppy',
          aquariumName: 'Living Room Tank',
          fishQuantity: 5,
        ),
      ];

      await tester.pumpWidget(
        buildStatusCard(
          aquarium: testAquariums[0],
          feedings: futureFeedings,
          feedingsState: TodayFeedingsState(
            feedings: futureFeedings,
            isLoading: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Next at 23:00'), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    testWidgets('card has InkWell for tap interaction', (tester) async {
      await tester.pumpWidget(
        buildStatusCard(
          aquarium: testAquariums[0],
          feedings: testFeedings.where((f) => f.aquariumId == 'aq1').toList(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify InkWell exists inside the card for tap navigation
      final inkWell = find.ancestor(
        of: find.text('Living Room Tank'),
        matching: find.byType(InkWell),
      );
      expect(inkWell, findsOneWidget);
    });

    testWidgets('displays empty fish count when no feedings', (tester) async {
      await tester.pumpWidget(
        buildStatusCard(aquarium: testAquariums[0], feedings: []),
      );
      await tester.pumpAndSettle();

      expect(find.text('No fish'), findsOneWidget);
    });

    testWidgets('displays chevron icon', (tester) async {
      await tester.pumpWidget(
        buildStatusCard(
          aquarium: testAquariums[0],
          feedings: testFeedings.where((f) => f.aquariumId == 'aq1').toList(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('displays water drop icon', (tester) async {
      await tester.pumpWidget(
        buildStatusCard(
          aquarium: testAquariums[0],
          feedings: testFeedings.where((f) => f.aquariumId == 'aq1').toList(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.water_drop_outlined), findsOneWidget);
    });
  });

  group('TodayView with AquariumStatusCard', () {
    testWidgets('displays all aquariums as status cards', (tester) async {
      await tester.pumpWidget(buildTodayView());
      await tester.pumpAndSettle();

      expect(find.text('Living Room Tank'), findsOneWidget);
      expect(find.text('Office Tank'), findsOneWidget);
      expect(find.byType(AquariumStatusCard), findsNWidgets(2));
    });

    testWidgets('displays add aquarium button', (tester) async {
      await tester.pumpWidget(buildTodayView());
      await tester.pumpAndSettle();

      expect(find.text('Add Another Aquarium'), findsOneWidget);
    });

    testWidgets('displays empty state when no feedings', (tester) async {
      await tester.pumpWidget(
        buildTodayView(
          state: const TodayFeedingsState(feedings: [], isLoading: false),
        ),
      );
      await tester.pumpAndSettle();

      // Empty state message appears when no feedings
      // Plus aquarium cards still shown (with empty fish count)
      expect(find.byType(AquariumStatusCard), findsNWidgets(2));
    });

    testWidgets('shows shimmer loading on initial load', (tester) async {
      await tester.pumpWidget(
        buildTodayView(state: const TodayFeedingsState(isLoading: true)),
      );

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('shows error state with retry button', (tester) async {
      await tester.pumpWidget(
        buildTodayView(
          state: const TodayFeedingsState(
            isLoading: false,
            error: 'Network error',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Network error'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('shows empty state message when no aquariums', (tester) async {
      await tester.pumpWidget(
        buildTodayView(
          state: const TodayFeedingsState(feedings: [], isLoading: false),
          aquariums: [],
        ),
      );
      await tester.pumpAndSettle();

      // No AquariumStatusCard when no aquariums
      expect(find.byType(AquariumStatusCard), findsNothing);
      // Add button still visible
      expect(find.text('Add Another Aquarium'), findsOneWidget);
    });

    testWidgets('RefreshIndicator is present', (tester) async {
      await tester.pumpWidget(buildTodayView());
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);
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
    String? imageUrl,
  }) async => null;

  @override
  Future<bool> deleteAquarium(String aquariumId) async => false;

  @override
  void clearError() {}
}
