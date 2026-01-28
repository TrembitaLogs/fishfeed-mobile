import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/domain/entities/fish.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/fish_management_provider.dart';
import 'package:fishfeed/presentation/screens/aquarium/my_aquarium_screen.dart';

// ============================================================================
// Mocks
// ============================================================================

/// Mock FishManagementNotifier for testing
class MockFishManagementNotifier extends StateNotifier<FishManagementState>
    implements FishManagementNotifier {
  MockFishManagementNotifier({
    List<Fish>? fish,
    bool isEmpty = false,
    bool hasError = false,
    String? error,
  }) : super(
         FishManagementState(
           userFish: fish ?? (isEmpty ? [] : _defaultTestFish),
           isLoading: false,
           error: hasError ? (error ?? 'Something went wrong') : null,
         ),
       );

  static final _defaultTestFish = [
    Fish(
      id: 'test-fish-1',
      aquariumId: 'test-aquarium',
      speciesId: 'guppy',
      name: 'My Guppy',
      quantity: 3,
      addedAt: DateTime(2024, 1, 15),
    ),
  ];

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
  Future<bool> deleteFish(String fishId) async {
    state = state.copyWith(
      userFish: state.userFish.where((f) => f.id != fishId).toList(),
    );
    return true;
  }

  @override
  Fish? getFishById(String id) {
    try {
      return state.userFish.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  Future<void> refresh() async {}
}

Fish _createFish(String id, String speciesId, int quantity, {String? name}) {
  return Fish(
    id: id,
    aquariumId: 'test-aquarium',
    speciesId: speciesId,
    name: name,
    quantity: quantity,
    addedAt: DateTime(2024, 1, 15),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  Widget buildTestWidget({
    List<Fish>? fish,
    bool isEmpty = false,
    bool hasError = false,
    String? error,
  }) {
    final router = GoRouter(
      initialLocation: '/aquarium',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/aquarium',
          builder: (context, state) => const MyAquariumScreen(),
        ),
        GoRoute(
          path: '/ai-camera',
          builder: (context, state) => const Scaffold(body: Text('AI Camera')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        fishManagementProvider.overrideWith(
          (ref) => MockFishManagementNotifier(
            fish: fish,
            isEmpty: isEmpty,
            hasError: hasError,
            error: error,
          ),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  group('MyAquariumScreen', () {
    group('loading state', () {
      testWidgets('renders without errors during initial load', (tester) async {
        await tester.pumpWidget(buildTestWidget(isEmpty: true));
        await tester.pumpAndSettle();

        expect(find.byType(MyAquariumScreen), findsOneWidget);
      });
    });

    group('empty state', () {
      testWidgets('shows empty state when no fish', (tester) async {
        await tester.pumpWidget(buildTestWidget(isEmpty: true));
        await tester.pumpAndSettle();

        expect(find.text('No fish yet'), findsOneWidget);
        expect(find.text('Add your first fish'), findsOneWidget);
        expect(find.byIcon(Icons.pets_outlined), findsOneWidget);
      });

      testWidgets('empty state CTA shows bottom sheet', (tester) async {
        await tester.pumpWidget(buildTestWidget(isEmpty: true));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Add your first fish'));
        await tester.pumpAndSettle();

        // Should show bottom sheet with options
        expect(find.text('Scan with AI Camera'), findsOneWidget);
      });
    });

    group('fish list', () {
      testWidgets('displays fish list correctly', (tester) async {
        final fishList = [
          _createFish('1', 'guppy', 5),
          _createFish('2', 'betta', 1, name: 'My Betta'),
        ];

        await tester.pumpWidget(buildTestWidget(fish: fishList));
        await tester.pumpAndSettle();

        expect(find.text('Guppy'), findsOneWidget);
        expect(find.text('My Betta'), findsOneWidget);
        expect(find.text('x5'), findsOneWidget);
        expect(find.text('x1'), findsOneWidget);
      });

      testWidgets('displays fish icon for each item', (tester) async {
        final fishList = [_createFish('1', 'guppy', 5)];

        await tester.pumpWidget(buildTestWidget(fish: fishList));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.set_meal_rounded), findsOneWidget);
      });
    });

    group('FAB', () {
      testWidgets('FAB is present', (tester) async {
        await tester.pumpWidget(buildTestWidget(isEmpty: true));
        await tester.pumpAndSettle();

        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.byIcon(Icons.add), findsAtLeastNWidgets(1));
      });

      testWidgets('FAB shows bottom sheet with options', (tester) async {
        final fishList = [_createFish('1', 'guppy', 5)];

        await tester.pumpWidget(buildTestWidget(fish: fishList));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        expect(find.text('Scan with AI Camera'), findsOneWidget);
        expect(find.text('Select from list'), findsOneWidget);
      });
    });

    group('popup menu', () {
      testWidgets('shows popup menu button for each fish', (tester) async {
        final fishList = [_createFish('1', 'guppy', 5)];

        await tester.pumpWidget(buildTestWidget(fish: fishList));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.more_vert), findsOneWidget);
      });

      testWidgets('popup menu shows Edit and Delete options', (tester) async {
        final fishList = [_createFish('1', 'guppy', 5)];

        await tester.pumpWidget(buildTestWidget(fish: fishList));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        expect(find.text('Edit'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);
      });

      testWidgets('tapping Delete shows confirmation dialog', (tester) async {
        final fishList = [_createFish('1', 'guppy', 5)];

        await tester.pumpWidget(buildTestWidget(fish: fishList));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Delete Guppy?'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
      });

      testWidgets('confirmation dialog Cancel dismisses dialog', (
        tester,
      ) async {
        final fishList = [_createFish('1', 'guppy', 5)];

        await tester.pumpWidget(buildTestWidget(fish: fishList));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(find.text('Guppy'), findsOneWidget);
      });

      testWidgets('confirmation dialog Delete removes fish', (tester) async {
        final fishList = [_createFish('1', 'guppy', 5)];

        await tester.pumpWidget(buildTestWidget(fish: fishList));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(TextButton, 'Delete'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
      });

      testWidgets('shows SnackBar after successful deletion', (tester) async {
        final fishList = [_createFish('1', 'guppy', 5)];

        await tester.pumpWidget(buildTestWidget(fish: fishList));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(TextButton, 'Delete'));
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text('Fish deleted'), findsOneWidget);
      });
    });

    group('error state', () {
      testWidgets('shows error state on load failure', (tester) async {
        await tester.pumpWidget(buildTestWidget(hasError: true));
        await tester.pumpAndSettle();

        // Title and message may both show "Something went wrong"
        expect(find.text('Something went wrong'), findsAtLeastNWidgets(1));
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
      });

      testWidgets('retry button is tappable', (tester) async {
        await tester.pumpWidget(buildTestWidget(hasError: true));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Retry'));
        await tester.pump();

        // Just verify it doesn't crash
        expect(find.byType(MyAquariumScreen), findsOneWidget);
      });
    });

    group('pull to refresh', () {
      testWidgets('can pull to refresh fish list', (tester) async {
        final fishList = [_createFish('1', 'guppy', 5)];

        await tester.pumpWidget(buildTestWidget(fish: fishList));
        await tester.pumpAndSettle();

        // Find the list and perform pull to refresh
        await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
        await tester.pumpAndSettle();

        // Verify screen still works
        expect(find.byType(MyAquariumScreen), findsOneWidget);
      });
    });
  });
}
