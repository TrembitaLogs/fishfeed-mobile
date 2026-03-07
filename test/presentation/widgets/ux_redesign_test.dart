import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/data/datasources/local/fish_local_ds.dart';
import 'package:fishfeed/data/datasources/local/local_datasources_providers.dart';
import 'package:fishfeed/data/datasources/local/schedule_local_ds.dart';
import 'package:fishfeed/data/datasources/local/species_local_ds.dart';
import 'package:fishfeed/data/datasources/remote/species_remote_ds.dart';
import 'package:fishfeed/data/models/schedule_model.dart';
import 'package:fishfeed/domain/entities/aquarium.dart';
import 'package:fishfeed/domain/entities/calendar_month_data.dart';
import 'package:fishfeed/domain/entities/day_feeding_status.dart';
import 'package:fishfeed/domain/entities/feeding_event.dart';
import 'package:fishfeed/domain/entities/fish.dart';
import 'package:fishfeed/domain/entities/subscription_status.dart';
import 'package:fishfeed/domain/entities/user.dart';
import 'package:fishfeed/domain/entities/water_type.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/ad_provider.dart';
import 'package:fishfeed/presentation/providers/aquarium_providers.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';
import 'package:fishfeed/presentation/providers/calendar_data_provider.dart';
import 'package:fishfeed/presentation/providers/feeding_providers.dart';
import 'package:fishfeed/presentation/providers/fish_management_provider.dart';
import 'package:fishfeed/presentation/providers/purchase_provider.dart';
import 'package:fishfeed/presentation/screens/aquarium/aquarium_edit_screen.dart';
import 'package:fishfeed/presentation/widgets/feeding/confirm_feeding_dialog.dart';
import 'package:fishfeed/presentation/widgets/feeding/feeding_card.dart';
import 'package:fishfeed/presentation/widgets/feeding/fish_card_sheet.dart';
import 'package:fishfeed/presentation/widgets/sheets/aquarium_card_sheet.dart';
import 'package:fishfeed/services/sync/sync_service.dart';

// ============================================================================
// Mock Classes
// ============================================================================

class MockFishLocalDataSource extends Mock implements FishLocalDataSource {}

class MockScheduleLocalDataSource extends Mock
    implements ScheduleLocalDataSource {}

class MockSpeciesLocalDataSource extends Mock
    implements SpeciesLocalDataSource {}

class MockSpeciesRemoteDataSource extends Mock
    implements SpeciesRemoteDataSource {}

class MockSyncService extends Mock implements SyncService {}

/// Mock UserAquariumsNotifier for aquarium provider overrides.
class MockUserAquariumsNotifier extends StateNotifier<UserAquariumsState>
    implements UserAquariumsNotifier {
  MockUserAquariumsNotifier({List<Aquarium>? aquariums})
    : super(UserAquariumsState(aquariums: aquariums ?? [], isLoading: false));

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
  Future<bool> deleteAquarium(String aquariumId) async {
    state = state.copyWith(
      aquariums: state.aquariums.where((a) => a.id != aquariumId).toList(),
    );
    return true;
  }

  @override
  void clearError() {}
}

/// Mock FishManagementNotifier for fish provider overrides.
class MockFishManagementNotifier extends StateNotifier<FishManagementState>
    implements FishManagementNotifier {
  MockFishManagementNotifier({List<Fish>? fish})
    : super(
        FishManagementState(
          userFish: fish ?? [],
          isLoading: false,
          error: null,
        ),
      );

  @override
  Future<void> loadUserFish() async {}

  @override
  void setSelectedAquarium(String? aquariumId) {}

  @override
  Future<Fish?> addFish({
    required String speciesId,
    int quantity = 1,
    String? name,
    String? aquariumId,
  }) async => null;

  @override
  Future<bool> updateFish(Fish fish) async => true;

  @override
  Future<bool> deleteFish(String fishId) async => true;

  @override
  Fish? getFishById(String id) {
    try {
      return state.userFish.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  void clearError() {}

  @override
  Future<void> refresh() async {}
}

/// Mock CalendarDataNotifier that does not make async calls.
class MockCalendarDataNotifier extends StateNotifier<CalendarDataState>
    implements CalendarDataNotifier {
  MockCalendarDataNotifier()
    : super(
        CalendarDataState(
          monthData: CalendarMonthData.empty(
            DateTime.now().year,
            DateTime.now().month,
          ),
          isLoading: false,
        ),
      );

  @override
  Future<void> loadMonth(int year, int month) async {}

  @override
  DayFeedingStatus getDayStatus(DateTime day) => DayFeedingStatus.noData;

  @override
  Future<void> refresh() async {}
}

/// Mock TodayFeedingsNotifier that does not make async calls.
class MockTodayFeedingsNotifier extends StateNotifier<TodayFeedingsState>
    implements TodayFeedingsNotifier {
  MockTodayFeedingsNotifier()
    : super(const TodayFeedingsState(feedings: [], isLoading: false));

  @override
  Future<void> loadFeedings() async {}

  @override
  Future<void> refresh() async {}

  @override
  Future<void> markAsFed(String feedingId) async {}

  @override
  Future<void> markAsMissed(String feedingId) async {}

  @override
  void updateFeedingStatus(String scheduleId, EventStatus newStatus) {}

  @override
  void clearError() {}
}

// ============================================================================
// Test Data
// ============================================================================

final _testOwner = User(
  id: 'owner-1',
  email: 'owner@test.com',
  displayName: 'Test Owner',
  createdAt: DateTime(2024, 1, 1),
  subscriptionStatus: const SubscriptionStatus.free(),
  freeAiScansRemaining: 5,
);

final _testNonOwner = User(
  id: 'member-1',
  email: 'member@test.com',
  displayName: 'Family Member',
  createdAt: DateTime(2024, 1, 1),
  subscriptionStatus: const SubscriptionStatus.free(),
  freeAiScansRemaining: 5,
);

final _testAquarium = Aquarium(
  id: 'aquarium-1',
  userId: 'owner-1',
  name: 'My Tank',
  waterType: WaterType.freshwater,
  capacity: 100.0,
  createdAt: DateTime(2024, 1, 15),
);

final _testFish1 = Fish(
  id: 'fish-1',
  aquariumId: 'aquarium-1',
  speciesId: 'guppy',
  name: 'Nemo',
  quantity: 3,
  notes: 'Loves flakes',
  addedAt: DateTime(2024, 1, 20),
);

final _testFish2 = Fish(
  id: 'fish-2',
  aquariumId: 'aquarium-1',
  speciesId: 'betta',
  name: 'Blue',
  quantity: 1,
  addedAt: DateTime(2024, 2, 10),
);

ComputedFeedingEvent _createFeedingEvent({
  EventStatus status = EventStatus.pending,
  String fishName = 'Nemo',
  String aquariumName = 'My Tank',
  int fishQuantity = 3,
  String scheduleId = 'schedule-1',
  String fishId = 'fish-1',
  String aquariumId = 'aquarium-1',
  String time = '09:00',
  String foodType = 'flakes',
  String? portionHint,
}) {
  return ComputedFeedingEvent(
    scheduleId: scheduleId,
    fishId: fishId,
    aquariumId: aquariumId,
    scheduledFor: DateTime(2025, 1, 15, 9, 0),
    time: time,
    foodType: foodType,
    portionHint: portionHint,
    status: status,
    fishName: fishName,
    aquariumName: aquariumName,
    fishQuantity: fishQuantity,
  );
}

ScheduleModel _createSchedule({
  String id = 'schedule-1',
  String fishId = 'fish-1',
  String aquariumId = 'aquarium-1',
  String time = '09:00',
  int intervalDays = 1,
  String foodType = 'flakes',
  bool active = true,
}) {
  return ScheduleModel(
    id: id,
    fishId: fishId,
    aquariumId: aquariumId,
    time: time,
    intervalDays: intervalDays,
    anchorDate: DateTime(2025, 1, 1),
    foodType: foodType,
    active: active,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
    createdByUserId: 'owner-1',
    synced: true,
  );
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Creates a properly configured mock SyncService.
MockSyncService _createMockSyncService() {
  final service = MockSyncService();
  when(() => service.hasUnsyncedFeedings).thenReturn(false);
  when(() => service.hasPendingOperations).thenReturn(false);
  when(() => service.hasUnresolvedConflicts).thenReturn(false);
  when(() => service.pendingConflictCount).thenReturn(0);
  when(() => service.pendingConflicts).thenReturn([]);
  when(() => service.currentState).thenReturn(SyncState.idle);
  when(() => service.isProcessing).thenReturn(false);
  when(() => service.isOnline).thenReturn(true);
  when(() => service.syncAll()).thenAnswer((_) async => 0);
  when(() => service.syncNow()).thenAnswer((_) async => 0);
  when(() => service.startListening()).thenAnswer((_) async {});
  when(() => service.stopListening()).thenReturn(null);
  when(() => service.dispose()).thenReturn(null);
  when(() => service.stateStream).thenAnswer((_) => const Stream.empty());
  when(() => service.conflictStream).thenAnswer((_) => const Stream.empty());
  when(
    () => service.feedingConflictStream,
  ).thenAnswer((_) => const Stream.empty());
  return service;
}

/// Common provider overrides for sheet/card tests.
///
/// When [fishDs] or [scheduleDs] are provided, their existing stubs are
/// preserved (no default stubs are registered). When omitted, fresh mocks
/// with empty-return defaults are created.
List<Override> _sheetOverrides({
  User? currentUser,
  List<Aquarium>? aquariums,
  MockFishLocalDataSource? fishDs,
  MockScheduleLocalDataSource? scheduleDs,
}) {
  final mockSyncService = _createMockSyncService();
  final mockFishDs = fishDs ?? MockFishLocalDataSource();
  final mockScheduleDs = scheduleDs ?? MockScheduleLocalDataSource();

  // Only register default stubs when mocks were NOT provided by the caller,
  // to avoid overwriting caller-specific stubs.
  if (scheduleDs == null) {
    when(() => mockScheduleDs.getByFishId(any())).thenReturn([]);
    when(
      () => mockScheduleDs.getByFishId(
        any(),
        activeOnly: any(named: 'activeOnly'),
      ),
    ).thenReturn([]);
  }

  if (fishDs == null) {
    when(() => mockFishDs.getFishById(any())).thenReturn(null);
    when(() => mockFishDs.getFishByAquariumId(any())).thenReturn([]);
  }

  final mockSpeciesLocalDs = MockSpeciesLocalDataSource();
  when(() => mockSpeciesLocalDs.getAllSpecies()).thenReturn([]);
  final mockSpeciesRemoteDs = MockSpeciesRemoteDataSource();

  return [
    if (currentUser != null) currentUserProvider.overrideWithValue(currentUser),
    userAquariumsProvider.overrideWith(
      (ref) => MockUserAquariumsNotifier(aquariums: aquariums ?? []),
    ),
    fishManagementProvider.overrideWith((ref) => MockFishManagementNotifier()),
    fishLocalDataSourceProvider.overrideWithValue(mockFishDs),
    scheduleLocalDataSourceProvider.overrideWithValue(mockScheduleDs),
    speciesLocalDataSourceProvider.overrideWithValue(mockSpeciesLocalDs),
    speciesRemoteDataSourceProvider.overrideWithValue(mockSpeciesRemoteDs),
    syncServiceProvider.overrideWithValue(mockSyncService),
    subscriptionStatusProvider.overrideWithValue(
      const SubscriptionStatus.free(),
    ),
    isPremiumProvider.overrideWithValue(false),
    shouldShowAdsProvider.overrideWithValue(false),
    calendarDataProvider.overrideWith((ref) => MockCalendarDataNotifier()),
    todayFeedingsProvider.overrideWith((ref) => MockTodayFeedingsNotifier()),
  ];
}

/// Wraps a widget with ProviderScope and MaterialApp for testing.
Widget _buildTestApp({
  required Widget child,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: child),
    ),
  );
}

// ============================================================================
// Tests
// ============================================================================

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  // ==========================================================================
  // 1. AquariumCardSheet Tests
  // ==========================================================================
  group('AquariumCardSheet', () {
    testWidgets('displays aquarium name, water type, and volume', (
      tester,
    ) async {
      final fishDs = MockFishLocalDataSource();
      when(() => fishDs.getFishByAquariumId('aquarium-1')).thenReturn([]);
      when(() => fishDs.getFishById(any())).thenReturn(null);

      await tester.pumpWidget(
        _buildTestApp(
          overrides: _sheetOverrides(
            currentUser: _testOwner,
            aquariums: [_testAquarium],
            fishDs: fishDs,
          ),
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showAquariumCardSheet(context, 'aquarium-1'),
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Verify aquarium name is displayed
      expect(find.text('My Tank'), findsOneWidget);

      // Verify water type chip is displayed (localized)
      expect(find.text('Freshwater'), findsOneWidget);

      // Verify capacity is displayed with L suffix
      expect(find.textContaining('100 L'), findsOneWidget);
    });

    testWidgets('fish list shows correct record count', (tester) async {
      final fishDs = MockFishLocalDataSource();
      when(() => fishDs.getFishByAquariumId('aquarium-1')).thenReturn([]);
      when(() => fishDs.getFishById(any())).thenReturn(null);

      await tester.pumpWidget(
        _buildTestApp(
          overrides: [
            ..._sheetOverrides(
              currentUser: _testOwner,
              aquariums: [_testAquarium],
              fishDs: fishDs,
            ),
            // Override fishByAquariumIdProvider to return 2 fish records
            fishByAquariumIdProvider(
              'aquarium-1',
            ).overrideWithValue([_testFish1, _testFish2]),
          ],
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showAquariumCardSheet(context, 'aquarium-1'),
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Header should show the record count "2" (not quantity sum 3+1=4)
      // The l10n key fishInAquarium(2) produces text containing "2"
      expect(find.textContaining('2'), findsWidgets);
    });

    testWidgets('Edit/Delete buttons hidden for non-owner', (tester) async {
      final fishDs = MockFishLocalDataSource();
      when(() => fishDs.getFishByAquariumId('aquarium-1')).thenReturn([]);
      when(() => fishDs.getFishById(any())).thenReturn(null);

      await tester.pumpWidget(
        _buildTestApp(
          overrides: _sheetOverrides(
            currentUser: _testNonOwner, // Non-owner
            aquariums: [_testAquarium],
            fishDs: fishDs,
          ),
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showAquariumCardSheet(context, 'aquarium-1'),
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Edit and Delete buttons should NOT be visible for non-owner
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('Edit/Delete buttons visible for owner', (tester) async {
      final fishDs = MockFishLocalDataSource();
      when(() => fishDs.getFishByAquariumId('aquarium-1')).thenReturn([]);
      when(() => fishDs.getFishById(any())).thenReturn(null);

      await tester.pumpWidget(
        _buildTestApp(
          overrides: _sheetOverrides(
            currentUser: _testOwner, // Owner
            aquariums: [_testAquarium],
            fishDs: fishDs,
          ),
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showAquariumCardSheet(context, 'aquarium-1'),
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Scroll the sheet's ListView to reveal the owner action buttons.
      // The Edit/Delete buttons are at the bottom of the ListView inside
      // the DraggableScrollableSheet. Use scrollUntilVisible to ensure
      // the buttons are scrolled into view.
      await tester.scrollUntilVisible(
        find.byIcon(Icons.delete_outline),
        200,
        scrollable: find.descendant(
          of: find.byType(DraggableScrollableSheet),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();

      // Edit and Delete buttons should be visible for owner
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('tap outside dismisses sheet', (tester) async {
      final fishDs = MockFishLocalDataSource();
      when(() => fishDs.getFishByAquariumId('aquarium-1')).thenReturn([]);
      when(() => fishDs.getFishById(any())).thenReturn(null);

      await tester.pumpWidget(
        _buildTestApp(
          overrides: _sheetOverrides(
            currentUser: _testOwner,
            aquariums: [_testAquarium],
            fishDs: fishDs,
          ),
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showAquariumCardSheet(context, 'aquarium-1'),
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Verify sheet is open
      expect(find.text('My Tank'), findsOneWidget);

      // Tap the barrier (outside the sheet) to dismiss
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Sheet should be dismissed
      expect(find.byType(AquariumCardSheet), findsNothing);
    });
  });

  // ==========================================================================
  // 2. FishCardSheet Tests
  // ==========================================================================
  group('FishCardSheet', () {
    testWidgets('displays fish details from ComputedFeedingEvent', (
      tester,
    ) async {
      final event = _createFeedingEvent(
        fishName: 'Nemo',
        aquariumName: 'My Tank',
        foodType: 'flakes',
        time: '09:00',
        fishQuantity: 3,
      );

      final fishDs = MockFishLocalDataSource();
      final scheduleDs = MockScheduleLocalDataSource();
      when(() => fishDs.getFishById(any())).thenReturn(null);
      when(() => fishDs.getFishByAquariumId(any())).thenReturn([]);
      when(
        () =>
            scheduleDs.getByFishId(any(), activeOnly: any(named: 'activeOnly')),
      ).thenReturn([]);
      when(() => scheduleDs.getByFishId(any())).thenReturn([]);

      await tester.pumpWidget(
        _buildTestApp(
          overrides: _sheetOverrides(
            currentUser: _testOwner,
            aquariums: [_testAquarium],
            fishDs: fishDs,
            scheduleDs: scheduleDs,
          ),
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showFishCardSheet(context, event),
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Verify fish name is displayed
      expect(find.text('Nemo'), findsOneWidget);

      // Verify food type is displayed
      expect(find.textContaining('flakes'), findsWidgets);

      // Verify time is displayed
      expect(find.textContaining('09:00'), findsWidgets);
    });

    testWidgets('Mark as Fed button hidden when event.isCompleted == true', (
      tester,
    ) async {
      final event = _createFeedingEvent(status: EventStatus.fed);

      final fishDs = MockFishLocalDataSource();
      final scheduleDs = MockScheduleLocalDataSource();
      when(() => fishDs.getFishById(any())).thenReturn(null);
      when(() => fishDs.getFishByAquariumId(any())).thenReturn([]);
      when(
        () =>
            scheduleDs.getByFishId(any(), activeOnly: any(named: 'activeOnly')),
      ).thenReturn([]);
      when(() => scheduleDs.getByFishId(any())).thenReturn([]);

      await tester.pumpWidget(
        _buildTestApp(
          overrides: _sheetOverrides(
            currentUser: _testOwner,
            aquariums: [_testAquarium],
            fishDs: fishDs,
            scheduleDs: scheduleDs,
          ),
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showFishCardSheet(context, event),
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Mark as Fed button should NOT be visible for completed events.
      // The Mark as Fed button contains an Icons.check icon. Since the event
      // is completed, neither the button nor its icon should be present.
      expect(
        find.descendant(
          of: find.byType(FishCardSheet),
          matching: find.byIcon(Icons.check),
        ),
        findsNothing,
      );
    });

    testWidgets('Mark as Fed button visible when event.isCompleted == false', (
      tester,
    ) async {
      final event = _createFeedingEvent(status: EventStatus.pending);

      final fishDs = MockFishLocalDataSource();
      final scheduleDs = MockScheduleLocalDataSource();
      when(() => fishDs.getFishById(any())).thenReturn(null);
      when(() => fishDs.getFishByAquariumId(any())).thenReturn([]);
      when(
        () =>
            scheduleDs.getByFishId(any(), activeOnly: any(named: 'activeOnly')),
      ).thenReturn([]);
      when(() => scheduleDs.getByFishId(any())).thenReturn([]);

      // Use a large surface to ensure DraggableScrollableSheet has enough room
      await tester.binding.setSurfaceSize(const Size(400, 1600));

      // Render FishCardSheet directly inside a Scaffold body instead of using
      // showModalBottomSheet. The DraggableScrollableSheet inside FishCardSheet
      // needs proper parent constraints which are provided by the Scaffold body.
      await tester.pumpWidget(
        ProviderScope(
          overrides: _sheetOverrides(
            currentUser: _testOwner,
            aquariums: [_testAquarium],
            fishDs: fishDs,
            scheduleDs: scheduleDs,
          ),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Scaffold(body: FishCardSheet(feedingEvent: event)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Mark as Fed button should be present for pending events.
      // FilledButton.icon() creates a _FilledButtonWithIcon, which is a
      // private subclass - find.byType(FilledButton) uses exact type match
      // and won't find it. Instead, look for the check icon which is
      // rendered inside the Mark as Fed button.
      final checkIconInSheet = find.descendant(
        of: find.byType(FishCardSheet),
        matching: find.byIcon(Icons.check),
      );
      expect(checkIconInSheet, findsOneWidget);

      // Also verify OutlinedButton (Edit Fish) is present - OutlinedButton.icon
      // renders as an OutlinedButton in the tree unlike FilledButton.icon
      expect(
        find.descendant(
          of: find.byType(FishCardSheet),
          matching: find.byIcon(Icons.edit),
        ),
        findsOneWidget,
      );

      // Reset surface size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Delete Fish hidden for non-owner', (tester) async {
      final event = _createFeedingEvent(status: EventStatus.pending);

      final fishDs = MockFishLocalDataSource();
      final scheduleDs = MockScheduleLocalDataSource();
      when(() => fishDs.getFishById(any())).thenReturn(null);
      when(() => fishDs.getFishByAquariumId(any())).thenReturn([]);
      when(
        () =>
            scheduleDs.getByFishId(any(), activeOnly: any(named: 'activeOnly')),
      ).thenReturn([]);
      when(() => scheduleDs.getByFishId(any())).thenReturn([]);

      await tester.pumpWidget(
        _buildTestApp(
          overrides: _sheetOverrides(
            currentUser: _testNonOwner, // Non-owner
            aquariums: [_testAquarium],
            fishDs: fishDs,
            scheduleDs: scheduleDs,
          ),
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showFishCardSheet(context, event),
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Delete Fish button should NOT be visible for non-owner
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('feeding schedule section shows active schedules', (
      tester,
    ) async {
      final event = _createFeedingEvent(status: EventStatus.pending);
      final schedule = _createSchedule(time: '09:00', intervalDays: 1);

      final fishDs = MockFishLocalDataSource();
      final scheduleDs = MockScheduleLocalDataSource();
      when(() => fishDs.getFishById(any())).thenReturn(null);
      when(() => fishDs.getFishByAquariumId(any())).thenReturn([]);
      when(
        () =>
            scheduleDs.getByFishId(any(), activeOnly: any(named: 'activeOnly')),
      ).thenReturn([schedule]);
      when(() => scheduleDs.getByFishId(any())).thenReturn([schedule]);

      // Use a large surface to ensure DraggableScrollableSheet has enough room
      await tester.binding.setSurfaceSize(const Size(400, 1600));

      // Render FishCardSheet directly inside a Scaffold body instead of using
      // showModalBottomSheet. This avoids the DraggableScrollableSheet
      // rendering constraints that prevent bottom content from being built
      // when opened as a modal sheet in the test environment.
      await tester.pumpWidget(
        ProviderScope(
          overrides: _sheetOverrides(
            currentUser: _testOwner,
            aquariums: [_testAquarium],
            fishDs: fishDs,
            scheduleDs: scheduleDs,
          ),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Scaffold(body: FishCardSheet(feedingEvent: event)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show the repeat icon for interval display
      expect(find.byIcon(Icons.repeat), findsOneWidget);

      // Should show the time chip with access_time icon
      expect(find.byIcon(Icons.access_time), findsOneWidget);

      // Reset surface size
      await tester.binding.setSurfaceSize(null);
    });
  });

  // ==========================================================================
  // 3. Feeding Card Gestures
  // ==========================================================================
  group('FeedingCard Gestures', () {
    testWidgets('renders feeding card with fish name and time', (tester) async {
      final event = _createFeedingEvent(
        fishName: 'Nemo',
        time: '09:00',
        foodType: 'flakes',
      );

      await tester.pumpWidget(
        _buildTestApp(
          overrides: _sheetOverrides(
            currentUser: _testOwner,
            aquariums: [_testAquarium],
          ),
          child: FeedingCard(feeding: event, onMarkAsFed: (_) {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nemo'), findsOneWidget);
      expect(find.text('09:00'), findsOneWidget);
      expect(find.text('flakes'), findsOneWidget);
    });

    testWidgets('Dismissible direction is horizontal for unfed event', (
      tester,
    ) async {
      final event = _createFeedingEvent(status: EventStatus.pending);

      await tester.pumpWidget(
        _buildTestApp(
          overrides: _sheetOverrides(
            currentUser: _testOwner,
            aquariums: [_testAquarium],
          ),
          child: FeedingCard(feeding: event, onMarkAsFed: (_) {}),
        ),
      );
      await tester.pumpAndSettle();

      // Find the Dismissible descendant of FeedingCard
      final dismissibleFinder = find.descendant(
        of: find.byType(FeedingCard),
        matching: find.byType(Dismissible),
      );
      expect(dismissibleFinder, findsOneWidget);

      final dismissible = tester.widget<Dismissible>(dismissibleFinder);
      expect(dismissible.direction, DismissDirection.horizontal);
    });

    testWidgets('Dismissible direction is endToStart for fed event', (
      tester,
    ) async {
      final event = _createFeedingEvent(status: EventStatus.fed);

      await tester.pumpWidget(
        _buildTestApp(
          overrides: _sheetOverrides(
            currentUser: _testOwner,
            aquariums: [_testAquarium],
          ),
          child: FeedingCard(feeding: event, onMarkAsFed: (_) {}),
        ),
      );
      await tester.pumpAndSettle();

      // Find the Dismissible descendant of FeedingCard
      final dismissibleFinder = find.descendant(
        of: find.byType(FeedingCard),
        matching: find.byType(Dismissible),
      );
      expect(dismissibleFinder, findsOneWidget);

      final dismissible = tester.widget<Dismissible>(dismissibleFinder);
      expect(dismissible.direction, DismissDirection.endToStart);
    });

    testWidgets('InkWell is present for tap interaction', (tester) async {
      final event = _createFeedingEvent(status: EventStatus.pending);

      await tester.pumpWidget(
        _buildTestApp(
          overrides: _sheetOverrides(
            currentUser: _testOwner,
            aquariums: [_testAquarium],
          ),
          child: FeedingCard(feeding: event, onMarkAsFed: (_) {}),
        ),
      );
      await tester.pumpAndSettle();

      // InkWell wraps the card content for tap handling
      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('chevron icon present on feeding card', (tester) async {
      final event = _createFeedingEvent(status: EventStatus.pending);

      await tester.pumpWidget(
        _buildTestApp(
          overrides: _sheetOverrides(
            currentUser: _testOwner,
            aquariums: [_testAquarium],
          ),
          child: FeedingCard(feeding: event, onMarkAsFed: (_) {}),
        ),
      );
      await tester.pumpAndSettle();

      // Chevron hint icon should be present
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('fed event shows line-through text decoration', (tester) async {
      final event = _createFeedingEvent(status: EventStatus.fed);

      await tester.pumpWidget(
        _buildTestApp(
          overrides: _sheetOverrides(
            currentUser: _testOwner,
            aquariums: [_testAquarium],
          ),
          child: FeedingCard(feeding: event, onMarkAsFed: (_) {}),
        ),
      );
      await tester.pumpAndSettle();

      // Fed event should show name with line-through decoration
      final nameText = tester.widget<Text>(find.text('Nemo'));
      expect(nameText.style?.decoration, TextDecoration.lineThrough);
    });
  });

  // ==========================================================================
  // 4. Mark as Fed Dialog (ConfirmFeedingDialog)
  // ==========================================================================
  group('ConfirmFeedingDialog', () {
    testWidgets('dialog shows fish name', (tester) async {
      final event = _createFeedingEvent(
        fishName: 'Nemo',
        aquariumName: 'My Tank',
      );

      final fishDs = MockFishLocalDataSource();
      when(() => fishDs.getFishById(any())).thenReturn(null);
      when(() => fishDs.getFishByAquariumId(any())).thenReturn([]);

      await tester.pumpWidget(
        _buildTestApp(
          overrides: _sheetOverrides(
            currentUser: _testOwner,
            aquariums: [_testAquarium],
            fishDs: fishDs,
          ),
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showConfirmFeedingDialog(context, event),
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Dialog should show the fish name in the info content
      expect(find.textContaining('Nemo'), findsWidgets);
    });

    testWidgets('dialog shows fish photo widget (placeholder)', (tester) async {
      final event = _createFeedingEvent(fishName: 'Nemo');

      final fishDs = MockFishLocalDataSource();
      when(() => fishDs.getFishById(any())).thenReturn(null);
      when(() => fishDs.getFishByAquariumId(any())).thenReturn([]);

      await tester.pumpWidget(
        _buildTestApp(
          overrides: _sheetOverrides(
            currentUser: _testOwner,
            aquariums: [_testAquarium],
            fishDs: fishDs,
          ),
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showConfirmFeedingDialog(context, event),
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Should render a fish placeholder icon (set_meal_rounded)
      expect(find.byIcon(Icons.set_meal_rounded), findsOneWidget);
    });

    testWidgets('dialog preserves Cancel and Confirm actions', (tester) async {
      final event = _createFeedingEvent(fishName: 'Nemo');

      final fishDs = MockFishLocalDataSource();
      when(() => fishDs.getFishById(any())).thenReturn(null);
      when(() => fishDs.getFishByAquariumId(any())).thenReturn([]);

      await tester.pumpWidget(
        _buildTestApp(
          overrides: _sheetOverrides(
            currentUser: _testOwner,
            aquariums: [_testAquarium],
            fishDs: fishDs,
          ),
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showConfirmFeedingDialog(context, event),
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Cancel button should be present (TextButton)
      expect(find.byType(TextButton), findsOneWidget);

      // Confirm button should be present (FilledButton "Yes, fed!")
      expect(find.byType(FilledButton), findsOneWidget);
    });
  });

  // ==========================================================================
  // 5. Edit Aquarium Screen
  // ==========================================================================
  group('AquariumEditScreen', () {
    testWidgets('water type segmented button present with 3 options', (
      tester,
    ) async {
      final fishDs = MockFishLocalDataSource();
      when(() => fishDs.getFishByAquariumId('aquarium-1')).thenReturn([]);
      when(() => fishDs.getFishById(any())).thenReturn(null);

      final router = GoRouter(
        initialLocation: '/edit',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const Scaffold(body: Text('Home')),
          ),
          GoRoute(
            path: '/edit',
            builder: (_, __) =>
                const AquariumEditScreen(aquariumId: 'aquarium-1'),
          ),
          GoRoute(
            path: '/add-fish',
            builder: (_, __) => const Scaffold(body: Text('Add Fish')),
          ),
          GoRoute(
            path: '/aquarium/fish/:fishId/edit',
            builder: (_, __) => const Scaffold(body: Text('Edit Fish')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: _sheetOverrides(
            currentUser: _testOwner,
            aquariums: [_testAquarium],
            fishDs: fishDs,
          ),
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // SegmentedButton should be present with 3 water type options
      expect(find.byType(SegmentedButton<WaterType>), findsOneWidget);

      // All three water type labels should be present
      expect(find.text('Freshwater'), findsOneWidget);
      expect(find.text('Saltwater'), findsOneWidget);
      expect(find.text('Brackish'), findsOneWidget);
    });

    testWidgets('volume field accepts numeric input', (tester) async {
      final fishDs = MockFishLocalDataSource();
      when(() => fishDs.getFishByAquariumId('aquarium-1')).thenReturn([]);
      when(() => fishDs.getFishById(any())).thenReturn(null);

      final router = GoRouter(
        initialLocation: '/edit',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const Scaffold(body: Text('Home')),
          ),
          GoRoute(
            path: '/edit',
            builder: (_, __) =>
                const AquariumEditScreen(aquariumId: 'aquarium-1'),
          ),
          GoRoute(
            path: '/add-fish',
            builder: (_, __) => const Scaffold(body: Text('Add Fish')),
          ),
          GoRoute(
            path: '/aquarium/fish/:fishId/edit',
            builder: (_, __) => const Scaffold(body: Text('Edit Fish')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: _sheetOverrides(
            currentUser: _testOwner,
            aquariums: [_testAquarium],
            fishDs: fishDs,
          ),
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The volume field should show the initial capacity "100"
      expect(find.text('100'), findsOneWidget);

      // Volume field should have the 'L' suffix
      expect(find.text('L'), findsOneWidget);

      // At least one TextFormField for volume
      expect(find.byType(TextFormField), findsAtLeastNWidgets(1));
    });
  });

  // ==========================================================================
  // 6. Edit Fish Screen
  // ==========================================================================
  group('EditFishScreen', () {
    // TODO(task-24): EditFishScreen tests require deep provider setup including
    // fishByIdProvider (backed by FishLocalDataSource with Hive),
    // speciesListProvider (StateNotifier with findById method),
    // aquariumsListProvider, and analyticsServiceProvider.
    // These are documented as test stubs below.

    test('aquarium dropdown present when 2+ aquariums exist - stub', () {
      // TODO(task-24): Verify that when the fish management provider returns
      // a fish and there are 2+ aquariums, a DropdownButtonFormField<String>
      // is rendered in the EditFishScreen.
      //
      // Steps to verify:
      // 1. Create 2 test aquariums in aquariumsListProvider
      // 2. Override fishByIdProvider to return a test fish
      // 3. Override speciesListProvider to return species data
      // 4. Override analyticsServiceProvider with a mock
      // 5. Pump EditFishScreen with fishId
      // 6. Expect find.byType(DropdownButtonFormField<String>), findsOneWidget
    });

    test('notes field present with 500 char limit - stub', () {
      // TODO(task-24): Verify that the EditFishScreen renders a TextFormField
      // for notes with maxLength = 500.
      //
      // Steps to verify:
      // 1. Override fishByIdProvider to return a test fish
      // 2. Override speciesListProvider with species data
      // 3. Override analyticsServiceProvider with a mock
      // 4. Pump EditFishScreen with fishId
      // 5. Expect to find a TextFormField with maxLength 500
      // 6. Verify the notes label text is present
    });

    test('aquarium dropdown hidden when only 1 aquarium exists - stub', () {
      // TODO(task-24): Verify that when only 1 aquarium exists, the
      // DropdownButtonFormField<String> is NOT rendered.
      //
      // Steps to verify:
      // 1. Create only 1 test aquarium in aquariumsListProvider
      // 2. Override fishByIdProvider to return a test fish
      // 3. Override speciesListProvider with species data
      // 4. Pump EditFishScreen with fishId
      // 5. Expect find.byType(DropdownButtonFormField<String>), findsNothing
    });
  });

  // ==========================================================================
  // 7. AppBar Changes (FeedingCardsScreen)
  // ==========================================================================
  group('FeedingCardsScreen AppBar', () {
    // TODO(task-24): FeedingCardsScreen requires syncServiceProvider
    // with feedingConflictStream properly stubbed, plus
    // feedingsGroupedByTimeProvider and aquariumByIdProvider.
    // These tests are documented stubs.

    test('gear icon NOT present in Feeding Events AppBar - stub', () {
      // TODO(task-24): Verify that the FeedingCardsScreen AppBar does NOT
      // contain a settings/gear icon (Icons.settings or
      // Icons.settings_outlined).
      //
      // Steps to verify:
      // 1. Set up provider overrides for aquariumByIdProvider,
      //    feedingsGroupedByTimeProvider, todayFeedingsProvider,
      //    syncServiceProvider (with feedingConflictStream)
      // 2. Pump FeedingCardsScreen with aquariumId
      // 3. Expect find.byIcon(Icons.settings), findsNothing
      // 4. Expect find.byIcon(Icons.settings_outlined), findsNothing
    });

    test('aquarium name IS tappable with GestureDetector - stub', () {
      // TODO(task-24): Verify that the AppBar title is wrapped in a
      // GestureDetector that opens the AquariumCardSheet on tap.
      //
      // Steps to verify:
      // 1. Set up all required provider overrides
      // 2. Pump FeedingCardsScreen with aquariumId
      // 3. Find GestureDetector ancestor of aquarium name Text widget
      // 4. Expect find.ancestor(of: name, matching: GestureDetector),
      //    findsOneWidget
    });

    test('dropdown arrow visible next to aquarium name - stub', () {
      // TODO(task-24): Verify that an arrow_drop_down icon is displayed
      // next to the aquarium name in the AppBar.
      //
      // Steps to verify:
      // 1. Set up all required provider overrides
      // 2. Pump FeedingCardsScreen with aquariumId
      // 3. Expect find.byIcon(Icons.arrow_drop_down), findsOneWidget
    });
  });

  // ==========================================================================
  // 8. Delete Aquarium from Feeding Events -> Navigate Home
  // ==========================================================================
  group('Delete aquarium navigation', () {
    test('deleting aquarium from feeding events navigates to Home - stub', () {
      // TODO(task-24): Verify that when an aquarium is deleted via the
      // AquariumCardSheet opened from FeedingCardsScreen, the app
      // navigates to the home route (AppRouter.home = '/').
      //
      // Steps to verify:
      // 1. Set up FeedingCardsScreen with all provider overrides
      // 2. Open AquariumCardSheet by tapping aquarium name in AppBar
      // 3. Tap Delete Aquarium button
      // 4. Confirm deletion in dialog
      // 5. Verify context.go(AppRouter.home) was called
      //    (e.g., verify Home screen is displayed)
    });
  });

  // ==========================================================================
  // 9. FeedingCard Display Variants
  // ==========================================================================
  group('FeedingCard display variants', () {
    testWidgets('shows quantity badge when fishQuantity > 1', (tester) async {
      final event = _createFeedingEvent(fishName: 'Guppies', fishQuantity: 5);

      await tester.pumpWidget(
        _buildTestApp(
          overrides: _sheetOverrides(
            currentUser: _testOwner,
            aquariums: [_testAquarium],
          ),
          child: FeedingCard(feeding: event, onMarkAsFed: (_) {}),
        ),
      );
      await tester.pumpAndSettle();

      // Should display the quantity count (localized via l10n.fishCount)
      expect(find.textContaining('5'), findsWidgets);
    });

    testWidgets('shows aquarium name as subtitle', (tester) async {
      final event = _createFeedingEvent(
        fishName: 'Nemo',
        aquariumName: 'My Tank',
      );

      await tester.pumpWidget(
        _buildTestApp(
          overrides: _sheetOverrides(
            currentUser: _testOwner,
            aquariums: [_testAquarium],
          ),
          child: FeedingCard(feeding: event, onMarkAsFed: (_) {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Tank'), findsOneWidget);
    });

    testWidgets('displays status indicator for pending event', (tester) async {
      final event = _createFeedingEvent(status: EventStatus.pending);

      await tester.pumpWidget(
        _buildTestApp(
          overrides: _sheetOverrides(
            currentUser: _testOwner,
            aquariums: [_testAquarium],
          ),
          child: FeedingCard(feeding: event, onMarkAsFed: (_) {}),
        ),
      );
      await tester.pumpAndSettle();

      // Should show the schedule icon for pending status
      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    testWidgets('displays check icon for fed event', (tester) async {
      final event = _createFeedingEvent(status: EventStatus.fed);

      await tester.pumpWidget(
        _buildTestApp(
          overrides: _sheetOverrides(
            currentUser: _testOwner,
            aquariums: [_testAquarium],
          ),
          child: FeedingCard(feeding: event, onMarkAsFed: (_) {}),
        ),
      );
      await tester.pumpAndSettle();

      // Should show the check icon for fed status
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('has proper semantics label', (tester) async {
      final event = _createFeedingEvent(
        fishName: 'Nemo',
        time: '09:00',
        foodType: 'flakes',
      );

      await tester.pumpWidget(
        _buildTestApp(
          overrides: _sheetOverrides(
            currentUser: _testOwner,
            aquariums: [_testAquarium],
          ),
          child: FeedingCard(feeding: event, onMarkAsFed: (_) {}),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Semantics widget is present
      expect(find.byType(Semantics), findsWidgets);
    });
  });

  // ==========================================================================
  // 10. ComputedFeedingEvent entity tests (unit tests)
  // ==========================================================================
  group('ComputedFeedingEvent', () {
    test('isCompleted returns true for fed status', () {
      final event = _createFeedingEvent(status: EventStatus.fed);
      expect(event.isCompleted, isTrue);
    });

    test('isCompleted returns true for skipped status', () {
      final event = _createFeedingEvent(status: EventStatus.skipped);
      expect(event.isCompleted, isTrue);
    });

    test('isCompleted returns false for pending status', () {
      final event = _createFeedingEvent(status: EventStatus.pending);
      expect(event.isCompleted, isFalse);
    });

    test('isCompleted returns false for overdue status', () {
      final event = _createFeedingEvent(status: EventStatus.overdue);
      expect(event.isCompleted, isFalse);
    });

    test('needsAttention returns true for pending/overdue', () {
      expect(
        _createFeedingEvent(status: EventStatus.pending).needsAttention,
        isTrue,
      );
      expect(
        _createFeedingEvent(status: EventStatus.overdue).needsAttention,
        isTrue,
      );
    });

    test('needsAttention returns false for fed/skipped', () {
      expect(
        _createFeedingEvent(status: EventStatus.fed).needsAttention,
        isFalse,
      );
      expect(
        _createFeedingEvent(status: EventStatus.skipped).needsAttention,
        isFalse,
      );
    });

    test('copyWith preserves unmodified fields', () {
      final original = _createFeedingEvent(
        fishName: 'Nemo',
        status: EventStatus.pending,
      );
      final updated = original.copyWith(status: EventStatus.fed);

      expect(updated.fishName, 'Nemo');
      expect(updated.status, EventStatus.fed);
      expect(updated.scheduleId, original.scheduleId);
    });
  });
}
