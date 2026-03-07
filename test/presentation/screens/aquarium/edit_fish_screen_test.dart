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
import 'package:fishfeed/data/models/fish_model.dart';
import 'package:fishfeed/domain/entities/aquarium.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/aquarium_providers.dart';
import 'package:fishfeed/presentation/screens/aquarium/edit_fish_screen.dart';
import 'package:fishfeed/presentation/widgets/common/app_cached_image.dart';
import 'package:fishfeed/presentation/widgets/common/image_picker_button.dart';

// ============================================================================
// Mocks
// ============================================================================

class MockFishLocalDataSource extends Mock implements FishLocalDataSource {}

class MockSpeciesLocalDataSource extends Mock
    implements SpeciesLocalDataSource {}

class MockSpeciesRemoteDataSource extends Mock
    implements SpeciesRemoteDataSource {}

class MockScheduleLocalDataSource extends Mock
    implements ScheduleLocalDataSource {}

class FakeFishModel extends Fake implements FishModel {}

void main() {
  late MockFishLocalDataSource mockFishDs;
  late MockSpeciesLocalDataSource mockSpeciesLocalDs;
  late MockSpeciesRemoteDataSource mockSpeciesRemoteDs;
  late MockScheduleLocalDataSource mockScheduleDs;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
    registerFallbackValue(FakeFishModel());
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  setUp(() {
    mockFishDs = MockFishLocalDataSource();
    mockSpeciesLocalDs = MockSpeciesLocalDataSource();
    mockSpeciesRemoteDs = MockSpeciesRemoteDataSource();
    mockScheduleDs = MockScheduleLocalDataSource();
    when(() => mockSpeciesLocalDs.getAllSpecies()).thenReturn([]);
    when(
      () => mockScheduleDs.getByFishId(
        any(),
        activeOnly: any(named: 'activeOnly'),
      ),
    ).thenReturn([]);
  });

  Widget buildTestWidget({
    required String fishId,
    List<Override> additionalOverrides = const [],
  }) {
    final router = GoRouter(
      initialLocation: '/aquarium/fish/$fishId/edit',
      routes: [
        GoRoute(
          path: '/aquarium',
          builder: (context, state) => const Scaffold(body: Text('Aquarium')),
          routes: [
            GoRoute(
              path: 'fish/:fishId/edit',
              builder: (context, state) {
                final id = state.pathParameters['fishId']!;
                return EditFishScreen(fishId: id);
              },
            ),
          ],
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        fishLocalDataSourceProvider.overrideWithValue(mockFishDs),
        speciesLocalDataSourceProvider.overrideWithValue(mockSpeciesLocalDs),
        speciesRemoteDataSourceProvider.overrideWithValue(mockSpeciesRemoteDs),
        scheduleLocalDataSourceProvider.overrideWithValue(mockScheduleDs),
        aquariumsListProvider.overrideWithValue(const <Aquarium>[]),
        ...additionalOverrides,
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  group('EditFishScreen', () {
    group('form initialization', () {
      testWidgets('displays fish data with custom name', (tester) async {
        final fishModel = _createFishModel('1', 'guppy', 5, name: 'My Guppy');

        when(() => mockFishDs.getFishById(any())).thenReturn(fishModel);

        await tester.pumpWidget(buildTestWidget(fishId: '1'));
        await tester.pumpAndSettle();

        // Check custom name is displayed as title
        expect(find.text('My Guppy'), findsOneWidget);

        // Check species name is displayed as subtitle
        expect(find.text('Guppy'), findsOneWidget);

        // Check quantity is displayed
        expect(find.text('5'), findsOneWidget);
      });

      testWidgets('displays species name when fish has no custom name', (
        tester,
      ) async {
        final fishModel = _createFishModel('1', 'betta', 3);

        when(() => mockFishDs.getFishById(any())).thenReturn(fishModel);

        await tester.pumpWidget(buildTestWidget(fishId: '1'));
        await tester.pumpAndSettle();

        // Check species name is displayed as title (no custom name)
        expect(find.text('Betta'), findsOneWidget);

        // Check quantity is displayed
        expect(find.text('3'), findsOneWidget);
      });
    });

    group('quantity counter', () {
      testWidgets('increment button increases quantity', (tester) async {
        final fishModel = _createFishModel('1', 'guppy', 5);

        when(() => mockFishDs.getFishById(any())).thenReturn(fishModel);

        await tester.pumpWidget(buildTestWidget(fishId: '1'));
        await tester.pumpAndSettle();

        expect(find.text('5'), findsOneWidget);

        // Tap increment (first add icon is in quantity section)
        await tester.tap(find.byIcon(Icons.add).first);
        await tester.pumpAndSettle();

        expect(find.text('6'), findsOneWidget);
      });

      testWidgets('decrement button decreases quantity', (tester) async {
        final fishModel = _createFishModel('1', 'guppy', 5);

        when(() => mockFishDs.getFishById(any())).thenReturn(fishModel);

        await tester.pumpWidget(buildTestWidget(fishId: '1'));
        await tester.pumpAndSettle();

        expect(find.text('5'), findsOneWidget);

        // Tap decrement (first remove icon is in quantity section)
        await tester.tap(find.byIcon(Icons.remove).first);
        await tester.pumpAndSettle();

        expect(find.text('4'), findsOneWidget);
      });

      testWidgets('quantity cannot go below 1', (tester) async {
        final fishModel = _createFishModel('1', 'guppy', 1);

        when(() => mockFishDs.getFishById(any())).thenReturn(fishModel);

        await tester.pumpWidget(buildTestWidget(fishId: '1'));
        await tester.pumpAndSettle();

        expect(find.text('1'), findsOneWidget);

        // Try to decrement when at minimum (first remove icon is in quantity section)
        await tester.tap(find.byIcon(Icons.remove).first);
        await tester.pumpAndSettle();

        // Should still be 1
        expect(find.text('1'), findsOneWidget);
      });

      testWidgets('quantity cannot exceed 999', (tester) async {
        final fishModel = _createFishModel('1', 'guppy', 999);

        when(() => mockFishDs.getFishById(any())).thenReturn(fishModel);

        await tester.pumpWidget(buildTestWidget(fishId: '1'));
        await tester.pumpAndSettle();

        expect(find.text('999'), findsOneWidget);

        // Try to increment when at maximum (first add icon is in quantity section)
        await tester.tap(find.byIcon(Icons.add).first);
        await tester.pumpAndSettle();

        // Should still be 999
        expect(find.text('999'), findsOneWidget);
      });
    });

    group('save action', () {
      testWidgets('Save button saves quantity change and navigates back', (
        tester,
      ) async {
        final fishModel = _createFishModel('1', 'guppy', 5);

        when(() => mockFishDs.getFishById(any())).thenReturn(fishModel);
        when(() => mockFishDs.updateFish(any())).thenAnswer((_) async => true);

        await tester.pumpWidget(buildTestWidget(fishId: '1'));
        await tester.pumpAndSettle();

        // Change quantity (first add icon is in quantity section)
        await tester.tap(find.byIcon(Icons.add).first);
        await tester.pumpAndSettle();

        // Tap Save
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        // Verify update was called with new quantity
        final captured = verify(
          () => mockFishDs.updateFish(captureAny()),
        ).captured;
        final updatedModel = captured.first as FishModel;
        expect(updatedModel.quantity, equals(6));
      });

      testWidgets('Save preserves original custom name', (tester) async {
        final fishModel = _createFishModel('1', 'guppy', 5, name: 'My Fish');

        when(() => mockFishDs.getFishById(any())).thenReturn(fishModel);
        when(() => mockFishDs.updateFish(any())).thenAnswer((_) async => true);

        await tester.pumpWidget(buildTestWidget(fishId: '1'));
        await tester.pumpAndSettle();

        // Change quantity (first add icon is in quantity section)
        await tester.tap(find.byIcon(Icons.add).first);
        await tester.pumpAndSettle();

        // Tap Save
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        // Verify name was preserved
        final captured = verify(
          () => mockFishDs.updateFish(captureAny()),
        ).captured;
        final updatedModel = captured.first as FishModel;
        expect(updatedModel.name, equals('My Fish'));
      });

      testWidgets('shows loading indicator while saving', (tester) async {
        final fishModel = _createFishModel('1', 'guppy', 5);

        when(() => mockFishDs.getFishById(any())).thenReturn(fishModel);
        when(() => mockFishDs.updateFish(any())).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(seconds: 1));
          return true;
        });

        await tester.pumpWidget(buildTestWidget(fishId: '1'));
        await tester.pumpAndSettle();

        // Tap Save
        await tester.tap(find.text('Save'));
        await tester.pump();

        // Should show loading indicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Complete the save
        await tester.pumpAndSettle();
      });
    });

    group('cancel action', () {
      testWidgets('Cancel button navigates back without saving', (
        tester,
      ) async {
        final fishModel = _createFishModel('1', 'guppy', 5);

        when(() => mockFishDs.getFishById(any())).thenReturn(fishModel);

        await tester.pumpWidget(buildTestWidget(fishId: '1'));
        await tester.pumpAndSettle();

        // Change quantity (first add icon is in quantity section)
        await tester.tap(find.byIcon(Icons.add).first);
        await tester.pumpAndSettle();

        expect(find.text('6'), findsOneWidget);

        // Tap Cancel
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Verify update was NOT called
        verifyNever(() => mockFishDs.updateFish(any()));
      });
    });

    group('fish not found', () {
      testWidgets('shows not found state when fish does not exist', (
        tester,
      ) async {
        when(() => mockFishDs.getFishById(any())).thenReturn(null);

        await tester.pumpWidget(buildTestWidget(fishId: 'nonexistent'));
        await tester.pumpAndSettle();

        expect(find.text('Fish not found'), findsOneWidget);
        expect(
          find.text('The fish you are trying to edit no longer exists.'),
          findsOneWidget,
        );
        expect(find.text('Go back'), findsOneWidget);
      });

      testWidgets('Go back button navigates back', (tester) async {
        when(() => mockFishDs.getFishById(any())).thenReturn(null);

        await tester.pumpWidget(buildTestWidget(fishId: 'nonexistent'));
        await tester.pumpAndSettle();

        // Tap Go back
        await tester.tap(find.text('Go back'));
        await tester.pumpAndSettle();

        // Should navigate away from edit screen
        expect(find.byType(EditFishScreen), findsNothing);
      });
    });

    group('AppBar', () {
      testWidgets('has correct title', (tester) async {
        final fishModel = _createFishModel('1', 'guppy', 5);

        when(() => mockFishDs.getFishById(any())).thenReturn(fishModel);

        await tester.pumpWidget(buildTestWidget(fishId: '1'));
        await tester.pumpAndSettle();

        expect(find.text('Edit Fish'), findsOneWidget);
      });
    });

    group('UI elements', () {
      testWidgets('displays Quantity label', (tester) async {
        final fishModel = _createFishModel('1', 'guppy', 5);

        when(() => mockFishDs.getFishById(any())).thenReturn(fishModel);

        await tester.pumpWidget(buildTestWidget(fishId: '1'));
        await tester.pumpAndSettle();

        expect(find.text('Quantity'), findsOneWidget);
      });

      testWidgets('displays fish icon', (tester) async {
        final fishModel = _createFishModel('1', 'guppy', 5);

        when(() => mockFishDs.getFishById(any())).thenReturn(fishModel);

        await tester.pumpWidget(buildTestWidget(fishId: '1'));
        await tester.pumpAndSettle();

        // One fish icon as photo placeholder
        expect(find.byIcon(Icons.set_meal_rounded), findsOneWidget);
      });
    });

    group('photo section', () {
      testWidgets('renders EntityImage with fish entityType', (tester) async {
        final fishModel = _createFishModel('1', 'guppy', 5);

        when(() => mockFishDs.getFishById(any())).thenReturn(fishModel);

        await tester.pumpWidget(buildTestWidget(fishId: '1'));
        await tester.pumpAndSettle();

        expect(find.byType(EntityImage), findsOneWidget);
      });

      testWidgets('renders ImagePickerButton for fish', (tester) async {
        final fishModel = _createFishModel('1', 'guppy', 5);

        when(() => mockFishDs.getFishById(any())).thenReturn(fishModel);

        await tester.pumpWidget(buildTestWidget(fishId: '1'));
        await tester.pumpAndSettle();

        expect(find.byType(ImagePickerButton), findsOneWidget);
      });

      testWidgets('shows Choose Photo label', (tester) async {
        final fishModel = _createFishModel('1', 'guppy', 5);

        when(() => mockFishDs.getFishById(any())).thenReturn(fishModel);

        await tester.pumpWidget(buildTestWidget(fishId: '1'));
        await tester.pumpAndSettle();

        expect(find.text('Choose Photo'), findsOneWidget);
      });

      testWidgets('hides remove button when no photo', (tester) async {
        final fishModel = _createFishModel('1', 'guppy', 5);

        when(() => mockFishDs.getFishById(any())).thenReturn(fishModel);

        await tester.pumpWidget(buildTestWidget(fishId: '1'));
        await tester.pumpAndSettle();

        expect(find.text('Remove'), findsNothing);
      });

      testWidgets('shows remove button when fish has photo', (tester) async {
        final fishModel = _createFishModel(
          '1',
          'guppy',
          5,
          photoKey: 'fish/1/abc123.webp',
        );

        when(() => mockFishDs.getFishById(any())).thenReturn(fishModel);

        await tester.pumpWidget(buildTestWidget(fishId: '1'));
        await tester.pumpAndSettle();

        expect(find.text('Remove'), findsOneWidget);
      });
    });
  });
}

/// Helper to create a FishModel for testing.
FishModel _createFishModel(
  String id,
  String speciesId,
  int quantity, {
  String? name,
  String? photoKey,
}) {
  return FishModel(
    id: id,
    aquariumId: 'default',
    speciesId: speciesId,
    name: name,
    quantity: quantity,
    photoKey: photoKey,
    addedAt: DateTime(2024, 1, 15),
  );
}
