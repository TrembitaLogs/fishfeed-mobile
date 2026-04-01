import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/domain/entities/fish.dart';
import 'package:fishfeed/domain/repositories/fish_repository.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/fish_management_provider.dart';
import 'package:fishfeed/presentation/router/app_router.dart';
import 'package:fishfeed/presentation/widgets/profile/my_aquarium_section.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  late List<String> pushedRoutes;

  Widget buildTestWidget({required FishManagementState fishState}) {
    pushedRoutes = [];

    final router = GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(
          path: '/profile',
          builder: (context, state) => const Scaffold(
            body: SingleChildScrollView(child: MyAquariumSection()),
          ),
        ),
        GoRoute(
          path: '/aquarium',
          builder: (context, state) {
            pushedRoutes.add('/aquarium');
            return const Scaffold(body: Text('Aquarium Screen'));
          },
        ),
        GoRoute(
          path: AppRouter.aiCamera,
          builder: (context, state) {
            pushedRoutes.add(AppRouter.aiCamera);
            return const Scaffold(body: Text('AI Camera Screen'));
          },
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        fishManagementProvider.overrideWith(
          (ref) => _TestFishManagementNotifier(fishState),
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

  Fish createFish({
    String id = 'fish-1',
    String speciesId = 'guppy',
    String? name,
    int quantity = 1,
  }) {
    return Fish(
      id: id,
      aquariumId: 'default',
      speciesId: speciesId,
      name: name,
      quantity: quantity,
      addedAt: DateTime.now(),
    );
  }

  group('MyAquariumSection', () {
    group('Header', () {
      testWidgets('displays section title', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(fishState: const FishManagementState()),
        );
        await tester.pumpAndSettle();

        expect(find.text('My Aquarium'), findsOneWidget);
      });

      testWidgets('displays water drop icon', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(fishState: const FishManagementState()),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.water_drop_rounded), findsOneWidget);
      });

      testWidgets('displays fish count badge when has fish', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            fishState: FishManagementState(
              userFish: [
                createFish(),
                createFish(id: 'fish-2'),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('2'), findsOneWidget);
      });

      testWidgets('does not display count badge when empty', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(fishState: const FishManagementState()),
        );
        await tester.pumpAndSettle();

        // Only the section title should be present, no count
        expect(find.text('My Aquarium'), findsOneWidget);
        expect(find.text('0'), findsNothing);
      });
    });

    group('Empty State', () {
      testWidgets('shows empty state when no fish', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(fishState: const FishManagementState()),
        );
        await tester.pumpAndSettle();

        expect(find.text('No fish yet'), findsOneWidget);
        expect(find.byIcon(Icons.pets_outlined), findsOneWidget);
      });

      testWidgets('shows "Add your first fish" button', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(fishState: const FishManagementState()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Add your first fish'), findsOneWidget);
        // Button should be tappable
        expect(
          find.ancestor(
            of: find.text('Add your first fish'),
            matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
          ),
          findsOneWidget,
        );
      });

      testWidgets('"Add your first fish" navigates to AI Camera', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(fishState: const FishManagementState()),
        );
        await tester.pumpAndSettle();

        // Tap button to open modal
        await tester.tap(find.text('Add your first fish'));
        await tester.pumpAndSettle();

        // Select AI Camera option from modal
        await tester.tap(find.text('Scan with AI Camera'));
        await tester.pumpAndSettle();

        expect(pushedRoutes, contains(AppRouter.aiCamera));
      });
    });

    group('Fish Preview', () {
      testWidgets('displays single fish with species name', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            fishState: FishManagementState(
              userFish: [createFish(speciesId: 'guppy')],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Guppy'), findsOneWidget);
      });

      testWidgets('displays custom name over species name', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            fishState: FishManagementState(
              userFish: [createFish(speciesId: 'guppy', name: 'Nemo')],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Nemo'), findsOneWidget);
        expect(find.text('Guppy'), findsNothing);
      });

      testWidgets('displays fish quantity', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            fishState: FishManagementState(userFish: [createFish(quantity: 5)]),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('x5'), findsOneWidget);
      });

      testWidgets('displays up to 3 fish in preview', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            fishState: FishManagementState(
              userFish: [
                createFish(id: '1', speciesId: 'guppy'),
                createFish(id: '2', speciesId: 'neon_tetra'),
                createFish(id: '3', speciesId: 'betta'),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Guppy'), findsOneWidget);
        expect(find.text('Neon Tetra'), findsOneWidget);
        expect(find.text('Betta'), findsOneWidget);
      });

      testWidgets('shows "+X more" when more than 3 fish', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            fishState: FishManagementState(
              userFish: [
                createFish(id: '1', speciesId: 'guppy'),
                createFish(id: '2', speciesId: 'neon_tetra'),
                createFish(id: '3', speciesId: 'betta'),
                createFish(id: '4', speciesId: 'goldfish'),
                createFish(id: '5', speciesId: 'angelfish'),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('+2 more'), findsOneWidget);
        // Only first 3 fish shown
        expect(find.text('Guppy'), findsOneWidget);
        expect(find.text('Neon Tetra'), findsOneWidget);
        expect(find.text('Betta'), findsOneWidget);
        // Fish 4 and 5 not shown
        expect(find.text('Goldfish'), findsNothing);
        expect(find.text('Angelfish'), findsNothing);
      });

      testWidgets('does not show "+X more" when exactly 3 fish', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            fishState: FishManagementState(
              userFish: [
                createFish(id: '1', speciesId: 'guppy'),
                createFish(id: '2', speciesId: 'neon_tetra'),
                createFish(id: '3', speciesId: 'betta'),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('more'), findsNothing);
      });

      testWidgets('displays fish icon for each fish item', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            fishState: FishManagementState(userFish: [createFish()]),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.set_meal_rounded), findsOneWidget);
      });
    });

    group('Action Buttons', () {
      testWidgets('shows Manage and Add Fish buttons when has fish', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            fishState: FishManagementState(userFish: [createFish()]),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Manage'), findsOneWidget);
        expect(find.text('Add Fish'), findsOneWidget);
      });

      testWidgets('Manage button navigates to aquarium screen', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            fishState: FishManagementState(userFish: [createFish()]),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Manage'));
        await tester.pumpAndSettle();

        expect(pushedRoutes, contains('/aquarium'));
      });

      testWidgets('Add Fish button navigates to AI Camera', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            fishState: FishManagementState(userFish: [createFish()]),
          ),
        );
        await tester.pumpAndSettle();

        // Tap button to open modal
        await tester.tap(find.text('Add Fish'));
        await tester.pumpAndSettle();

        // Select AI Camera option from modal
        await tester.tap(find.text('Scan with AI Camera'));
        await tester.pumpAndSettle();

        expect(pushedRoutes, contains(AppRouter.aiCamera));
      });

      testWidgets('Manage button has edit icon', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            fishState: FishManagementState(userFish: [createFish()]),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      });

      testWidgets('Add Fish button has add icon', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            fishState: FishManagementState(userFish: [createFish()]),
          ),
        );
        await tester.pumpAndSettle();

        // One in Add Fish button (in fish preview), not counting empty state
        expect(find.byIcon(Icons.add), findsOneWidget);
      });
    });

    group('Loading State', () {
      testWidgets('shows shimmer when loading', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            fishState: const FishManagementState(isLoading: true),
          ),
        );
        await tester.pump();

        // Should not find content elements
        expect(find.text('No fish yet'), findsNothing);
        expect(find.text('Manage'), findsNothing);
      });

      testWidgets('does not show fish content when loading', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            fishState: const FishManagementState(isLoading: true),
          ),
        );
        await tester.pump();

        expect(find.byIcon(Icons.set_meal_rounded), findsNothing);
      });
    });

    group('Edge Cases', () {
      testWidgets('handles fish with unknown species', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            fishState: FishManagementState(
              userFish: [createFish(speciesId: 'unknown_species')],
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Should show default species name
        expect(find.text('Fish'), findsOneWidget);
      });

      testWidgets('handles large quantity numbers', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            fishState: FishManagementState(
              userFish: [createFish(quantity: 999)],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('x999'), findsOneWidget);
      });

      testWidgets('handles long fish names with ellipsis', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            fishState: FishManagementState(
              userFish: [
                createFish(
                  name: 'A Very Long Fish Name That Should Be Truncated',
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        // The widget should render without overflow errors
        expect(find.byType(MyAquariumSection), findsOneWidget);
      });
    });
  });
}

/// Test-only FishManagementNotifier that returns a fixed state.
class _TestFishManagementNotifier extends FishManagementNotifier {
  _TestFishManagementNotifier(this._initialState)
    : super(fishRepository: _MockFishRepository(), ref: _MockRef());

  final FishManagementState _initialState;

  @override
  FishManagementState get state => _initialState;

  @override
  set state(FishManagementState value) {
    // No-op for tests
  }

  @override
  Future<void> loadUserFish() async {
    // No-op for tests
  }
}

/// Minimal mock for FishRepository.
class _MockFishRepository extends Mock implements FishRepository {}

/// Minimal mock for Ref.
class _MockRef extends Mock implements Ref {}
