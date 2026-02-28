import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/data/datasources/local/aquarium_local_ds.dart';
import 'package:fishfeed/data/datasources/local/fish_local_ds.dart';
import 'package:fishfeed/data/datasources/local/local_datasources_providers.dart';
import 'package:fishfeed/data/models/aquarium_model.dart';
import 'package:fishfeed/domain/entities/aquarium.dart';
import 'package:fishfeed/domain/entities/fish.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/aquarium_providers.dart';
import 'package:fishfeed/presentation/providers/fish_management_provider.dart';
import 'package:fishfeed/presentation/screens/aquarium/aquarium_edit_screen.dart';
import 'package:fishfeed/presentation/widgets/common/app_cached_image.dart';
import 'package:fishfeed/presentation/widgets/common/image_picker_button.dart';
import 'package:fishfeed/services/sync/sync_service.dart';

import '../../../helpers/test_helpers.dart' show createMockSyncService;

// ============================================================================
// Mocks
// ============================================================================

class MockAquariumLocalDataSource extends Mock
    implements AquariumLocalDataSource {}

class MockFishLocalDataSource extends Mock implements FishLocalDataSource {}

class FakeAquariumModel extends Fake implements AquariumModel {}

void main() {
  late MockAquariumLocalDataSource mockAquariumDs;
  late MockFishLocalDataSource mockFishDs;

  final testAquarium = Aquarium(
    id: 'aq-1',
    userId: 'user-1',
    name: 'My Aquarium',
    createdAt: DateTime(2024, 1, 15),
  );

  final testAquariumWithPhoto = Aquarium(
    id: 'aq-1',
    userId: 'user-1',
    name: 'My Aquarium',
    photoKey: 'aquariums/aq-1/f7a3b2c1.webp',
    createdAt: DateTime(2024, 1, 15),
  );

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
    registerFallbackValue(FakeAquariumModel());
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  setUp(() {
    mockAquariumDs = MockAquariumLocalDataSource();
    mockFishDs = MockFishLocalDataSource();

    // Default: return empty fish list
    when(() => mockFishDs.getFishByAquariumId(any())).thenReturn([]);
  });

  Widget buildTestWidget({
    required Aquarium aquarium,
    List<Fish> fish = const [],
  }) {
    final mockSyncService = createMockSyncService();
    when(() => mockSyncService.syncNow()).thenAnswer((_) async => 0);

    final router = GoRouter(
      initialLocation: '/aquarium/${aquarium.id}/edit',
      routes: [
        GoRoute(
          path: '/aquarium/:id/edit',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return AquariumEditScreen(aquariumId: id);
          },
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        aquariumLocalDataSourceProvider.overrideWithValue(mockAquariumDs),
        fishLocalDataSourceProvider.overrideWithValue(mockFishDs),
        syncServiceProvider.overrideWithValue(mockSyncService),
        aquariumByIdProvider(aquarium.id).overrideWithValue(aquarium),
        fishByAquariumIdProvider(aquarium.id).overrideWithValue(fish),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  group('AquariumEditScreen', () {
    group('photo section', () {
      testWidgets('renders EntityImage for aquarium', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(aquarium: testAquariumWithPhoto),
        );
        await tester.pumpAndSettle();

        expect(find.byType(EntityImage), findsOneWidget);
      });

      testWidgets('renders ImagePickerButton', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(aquarium: testAquariumWithPhoto),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ImagePickerButton), findsOneWidget);
      });

      testWidgets('renders placeholder when photoKey is null', (tester) async {
        await tester.pumpWidget(buildTestWidget(aquarium: testAquarium));
        await tester.pumpAndSettle();

        // EntityImage should render with placeholder (water drop icon)
        expect(find.byType(EntityImage), findsOneWidget);
        expect(find.byIcon(Icons.water_drop_outlined), findsOneWidget);
      });

      testWidgets('shows remove button when photo exists', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(aquarium: testAquariumWithPhoto),
        );
        await tester.pumpAndSettle();

        expect(find.text('Remove'), findsOneWidget);
      });

      testWidgets('hides remove button when no photo', (tester) async {
        await tester.pumpWidget(buildTestWidget(aquarium: testAquarium));
        await tester.pumpAndSettle();

        expect(find.text('Remove'), findsNothing);
      });

      testWidgets('tapping remove shows confirmation dialog', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(aquarium: testAquariumWithPhoto),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Remove'));
        await tester.pumpAndSettle();

        // Dialog should appear with localized text
        expect(find.text('Remove this photo?'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
      });
    });

    group('basic UI', () {
      testWidgets('renders aquarium name field', (tester) async {
        await tester.pumpWidget(buildTestWidget(aquarium: testAquarium));
        await tester.pumpAndSettle();

        expect(find.text('My Aquarium'), findsOneWidget);
      });

      testWidgets('renders Edit Aquarium title', (tester) async {
        await tester.pumpWidget(buildTestWidget(aquarium: testAquarium));
        await tester.pumpAndSettle();

        expect(find.text('Edit Aquarium'), findsOneWidget);
      });
    });
  });
}
