import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/domain/entities/aquarium.dart';
import 'package:fishfeed/domain/entities/feeding_status.dart';
import 'package:fishfeed/domain/entities/scheduled_feeding.dart';
import 'package:fishfeed/domain/entities/water_type.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/aquarium_providers.dart';
import 'package:fishfeed/presentation/providers/feeding_providers.dart';
import 'package:fishfeed/presentation/providers/purchase_provider.dart';
import 'package:fishfeed/presentation/screens/home/today_view.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
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
      testWidgets('displays empty state when no feedings scheduled', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            state: const TodayFeedingsState(feedings: [], isLoading: false),
          ),
        );
        await tester.pumpAndSettle();

        // TodayView shows aquarium sections with empty state message
        // When no feedings, AquariumSection shows "No feedings scheduled"
        // Multiple aquariums = multiple empty state messages
        expect(find.text('No feedings scheduled'), findsAtLeastNWidgets(1));
        expect(
          find.byIcon(Icons.check_circle_outline),
          findsAtLeastNWidgets(1),
        );
      });
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

    group('Feedings List', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final mockFeedings = [
        ScheduledFeeding(
          id: '1',
          scheduledTime: today.add(const Duration(hours: 8)),
          aquariumId: 'aq1',
          aquariumName: 'Living Room Tank',
          speciesName: 'Guppy',
          status: FeedingStatus.fed,
          foodType: 'Flakes',
          portionGrams: 0.5,
        ),
        ScheduledFeeding(
          id: '2',
          scheduledTime: today.add(const Duration(hours: 14)),
          aquariumId: 'aq1',
          aquariumName: 'Living Room Tank',
          speciesName: 'Betta',
          status: FeedingStatus.pending,
          foodType: 'Pellets',
          portionGrams: 0.3,
        ),
        ScheduledFeeding(
          id: '3',
          scheduledTime: today.add(const Duration(hours: 19)),
          aquariumId: 'aq2',
          aquariumName: 'Bedroom Aquarium',
          speciesName: 'Goldfish',
          status: FeedingStatus.missed,
          foodType: 'Flakes',
          portionGrams: 1.0,
        ),
      ];

      testWidgets('displays feeding cards for each scheduled feeding', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            state: TodayFeedingsState(feedings: mockFeedings, isLoading: false),
          ),
        );
        await tester.pumpAndSettle();

        // Should show all feeding names
        expect(find.text('Guppy'), findsOneWidget);
        expect(find.text('Betta'), findsOneWidget);
        expect(find.text('Goldfish'), findsOneWidget);
      });

      testWidgets('displays aquarium names in section headers and cards', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            state: TodayFeedingsState(feedings: mockFeedings, isLoading: false),
          ),
        );
        await tester.pumpAndSettle();

        // Aquarium names appear in:
        // 1. Section headers (one per aquarium)
        // 2. FeedingCard subtitle (one per feeding)
        // Living Room Tank: 1 header + 2 feedings = 3 total
        expect(find.text('Living Room Tank'), findsNWidgets(3));
        // Bedroom Aquarium: 1 header + 1 feeding = 2 total
        expect(find.text('Bedroom Aquarium'), findsNWidgets(2));
      });

      testWidgets('displays food types', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            state: TodayFeedingsState(feedings: mockFeedings, isLoading: false),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Flakes'), findsNWidgets(2));
        expect(find.text('Pellets'), findsOneWidget);
      });

      testWidgets('displays time for each feeding', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            state: TodayFeedingsState(feedings: mockFeedings, isLoading: false),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('08:00'), findsOneWidget);
        expect(find.text('14:00'), findsOneWidget);
        expect(find.text('19:00'), findsOneWidget);
      });

      testWidgets('displays status icons for different statuses', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            state: TodayFeedingsState(feedings: mockFeedings, isLoading: false),
          ),
        );
        await tester.pumpAndSettle();

        // Fed status (StatusIndicator uses Icons.check)
        expect(find.byIcon(Icons.check), findsOneWidget);
        // Pending status
        expect(find.byIcon(Icons.schedule), findsAtLeastNWidgets(1));
        // Missed status (StatusIndicator uses Icons.close)
        expect(find.byIcon(Icons.close), findsOneWidget);
      });
    });

    group('Aquarium Grouping', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      testWidgets('displays aquarium section headers for each aquarium', (
        tester,
      ) async {
        final feedings = [
          ScheduledFeeding(
            id: '1',
            scheduledTime: today.add(const Duration(hours: 8)),
            aquariumId: 'aq1',
            aquariumName: 'Living Room Tank',
            speciesName: 'Guppy',
            status: FeedingStatus.pending,
          ),
        ];

        await tester.pumpWidget(
          buildTestWidget(
            state: TodayFeedingsState(feedings: feedings, isLoading: false),
          ),
        );
        await tester.pumpAndSettle();

        // Living Room Tank appears in header (1) + FeedingCard subtitle (1) = 2
        expect(find.text('Living Room Tank'), findsNWidgets(2));
        // Should show water drop icon in headers (2 aquariums)
        expect(find.byIcon(Icons.water_drop_outlined), findsNWidgets(2));
      });

      testWidgets('displays multiple aquarium sections', (tester) async {
        final multiAquariumFeedings = [
          ScheduledFeeding(
            id: '1',
            scheduledTime: today.add(const Duration(hours: 8)),
            aquariumId: 'aq1',
            aquariumName: 'Living Room Tank',
            speciesName: 'Guppy',
            status: FeedingStatus.pending,
          ),
          ScheduledFeeding(
            id: '2',
            scheduledTime: today.add(const Duration(hours: 14)),
            aquariumId: 'aq2',
            aquariumName: 'Bedroom Aquarium',
            speciesName: 'Betta',
            status: FeedingStatus.pending,
          ),
        ];

        await tester.pumpWidget(
          buildTestWidget(
            state: TodayFeedingsState(
              feedings: multiAquariumFeedings,
              isLoading: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Each aquarium name appears in header (1) + FeedingCard subtitle (1) = 2
        expect(find.text('Living Room Tank'), findsNWidgets(2));
        expect(find.text('Bedroom Aquarium'), findsNWidgets(2));
      });

      testWidgets('displays add aquarium button at the bottom', (tester) async {
        final feedings = [
          ScheduledFeeding(
            id: '1',
            scheduledTime: today.add(const Duration(hours: 8)),
            aquariumId: 'aq1',
            aquariumName: 'Living Room Tank',
            speciesName: 'Guppy',
            status: FeedingStatus.pending,
          ),
        ];

        await tester.pumpWidget(
          buildTestWidget(
            state: TodayFeedingsState(feedings: feedings, isLoading: false),
          ),
        );
        await tester.pumpAndSettle();

        // Should show "Add Another Aquarium" button
        expect(find.text('Add Another Aquarium'), findsOneWidget);
      });

      testWidgets('shows empty state message for aquarium with no feedings', (
        tester,
      ) async {
        // Empty feedings list but aquariums exist
        await tester.pumpWidget(
          buildTestWidget(
            state: const TodayFeedingsState(feedings: [], isLoading: false),
          ),
        );
        await tester.pumpAndSettle();

        // Empty state is shown when no feedings - AquariumSection shows this message
        // Multiple aquariums = multiple empty state messages
        expect(find.text('No feedings scheduled'), findsAtLeastNWidgets(1));
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

    group('Feeding Card Interaction', () {
      testWidgets('feeding card is tappable', (tester) async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final pendingFeeding = [
          ScheduledFeeding(
            id: '1',
            scheduledTime: today.add(const Duration(hours: 19)),
            aquariumId: 'aq1',
            aquariumName: 'Tank',
            speciesName: 'Guppy',
            status: FeedingStatus.pending,
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

        // Find the card with InkWell
        final cardFinder = find.ancestor(
          of: find.text('Guppy'),
          matching: find.byType(InkWell),
        );
        expect(cardFinder, findsOneWidget);

        // Tap should not crash
        await tester.tap(cardFinder.first);
        await tester.pumpAndSettle();
      });
    });
  });

  group('ScheduledFeeding Entity', () {
    group('timePeriod', () {
      test('returns morning for hours before 12', () {
        final feeding = ScheduledFeeding(
          id: '1',
          scheduledTime: DateTime(2024, 1, 15, 8, 0),
          aquariumId: 'aq1',
          aquariumName: 'Tank',
          status: FeedingStatus.pending,
        );

        expect(feeding.timePeriod, equals('morning'));
      });

      test('returns afternoon for hours 12-17', () {
        final feeding = ScheduledFeeding(
          id: '1',
          scheduledTime: DateTime(2024, 1, 15, 14, 0),
          aquariumId: 'aq1',
          aquariumName: 'Tank',
          status: FeedingStatus.pending,
        );

        expect(feeding.timePeriod, equals('afternoon'));
      });

      test('returns evening for hours 18 and later', () {
        final feeding = ScheduledFeeding(
          id: '1',
          scheduledTime: DateTime(2024, 1, 15, 19, 0),
          aquariumId: 'aq1',
          aquariumName: 'Tank',
          status: FeedingStatus.pending,
        );

        expect(feeding.timePeriod, equals('evening'));
      });

      test('boundary: 11:59 is morning', () {
        final feeding = ScheduledFeeding(
          id: '1',
          scheduledTime: DateTime(2024, 1, 15, 11, 59),
          aquariumId: 'aq1',
          aquariumName: 'Tank',
          status: FeedingStatus.pending,
        );

        expect(feeding.timePeriod, equals('morning'));
      });

      test('boundary: 12:00 is afternoon', () {
        final feeding = ScheduledFeeding(
          id: '1',
          scheduledTime: DateTime(2024, 1, 15, 12, 0),
          aquariumId: 'aq1',
          aquariumName: 'Tank',
          status: FeedingStatus.pending,
        );

        expect(feeding.timePeriod, equals('afternoon'));
      });

      test('boundary: 17:59 is afternoon', () {
        final feeding = ScheduledFeeding(
          id: '1',
          scheduledTime: DateTime(2024, 1, 15, 17, 59),
          aquariumId: 'aq1',
          aquariumName: 'Tank',
          status: FeedingStatus.pending,
        );

        expect(feeding.timePeriod, equals('afternoon'));
      });

      test('boundary: 18:00 is evening', () {
        final feeding = ScheduledFeeding(
          id: '1',
          scheduledTime: DateTime(2024, 1, 15, 18, 0),
          aquariumId: 'aq1',
          aquariumName: 'Tank',
          status: FeedingStatus.pending,
        );

        expect(feeding.timePeriod, equals('evening'));
      });
    });

    group('displayName', () {
      test('returns fishName when available', () {
        final feeding = ScheduledFeeding(
          id: '1',
          scheduledTime: DateTime(2024, 1, 15, 8, 0),
          aquariumId: 'aq1',
          aquariumName: 'Tank',
          fishName: 'Nemo',
          speciesName: 'Clownfish',
          status: FeedingStatus.pending,
        );

        expect(feeding.displayName, equals('Nemo'));
      });

      test('returns speciesName when fishName is empty', () {
        final feeding = ScheduledFeeding(
          id: '1',
          scheduledTime: DateTime(2024, 1, 15, 8, 0),
          aquariumId: 'aq1',
          aquariumName: 'Tank',
          fishName: '',
          speciesName: 'Clownfish',
          status: FeedingStatus.pending,
        );

        expect(feeding.displayName, equals('Clownfish'));
      });

      test('returns speciesName when fishName is null', () {
        final feeding = ScheduledFeeding(
          id: '1',
          scheduledTime: DateTime(2024, 1, 15, 8, 0),
          aquariumId: 'aq1',
          aquariumName: 'Tank',
          speciesName: 'Clownfish',
          status: FeedingStatus.pending,
        );

        expect(feeding.displayName, equals('Clownfish'));
      });

      test('returns aquariumName when fishName and speciesName are null', () {
        final feeding = ScheduledFeeding(
          id: '1',
          scheduledTime: DateTime(2024, 1, 15, 8, 0),
          aquariumId: 'aq1',
          aquariumName: 'Living Room Tank',
          status: FeedingStatus.pending,
        );

        expect(feeding.displayName, equals('Living Room Tank'));
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
  Future<void> markAsFed(String feedingId) async {
    final updatedFeedings = state.feedings.map((f) {
      if (f.id == feedingId) {
        return f.copyWith(
          status: FeedingStatus.fed,
          completedAt: DateTime.now(),
        );
      }
      return f;
    }).toList();
    state = state.copyWith(feedings: updatedFeedings);
  }

  @override
  Future<void> markAsMissed(String feedingId) async {
    final updatedFeedings = state.feedings.map((f) {
      if (f.id == feedingId) {
        return f.copyWith(status: FeedingStatus.missed);
      }
      return f;
    }).toList();
    state = state.copyWith(feedings: updatedFeedings);
  }

  @override
  void updateFeedingStatus(String feedingId, FeedingStatus newStatus) {
    final updatedFeedings = state.feedings.map((f) {
      if (f.id == feedingId) {
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
    String? imageUrl,
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
