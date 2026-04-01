import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/data/datasources/local/fish_local_ds.dart';
import 'package:fishfeed/data/datasources/local/local_datasources_providers.dart';
import 'package:fishfeed/data/datasources/local/schedule_local_ds.dart';
import 'package:fishfeed/data/models/fish_model.dart';
import 'package:fishfeed/data/datasources/local/species_local_ds.dart';
import 'package:fishfeed/data/datasources/remote/species_remote_ds.dart';
import 'package:fishfeed/data/models/schedule_model.dart';
import 'package:fishfeed/domain/entities/aquarium.dart';
import 'package:fishfeed/domain/entities/feeding_event.dart';
import 'package:fishfeed/domain/entities/fish.dart';
import 'package:fishfeed/domain/entities/subscription_status.dart';
import 'package:fishfeed/domain/entities/user.dart';
import 'package:fishfeed/domain/entities/water_type.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/aquarium_providers.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';
import 'package:fishfeed/presentation/providers/feeding_providers.dart';
import 'package:fishfeed/presentation/providers/fish_management_provider.dart';
import 'package:fishfeed/presentation/widgets/feeding/fish_card_sheet.dart';

// ============================================================================
// Mocks
// ============================================================================

class MockFishLocalDataSource extends Mock implements FishLocalDataSource {}

class MockScheduleLocalDataSource extends Mock
    implements ScheduleLocalDataSource {}

class MockSpeciesLocalDataSource extends Mock
    implements SpeciesLocalDataSource {}

class MockSpeciesRemoteDataSource extends Mock
    implements SpeciesRemoteDataSource {}

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

class MockTodayFeedingsNotifier extends StateNotifier<TodayFeedingsState>
    implements TodayFeedingsNotifier {
  MockTodayFeedingsNotifier()
    : super(const TodayFeedingsState(feedings: [], isLoading: false));

  String? lastMarkedFedId;

  @override
  Future<void> loadFeedings() async {}

  @override
  Future<void> refresh() async {}

  @override
  Future<void> markAsFed(String feedingId) async {
    lastMarkedFedId = feedingId;
  }

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

final _testFish = Fish(
  id: 'fish-1',
  aquariumId: 'aquarium-1',
  speciesId: 'guppy',
  name: 'Nemo',
  quantity: 3,
  notes: 'Loves flakes',
  addedAt: DateTime(2024, 1, 20),
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
// Helpers
// ============================================================================

MockFishLocalDataSource _createFishDs({Fish? fish}) {
  final ds = MockFishLocalDataSource();
  final fishModel = fish != null ? FishModel.fromEntity(fish) : null;
  when(() => ds.getFishById(any())).thenReturn(fishModel);
  when(() => ds.getFishByAquariumId(any())).thenReturn([]);
  return ds;
}

MockScheduleLocalDataSource _createScheduleDs({
  List<ScheduleModel>? schedules,
}) {
  final ds = MockScheduleLocalDataSource();
  when(() => ds.getByFishId(any())).thenReturn(schedules ?? []);
  when(
    () => ds.getByFishId(any(), activeOnly: any(named: 'activeOnly')),
  ).thenReturn(schedules ?? []);
  return ds;
}

List<Override> _buildOverrides({
  User? currentUser,
  List<Aquarium>? aquariums,
  MockFishLocalDataSource? fishDs,
  MockScheduleLocalDataSource? scheduleDs,
  MockTodayFeedingsNotifier? feedingsNotifier,
}) {
  final mockFishDs = fishDs ?? _createFishDs();
  final mockScheduleDs = scheduleDs ?? _createScheduleDs();
  final mockSpeciesLocalDs = MockSpeciesLocalDataSource();
  when(() => mockSpeciesLocalDs.getAllSpecies()).thenReturn([]);
  final mockSpeciesRemoteDs = MockSpeciesRemoteDataSource();

  return [
    if (currentUser != null) currentUserProvider.overrideWithValue(currentUser),
    if (aquariums != null)
      aquariumByIdProvider.overrideWith((ref, id) {
        try {
          return aquariums.firstWhere((a) => a.id == id);
        } catch (_) {
          return null;
        }
      }),
    fishManagementProvider.overrideWith((ref) => MockFishManagementNotifier()),
    fishLocalDataSourceProvider.overrideWithValue(mockFishDs),
    scheduleLocalDataSourceProvider.overrideWithValue(mockScheduleDs),
    speciesLocalDataSourceProvider.overrideWithValue(mockSpeciesLocalDs),
    speciesRemoteDataSourceProvider.overrideWithValue(mockSpeciesRemoteDs),
    todayFeedingsProvider.overrideWith(
      (ref) => feedingsNotifier ?? MockTodayFeedingsNotifier(),
    ),
  ];
}

/// Renders FishCardSheet directly in a Scaffold body.
///
/// DraggableScrollableSheet needs proper parent constraints, so rendering
/// directly avoids issues with modal bottom sheet sizing in tests.
Widget _buildSheetDirect({
  required ComputedFeedingEvent event,
  required List<Override> overrides,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: FishCardSheet(feedingEvent: event)),
    ),
  );
}

/// Renders a button that opens FishCardSheet via showFishCardSheet.
Widget _buildSheetViaModal({
  required ComputedFeedingEvent event,
  required List<Override> overrides,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showFishCardSheet(context, event),
            child: const Text('Open Sheet'),
          ),
        ),
      ),
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

  group('FishCardSheet', () {
    group('Display', () {
      testWidgets('displays fish name from feeding event', (tester) async {
        final event = _createFeedingEvent(fishName: 'Guppy');

        await tester.pumpWidget(
          _buildSheetViaModal(
            event: event,
            overrides: _buildOverrides(
              currentUser: _testOwner,
              aquariums: [_testAquarium],
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        expect(find.text('Guppy'), findsOneWidget);
      });

      testWidgets('displays food type', (tester) async {
        final event = _createFeedingEvent(foodType: 'Pellets');

        await tester.pumpWidget(
          _buildSheetViaModal(
            event: event,
            overrides: _buildOverrides(
              currentUser: _testOwner,
              aquariums: [_testAquarium],
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Pellets'), findsWidgets);
      });

      testWidgets('displays scheduled time', (tester) async {
        final event = _createFeedingEvent(time: '14:30');

        await tester.pumpWidget(
          _buildSheetViaModal(
            event: event,
            overrides: _buildOverrides(
              currentUser: _testOwner,
              aquariums: [_testAquarium],
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        expect(find.textContaining('14:30'), findsWidgets);
      });

      testWidgets('displays fish quantity', (tester) async {
        final event = _createFeedingEvent(fishQuantity: 5);

        await tester.binding.setSurfaceSize(const Size(400, 1600));
        await tester.pumpWidget(
          _buildSheetDirect(
            event: event,
            overrides: _buildOverrides(
              currentUser: _testOwner,
              aquariums: [_testAquarium],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('5'), findsWidgets);
        await tester.binding.setSurfaceSize(null);
      });

      testWidgets('displays aquarium name', (tester) async {
        final event = _createFeedingEvent(aquariumName: 'Bedroom Tank');

        await tester.binding.setSurfaceSize(const Size(400, 1600));
        await tester.pumpWidget(
          _buildSheetDirect(
            event: event,
            overrides: _buildOverrides(
              currentUser: _testOwner,
              aquariums: [_testAquarium],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Bedroom Tank'), findsWidgets);
        await tester.binding.setSurfaceSize(null);
      });

      testWidgets('displays portion hint when present', (tester) async {
        final event = _createFeedingEvent(portionHint: '2 pinches');

        await tester.binding.setSurfaceSize(const Size(400, 1600));
        await tester.pumpWidget(
          _buildSheetDirect(
            event: event,
            overrides: _buildOverrides(
              currentUser: _testOwner,
              aquariums: [_testAquarium],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('2 pinches'), findsWidgets);
        await tester.binding.setSurfaceSize(null);
      });

      testWidgets('hides portion hint when null', (tester) async {
        final event = _createFeedingEvent(portionHint: null);

        await tester.binding.setSurfaceSize(const Size(400, 1600));
        await tester.pumpWidget(
          _buildSheetDirect(
            event: event,
            overrides: _buildOverrides(
              currentUser: _testOwner,
              aquariums: [_testAquarium],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.lightbulb_outline), findsNothing);
        await tester.binding.setSurfaceSize(null);
      });

      testWidgets('shows handle bar at top', (tester) async {
        final event = _createFeedingEvent();

        await tester.binding.setSurfaceSize(const Size(400, 1600));
        await tester.pumpWidget(
          _buildSheetDirect(
            event: event,
            overrides: _buildOverrides(
              currentUser: _testOwner,
              aquariums: [_testAquarium],
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Handle bar is a 32x4 Container
        final handleFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.constraints?.maxWidth == 32 &&
              widget.constraints?.maxHeight == 4,
        );
        expect(handleFinder, findsOneWidget);
        await tester.binding.setSurfaceSize(null);
      });

      testWidgets(
        'shows placeholder icon when no fish photo or species image',
        (tester) async {
          final event = _createFeedingEvent();

          await tester.binding.setSurfaceSize(const Size(400, 1600));
          await tester.pumpWidget(
            _buildSheetDirect(
              event: event,
              overrides: _buildOverrides(
                currentUser: _testOwner,
                aquariums: [_testAquarium],
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byIcon(Icons.set_meal_rounded), findsOneWidget);
          await tester.binding.setSurfaceSize(null);
        },
      );

      testWidgets('displays detail row icons', (tester) async {
        final event = _createFeedingEvent();

        await tester.binding.setSurfaceSize(const Size(400, 1600));
        await tester.pumpWidget(
          _buildSheetDirect(
            event: event,
            overrides: _buildOverrides(
              currentUser: _testOwner,
              aquariums: [_testAquarium],
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Quantity icon
        expect(find.byIcon(Icons.tag), findsOneWidget);
        // Aquarium icon
        expect(find.byIcon(Icons.water_drop_outlined), findsOneWidget);
        // Food type icon
        expect(find.byIcon(Icons.restaurant), findsOneWidget);
        // Scheduled time icon
        expect(find.byIcon(Icons.schedule), findsOneWidget);
        await tester.binding.setSurfaceSize(null);
      });

      testWidgets('displays fish notes when fish record has notes', (
        tester,
      ) async {
        final event = _createFeedingEvent();
        final fishDs = _createFishDs(fish: _testFish);

        await tester.binding.setSurfaceSize(const Size(400, 1600));
        await tester.pumpWidget(
          _buildSheetDirect(
            event: event,
            overrides: _buildOverrides(
              currentUser: _testOwner,
              aquariums: [_testAquarium],
              fishDs: fishDs,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Loves flakes'), findsOneWidget);
        expect(find.byIcon(Icons.notes), findsOneWidget);
        await tester.binding.setSurfaceSize(null);
      });

      testWidgets('displays added date when fish record exists', (
        tester,
      ) async {
        final event = _createFeedingEvent();
        final fishDs = _createFishDs(fish: _testFish);

        await tester.binding.setSurfaceSize(const Size(400, 1600));
        await tester.pumpWidget(
          _buildSheetDirect(
            event: event,
            overrides: _buildOverrides(
              currentUser: _testOwner,
              aquariums: [_testAquarium],
              fishDs: fishDs,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.calendar_today), findsOneWidget);
        await tester.binding.setSurfaceSize(null);
      });
    });

    group('Action Buttons - Owner', () {
      testWidgets('shows Mark as Fed button for pending event', (tester) async {
        final event = _createFeedingEvent(status: EventStatus.pending);

        await tester.binding.setSurfaceSize(const Size(400, 1600));
        await tester.pumpWidget(
          _buildSheetDirect(
            event: event,
            overrides: _buildOverrides(
              currentUser: _testOwner,
              aquariums: [_testAquarium],
            ),
          ),
        );
        await tester.pumpAndSettle();

        final checkIcon = find.descendant(
          of: find.byType(FishCardSheet),
          matching: find.byIcon(Icons.check),
        );
        expect(checkIcon, findsOneWidget);
        await tester.binding.setSurfaceSize(null);
      });

      testWidgets('hides Mark as Fed button for completed event', (
        tester,
      ) async {
        final event = _createFeedingEvent(status: EventStatus.fed);

        await tester.binding.setSurfaceSize(const Size(400, 1600));
        await tester.pumpWidget(
          _buildSheetDirect(
            event: event,
            overrides: _buildOverrides(
              currentUser: _testOwner,
              aquariums: [_testAquarium],
            ),
          ),
        );
        await tester.pumpAndSettle();

        final checkIcon = find.descendant(
          of: find.byType(FishCardSheet),
          matching: find.byIcon(Icons.check),
        );
        expect(checkIcon, findsNothing);
        await tester.binding.setSurfaceSize(null);
      });

      testWidgets('shows Edit Fish button for owner', (tester) async {
        final event = _createFeedingEvent(status: EventStatus.pending);

        await tester.binding.setSurfaceSize(const Size(400, 1600));
        await tester.pumpWidget(
          _buildSheetDirect(
            event: event,
            overrides: _buildOverrides(
              currentUser: _testOwner,
              aquariums: [_testAquarium],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byType(FishCardSheet),
            matching: find.byIcon(Icons.edit),
          ),
          findsOneWidget,
        );
        await tester.binding.setSurfaceSize(null);
      });

      testWidgets('shows Delete Fish button for owner', (tester) async {
        final event = _createFeedingEvent(status: EventStatus.pending);

        await tester.binding.setSurfaceSize(const Size(400, 1600));
        await tester.pumpWidget(
          _buildSheetDirect(
            event: event,
            overrides: _buildOverrides(
              currentUser: _testOwner,
              aquariums: [_testAquarium],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byType(FishCardSheet),
            matching: find.byIcon(Icons.delete_outline),
          ),
          findsOneWidget,
        );
        await tester.binding.setSurfaceSize(null);
      });
    });

    group('Action Buttons - Non-Owner', () {
      testWidgets('hides Edit Fish button for non-owner', (tester) async {
        final event = _createFeedingEvent(status: EventStatus.pending);

        await tester.pumpWidget(
          _buildSheetViaModal(
            event: event,
            overrides: _buildOverrides(
              currentUser: _testNonOwner,
              aquariums: [_testAquarium],
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.edit), findsNothing);
      });

      testWidgets('hides Delete Fish button for non-owner', (tester) async {
        final event = _createFeedingEvent(status: EventStatus.pending);

        await tester.pumpWidget(
          _buildSheetViaModal(
            event: event,
            overrides: _buildOverrides(
              currentUser: _testNonOwner,
              aquariums: [_testAquarium],
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.delete_outline), findsNothing);
      });

      testWidgets('shows Mark as Fed for non-owner pending event', (
        tester,
      ) async {
        final event = _createFeedingEvent(status: EventStatus.pending);

        await tester.pumpWidget(
          _buildSheetViaModal(
            event: event,
            overrides: _buildOverrides(
              currentUser: _testNonOwner,
              aquariums: [_testAquarium],
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        // Mark as Fed should still be visible for non-owners
        expect(find.byIcon(Icons.check), findsOneWidget);
      });
    });

    group('Feeding Schedule Section', () {
      testWidgets('shows schedule section with daily interval', (tester) async {
        final event = _createFeedingEvent(status: EventStatus.pending);
        final schedule = _createSchedule(time: '09:00', intervalDays: 1);
        final scheduleDs = _createScheduleDs(schedules: [schedule]);

        await tester.binding.setSurfaceSize(const Size(400, 1600));
        await tester.pumpWidget(
          _buildSheetDirect(
            event: event,
            overrides: _buildOverrides(
              currentUser: _testOwner,
              aquariums: [_testAquarium],
              scheduleDs: scheduleDs,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.repeat), findsOneWidget);
        expect(find.byIcon(Icons.access_time), findsOneWidget);
        await tester.binding.setSurfaceSize(null);
      });

      testWidgets('shows multiple time chips for multiple schedules', (
        tester,
      ) async {
        final event = _createFeedingEvent(status: EventStatus.pending);
        final schedule1 = _createSchedule(
          id: 's1',
          time: '08:00',
          intervalDays: 1,
        );
        final schedule2 = _createSchedule(
          id: 's2',
          time: '20:00',
          intervalDays: 1,
        );
        final scheduleDs = _createScheduleDs(schedules: [schedule1, schedule2]);

        await tester.binding.setSurfaceSize(const Size(400, 1600));
        await tester.pumpWidget(
          _buildSheetDirect(
            event: event,
            overrides: _buildOverrides(
              currentUser: _testOwner,
              aquariums: [_testAquarium],
              scheduleDs: scheduleDs,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Two time chips
        expect(find.byIcon(Icons.access_time), findsNWidgets(2));
        expect(find.text('08:00'), findsOneWidget);
        expect(find.text('20:00'), findsOneWidget);
        await tester.binding.setSurfaceSize(null);
      });

      testWidgets('hides schedule section when no active schedules', (
        tester,
      ) async {
        final event = _createFeedingEvent(status: EventStatus.pending);

        await tester.binding.setSurfaceSize(const Size(400, 1600));
        await tester.pumpWidget(
          _buildSheetDirect(
            event: event,
            overrides: _buildOverrides(
              currentUser: _testOwner,
              aquariums: [_testAquarium],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.repeat), findsNothing);
        await tester.binding.setSurfaceSize(null);
      });
    });

    group('showFishCardSheet', () {
      testWidgets('opens as modal bottom sheet', (tester) async {
        final event = _createFeedingEvent(fishName: 'Betta');

        await tester.pumpWidget(
          _buildSheetViaModal(
            event: event,
            overrides: _buildOverrides(
              currentUser: _testOwner,
              aquariums: [_testAquarium],
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        expect(find.byType(BottomSheet), findsOneWidget);
        expect(find.text('Betta'), findsOneWidget);
      });
    });

    group('DraggableScrollableSheet', () {
      testWidgets('renders inside DraggableScrollableSheet', (tester) async {
        final event = _createFeedingEvent();

        await tester.binding.setSurfaceSize(const Size(400, 1600));
        await tester.pumpWidget(
          _buildSheetDirect(
            event: event,
            overrides: _buildOverrides(
              currentUser: _testOwner,
              aquariums: [_testAquarium],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(DraggableScrollableSheet), findsOneWidget);
        await tester.binding.setSurfaceSize(null);
      });
    });
  });
}
