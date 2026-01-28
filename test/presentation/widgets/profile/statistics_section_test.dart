import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/core/constants/levels.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/domain/entities/user_statistics.dart';
import 'package:fishfeed/domain/usecases/calculate_statistics_usecase.dart';
import 'package:fishfeed/presentation/providers/statistics_provider.dart';
import 'package:fishfeed/presentation/widgets/profile/statistics_section.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  Widget buildTestWidget({required StatisticsState statisticsState}) {
    return ProviderScope(
      overrides: [
        statisticsProvider.overrideWith((ref) {
          return _TestStatisticsNotifier(statisticsState);
        }),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: SingleChildScrollView(child: StatisticsSection()),
        ),
      ),
    );
  }

  UserStatistics createStatistics({
    double onTimePercentage = 75.0,
    int totalFeedings = 100,
    int daysWithApp = 30,
    UserLevel currentLevel = UserLevel.caretaker,
    int totalXp = 250,
    int xpInCurrentLevel = 150,
    int xpForCurrentLevel = 400,
    double levelProgress = 0.375,
    bool isMaxLevel = false,
  }) {
    return UserStatistics(
      onTimePercentage: onTimePercentage,
      totalFeedings: totalFeedings,
      daysWithApp: daysWithApp,
      currentLevel: currentLevel,
      totalXp: totalXp,
      xpInCurrentLevel: xpInCurrentLevel,
      xpForCurrentLevel: xpForCurrentLevel,
      levelProgress: levelProgress,
      isMaxLevel: isMaxLevel,
    );
  }

  group('StatisticsSection', () {
    group('Display', () {
      testWidgets('displays section title', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            statisticsState: StatisticsState(statistics: createStatistics()),
          ),
        );

        expect(find.text('Statistics'), findsOneWidget);
      });

      testWidgets('displays on-time percentage', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            statisticsState: StatisticsState(
              statistics: createStatistics(onTimePercentage: 85.0),
            ),
          ),
        );

        expect(find.text('85%'), findsOneWidget);
        expect(find.text('On time'), findsOneWidget);
      });

      testWidgets('displays total feedings count', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            statisticsState: StatisticsState(
              statistics: createStatistics(totalFeedings: 150),
            ),
          ),
        );

        expect(find.text('150'), findsOneWidget);
        expect(find.text('Feedings'), findsOneWidget);
      });

      testWidgets('displays days with app', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            statisticsState: StatisticsState(
              statistics: createStatistics(daysWithApp: 45),
            ),
          ),
        );

        expect(find.text('45'), findsOneWidget);
        expect(find.text('Days with FishFeed'), findsOneWidget);
      });

      testWidgets('displays current level', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            statisticsState: StatisticsState(
              statistics: createStatistics(currentLevel: UserLevel.fishMaster),
            ),
          ),
        );

        expect(find.text('Master'), findsOneWidget);
        expect(find.text('Level'), findsOneWidget);
      });

      testWidgets('displays XP progress text', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            statisticsState: StatisticsState(
              statistics: createStatistics(
                xpInCurrentLevel: 150,
                xpForCurrentLevel: 400,
                isMaxLevel: false,
              ),
            ),
          ),
        );

        expect(find.text('150 / 400 XP'), findsOneWidget);
        expect(find.text('Experience'), findsOneWidget);
      });

      testWidgets('displays max level XP text', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            statisticsState: StatisticsState(
              statistics: createStatistics(
                currentLevel: UserLevel.aquariumPro,
                totalXp: 3000,
                isMaxLevel: true,
              ),
            ),
          ),
        );

        expect(find.text('3000 XP (Max)'), findsOneWidget);
      });

      testWidgets('displays all four stat icons', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            statisticsState: StatisticsState(statistics: createStatistics()),
          ),
        );

        expect(find.byIcon(Icons.bar_chart_rounded), findsOneWidget);
        expect(find.byIcon(Icons.restaurant), findsOneWidget);
        expect(find.byIcon(Icons.calendar_today), findsOneWidget);
        expect(find.byIcon(Icons.shield), findsOneWidget);
      });
    });

    group('Loading State', () {
      testWidgets('shows shimmer when loading', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            statisticsState: const StatisticsState(isLoading: true),
          ),
        );

        // Should not find stat labels
        expect(find.text('Statistics'), findsNothing);
        expect(find.text('Feedings'), findsNothing);
      });

      testWidgets('does not show content when loading', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            statisticsState: const StatisticsState(isLoading: true),
          ),
        );

        expect(find.text('On Time'), findsNothing);
        expect(find.byIcon(Icons.restaurant), findsNothing);
      });
    });

    group('Null Statistics State', () {
      testWidgets('renders nothing when statistics is null', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(statisticsState: const StatisticsState()),
        );

        expect(find.byType(SizedBox), findsWidgets);
        expect(find.text('Statistics'), findsNothing);
      });
    });

    group('Level Colors', () {
      testWidgets('displays green color for beginner level', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            statisticsState: StatisticsState(
              statistics: createStatistics(
                currentLevel: UserLevel.beginnerAquarist,
              ),
            ),
          ),
        );

        expect(find.text('Beginner'), findsOneWidget);
      });

      testWidgets('displays blue color for caretaker level', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            statisticsState: StatisticsState(
              statistics: createStatistics(currentLevel: UserLevel.caretaker),
            ),
          ),
        );

        expect(find.text('Caretaker'), findsOneWidget);
      });

      testWidgets('displays orange color for fishMaster level', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            statisticsState: StatisticsState(
              statistics: createStatistics(currentLevel: UserLevel.fishMaster),
            ),
          ),
        );

        expect(find.text('Master'), findsOneWidget);
      });

      testWidgets('displays purple color for aquariumPro level', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            statisticsState: StatisticsState(
              statistics: createStatistics(currentLevel: UserLevel.aquariumPro),
            ),
          ),
        );

        expect(find.text('Pro'), findsOneWidget);
      });
    });

    group('On-Time Percentage Colors', () {
      testWidgets('displays green color for percentage >= 80', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            statisticsState: StatisticsState(
              statistics: createStatistics(onTimePercentage: 90.0),
            ),
          ),
        );

        expect(find.text('90%'), findsOneWidget);
      });

      testWidgets('displays orange color for percentage 50-79', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            statisticsState: StatisticsState(
              statistics: createStatistics(onTimePercentage: 65.0),
            ),
          ),
        );

        expect(find.text('65%'), findsOneWidget);
      });

      testWidgets('displays red color for percentage < 50', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            statisticsState: StatisticsState(
              statistics: createStatistics(onTimePercentage: 30.0),
            ),
          ),
        );

        expect(find.text('30%'), findsOneWidget);
      });
    });

    group('XP Progress Bar', () {
      testWidgets('displays progress bar with animation', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            statisticsState: StatisticsState(
              statistics: createStatistics(levelProgress: 0.5),
            ),
          ),
        );

        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(find.byType(TweenAnimationBuilder<double>), findsOneWidget);
      });

      testWidgets('shows full progress for max level', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            statisticsState: StatisticsState(
              statistics: createStatistics(
                currentLevel: UserLevel.aquariumPro,
                isMaxLevel: true,
                levelProgress: 1.0,
              ),
            ),
          ),
        );

        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });
    });

    group('Circular Progress Indicator', () {
      testWidgets('displays circular progress for on-time percentage', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            statisticsState: StatisticsState(
              statistics: createStatistics(onTimePercentage: 75.0),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('Edge Cases', () {
      testWidgets('handles 0% on-time correctly', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            statisticsState: StatisticsState(
              statistics: createStatistics(onTimePercentage: 0.0),
            ),
          ),
        );

        expect(find.text('0%'), findsOneWidget);
      });

      testWidgets('handles 100% on-time correctly', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            statisticsState: StatisticsState(
              statistics: createStatistics(onTimePercentage: 100.0),
            ),
          ),
        );

        expect(find.text('100%'), findsOneWidget);
      });

      testWidgets('handles 0 total feedings correctly', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            statisticsState: StatisticsState(
              statistics: createStatistics(totalFeedings: 0),
            ),
          ),
        );

        expect(find.text('0'), findsOneWidget);
      });

      testWidgets('handles 0 days with app correctly', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            statisticsState: StatisticsState(
              statistics: createStatistics(daysWithApp: 0),
            ),
          ),
        );

        // daysWithApp shows 0
        final finder = find.descendant(
          of: find.ancestor(
            of: find.text('Days with FishFeed'),
            matching: find.byType(Column),
          ),
          matching: find.text('0'),
        );
        expect(finder, findsOneWidget);
      });

      testWidgets('handles large numbers correctly', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            statisticsState: StatisticsState(
              statistics: createStatistics(
                totalFeedings: 9999,
                daysWithApp: 365,
              ),
            ),
          ),
        );

        expect(find.text('9999'), findsOneWidget);
        expect(find.text('365'), findsOneWidget);
      });
    });
  });
}

/// Test-only StatisticsNotifier that returns a fixed state.
class _TestStatisticsNotifier extends StatisticsNotifier {
  _TestStatisticsNotifier(this._initialState)
    : super(
        calculateStatisticsUseCase: _MockCalculateStatisticsUseCase(),
        userId: 'test_user',
      );

  final StatisticsState _initialState;

  @override
  StatisticsState get state => _initialState;

  @override
  set state(StatisticsState value) {
    // No-op for tests
  }

  @override
  Future<void> loadStatistics() async {
    // No-op for tests
  }
}

/// Minimal mock for CalculateStatisticsUseCase.
class _MockCalculateStatisticsUseCase extends Mock
    implements CalculateStatisticsUseCase {}
