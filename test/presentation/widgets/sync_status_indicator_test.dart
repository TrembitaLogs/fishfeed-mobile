import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/services/connectivity/connectivity_service.dart';
import 'package:fishfeed/services/sync/sync_service.dart';
import 'package:fishfeed/presentation/widgets/sync_status_indicator.dart';

class MockSyncService extends Mock implements SyncService {}

void main() {
  late MockSyncService mockSyncService;
  late StreamController<SyncState> stateController;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  setUp(() {
    mockSyncService = MockSyncService();
    stateController = StreamController<SyncState>.broadcast();

    // Default mock setup
    when(
      () => mockSyncService.stateStream,
    ).thenAnswer((_) => stateController.stream);
    when(() => mockSyncService.currentState).thenReturn(SyncState.idle);
    when(() => mockSyncService.lastSyncTime).thenReturn(null);
    when(() => mockSyncService.pendingCount).thenReturn(0);
    when(() => mockSyncService.unsyncedFeedingCount).thenReturn(0);
    when(() => mockSyncService.syncNow()).thenAnswer((_) async => 1);
  });

  tearDown(() {
    stateController.close();
  });

  Widget buildTestWidget({
    bool isOffline = false,
    SyncState initialState = SyncState.idle,
    DateTime? lastSyncTime,
  }) {
    when(() => mockSyncService.currentState).thenReturn(initialState);
    when(() => mockSyncService.lastSyncTime).thenReturn(lastSyncTime);

    return ProviderScope(
      overrides: [
        syncServiceProvider.overrideWithValue(mockSyncService),
        syncStateProvider.overrideWith((ref) {
          return Stream.value(initialState);
        }),
        isOfflineProvider.overrideWithValue(isOffline),
        isOnlineProvider.overrideWith((ref) async* {
          yield !isOffline;
        }),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const Scaffold(body: Center(child: SyncStatusIndicator())),
      ),
    );
  }

  group('SyncStatusIndicator', () {
    testWidgets('shows offline state when offline', (tester) async {
      await tester.pumpWidget(buildTestWidget(isOffline: true));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
      expect(find.text('Offline'), findsOneWidget);
    });

    testWidgets('shows syncing state with animated icon', (tester) async {
      await tester.pumpWidget(buildTestWidget(initialState: SyncState.syncing));
      await tester.pump();

      expect(find.byIcon(Icons.sync_rounded), findsOneWidget);
      expect(find.text('Syncing...'), findsOneWidget);
    });

    testWidgets('shows success state with cloud done icon', (tester) async {
      await tester.pumpWidget(buildTestWidget(initialState: SyncState.success));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.cloud_done_rounded), findsOneWidget);
    });

    testWidgets('shows error state with problem icon', (tester) async {
      await tester.pumpWidget(buildTestWidget(initialState: SyncState.error));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.sync_problem_rounded), findsOneWidget);
      expect(find.text('Sync failed'), findsOneWidget);
    });

    testWidgets('shows "Just now" for recent sync', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          initialState: SyncState.success,
          lastSyncTime: DateTime.now(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Just now'), findsOneWidget);
    });

    testWidgets('shows relative time for older syncs', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          initialState: SyncState.success,
          lastSyncTime: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('5 min ago'), findsOneWidget);
    });

    testWidgets('shows snackbar when tapping while offline', (tester) async {
      await tester.pumpWidget(buildTestWidget(isOffline: true));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(SyncStatusIndicator));
      await tester.pumpAndSettle();

      expect(find.text('Cannot sync while offline'), findsOneWidget);
    });

    testWidgets('triggers sync when tapped while online', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(isOffline: false, initialState: SyncState.idle),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(SyncStatusIndicator));
      await tester.pump();

      verify(() => mockSyncService.syncNow()).called(1);
    });

    testWidgets('shows idle state with cloud done icon', (tester) async {
      await tester.pumpWidget(buildTestWidget(initialState: SyncState.idle));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.cloud_done_rounded), findsOneWidget);
    });

    testWidgets('shows hours ago for multi-hour old sync', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          initialState: SyncState.success,
          lastSyncTime: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 hours ago'), findsOneWidget);
    });

    testWidgets('shows days ago for multi-day old sync', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          initialState: SyncState.success,
          lastSyncTime: DateTime.now().subtract(const Duration(days: 3)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('3 days ago'), findsOneWidget);
    });
  });

  group('SyncStatusState', () {
    test('hasPendingItems returns true when pendingCount > 0', () {
      const state = SyncStatusState(
        syncState: SyncState.idle,
        isOnline: true,
        pendingCount: 5,
      );

      expect(state.hasPendingItems, isTrue);
    });

    test('hasPendingItems returns false when pendingCount is 0', () {
      const state = SyncStatusState(
        syncState: SyncState.idle,
        isOnline: true,
        pendingCount: 0,
      );

      expect(state.hasPendingItems, isFalse);
    });
  });
}
