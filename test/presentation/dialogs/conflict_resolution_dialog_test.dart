import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/services/sync/conflict_resolver.dart';
import 'package:fishfeed/services/sync/sync_service.dart';
import 'package:fishfeed/presentation/dialogs/conflict_resolution_dialog.dart';

class MockSyncService extends Mock implements SyncService {}

void main() {
  late MockSyncService mockSyncService;
  late StreamController<SyncState> stateController;
  late StreamController<SyncConflict<Map<String, dynamic>>> conflictController;

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
    conflictController = StreamController<SyncConflict<Map<String, dynamic>>>.broadcast();

    // Default mock setup
    when(() => mockSyncService.stateStream).thenAnswer((_) => stateController.stream);
    when(() => mockSyncService.conflictStream).thenAnswer((_) => conflictController.stream);
    when(() => mockSyncService.currentState).thenReturn(SyncState.idle);
    when(() => mockSyncService.pendingConflicts).thenReturn([]);
    when(() => mockSyncService.hasUnresolvedConflicts).thenReturn(false);
    when(() => mockSyncService.resolveConflictWithLocal(any())).thenAnswer((_) async => true);
    when(() => mockSyncService.resolveConflictWithServer(any())).thenAnswer((_) async => true);
  });

  tearDown(() {
    stateController.close();
    conflictController.close();
  });

  SyncConflict<Map<String, dynamic>> createTestConflict({
    String entityId = 'test-123',
    List<String> conflictFields = const ['amount', 'notes'],
    ConflictType conflictType = ConflictType.dataConflict,
    DateTime? serverDeletedAt,
  }) {
    final now = DateTime.now();
    return SyncConflict<Map<String, dynamic>>(
      entityId: entityId,
      entityType: 'feeding_event',
      localVersion: {
        'id': entityId,
        'amount': 2.5,
        'notes': 'Local notes',
        'feeding_time': now.toIso8601String(),
      },
      serverVersion: {
        'id': entityId,
        'amount': 3.0,
        'notes': 'Server notes',
        'feeding_time': now.toIso8601String(),
      },
      localUpdatedAt: now,
      serverUpdatedAt: now.subtract(const Duration(seconds: 2)),
      resolution: ConflictResolution.requireManual,
      conflictType: conflictType,
      conflictFields: conflictFields,
      serverDeletedAt: serverDeletedAt,
    );
  }

  SyncConflict<Map<String, dynamic>> createDeletionConflict({
    String entityId = 'test-deletion-123',
  }) {
    final now = DateTime.now();
    final deletedAt = now.subtract(const Duration(hours: 1));
    return SyncConflict<Map<String, dynamic>>(
      entityId: entityId,
      entityType: 'feeding_event',
      localVersion: {
        'id': entityId,
        'amount': 2.5,
        'notes': 'Local notes',
        'feeding_time': now.toIso8601String(),
      },
      serverVersion: {
        'id': entityId,
        'deleted_at': deletedAt.toIso8601String(),
      },
      localUpdatedAt: now,
      serverUpdatedAt: deletedAt,
      resolution: ConflictResolution.requireManual,
      conflictType: ConflictType.deletionConflict,
      conflictFields: const [],
      serverDeletedAt: deletedAt,
    );
  }

  Widget buildTestWidget({
    required SyncConflict<Map<String, dynamic>> conflict,
  }) {
    return ProviderScope(
      overrides: [
        syncServiceProvider.overrideWithValue(mockSyncService),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: ElevatedButton(
                  onPressed: () {
                    ConflictResolutionDialog.show(context, conflict);
                  },
                  child: const Text('Show Dialog'),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  group('ConflictResolutionDialog', () {
    testWidgets('displays dialog title and description', (tester) async {
      final conflict = createTestConflict();
      await tester.pumpWidget(buildTestWidget(conflict: conflict));
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Sync Conflict'), findsOneWidget);
      expect(
        find.text('This item was modified on another device. Choose which version to keep.'),
        findsOneWidget,
      );
    });

    testWidgets('displays conflicting fields', (tester) async {
      final conflict = createTestConflict(
        conflictFields: ['amount', 'notes'],
      );
      await tester.pumpWidget(buildTestWidget(conflict: conflict));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Changed fields:'), findsOneWidget);
      expect(find.text('Amount'), findsWidgets);
      expect(find.text('Notes'), findsWidgets);
    });

    testWidgets('displays local and server version cards', (tester) async {
      final conflict = createTestConflict();
      await tester.pumpWidget(buildTestWidget(conflict: conflict));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Your version'), findsOneWidget);
      expect(find.text('Server version'), findsOneWidget);
    });

    testWidgets('shows local and server icons', (tester) async {
      final conflict = createTestConflict();
      await tester.pumpWidget(buildTestWidget(conflict: conflict));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.phone_android_rounded), findsOneWidget);
      expect(find.byIcon(Icons.cloud_rounded), findsOneWidget);
    });

    testWidgets('tapping "Keep mine" resolves with local', (tester) async {
      final conflict = createTestConflict(entityId: 'conflict-local');
      await tester.pumpWidget(buildTestWidget(conflict: conflict));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Keep mine'));
      await tester.pumpAndSettle();

      verify(() => mockSyncService.resolveConflictWithLocal('conflict-local')).called(1);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('tapping "Use server" resolves with server', (tester) async {
      final conflict = createTestConflict(entityId: 'conflict-server');
      await tester.pumpWidget(buildTestWidget(conflict: conflict));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Use server'));
      await tester.pumpAndSettle();

      verify(() => mockSyncService.resolveConflictWithServer('conflict-server')).called(1);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('dialog cannot be dismissed by tapping outside', (tester) async {
      final conflict = createTestConflict();
      await tester.pumpWidget(buildTestWidget(conflict: conflict));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Try to tap outside the dialog (barrier)
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Dialog should still be visible
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('displays sync problem icon in title', (tester) async {
      final conflict = createTestConflict();
      await tester.pumpWidget(buildTestWidget(conflict: conflict));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.sync_problem_rounded), findsOneWidget);
    });
  });

  group('Conflict field formatting', () {
    testWidgets('formats snake_case fields to Title Case', (tester) async {
      final conflict = createTestConflict(
        conflictFields: ['feeding_time', 'food_type'],
      );
      await tester.pumpWidget(buildTestWidget(conflict: conflict));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Feeding Time'), findsWidgets);
      expect(find.text('Food Type'), findsWidgets);
    });
  });

  group('Providers', () {
    test('hasUnresolvedConflictsProvider returns correct value', () {
      when(() => mockSyncService.hasUnresolvedConflicts).thenReturn(false);

      final container = ProviderContainer(
        overrides: [
          syncServiceProvider.overrideWithValue(mockSyncService),
        ],
      );

      final hasConflicts = container.read(hasUnresolvedConflictsProvider);
      expect(hasConflicts, isFalse);

      container.dispose();
    });

    test('pendingConflictsProvider returns empty list by default', () {
      when(() => mockSyncService.pendingConflicts).thenReturn([]);

      final container = ProviderContainer(
        overrides: [
          syncServiceProvider.overrideWithValue(mockSyncService),
        ],
      );

      final conflicts = container.read(pendingConflictsProvider);
      expect(conflicts, isEmpty);

      container.dispose();
    });

    test('hasUnresolvedConflictsProvider returns true when conflicts exist', () {
      when(() => mockSyncService.hasUnresolvedConflicts).thenReturn(true);

      final container = ProviderContainer(
        overrides: [
          syncServiceProvider.overrideWithValue(mockSyncService),
        ],
      );

      final hasConflicts = container.read(hasUnresolvedConflictsProvider);
      expect(hasConflicts, isTrue);

      container.dispose();
    });
  });

  group('Deletion Conflict', () {
    testWidgets('displays deletion conflict title and description',
        (tester) async {
      final conflict = createDeletionConflict();
      await tester.pumpWidget(buildTestWidget(conflict: conflict));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Deletion Conflict'), findsOneWidget);
      expect(
        find.text(
          'This item was deleted on another device but you made changes locally. Choose whether to restore or delete it.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('displays delete icon instead of sync problem icon',
        (tester) async {
      final conflict = createDeletionConflict();
      await tester.pumpWidget(buildTestWidget(conflict: conflict));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_sweep_rounded), findsOneWidget);
      expect(find.byIcon(Icons.sync_problem_rounded), findsNothing);
    });

    testWidgets('displays Restore and Delete buttons', (tester) async {
      final conflict = createDeletionConflict();
      await tester.pumpWidget(buildTestWidget(conflict: conflict));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Restore'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Keep mine'), findsNothing);
      expect(find.text('Use server'), findsNothing);
    });

    testWidgets('shows delete icon on server version card', (tester) async {
      final conflict = createDeletionConflict();
      await tester.pumpWidget(buildTestWidget(conflict: conflict));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_rounded), findsOneWidget);
    });

    testWidgets('does not show conflict fields for deletion conflict',
        (tester) async {
      final conflict = createDeletionConflict();
      await tester.pumpWidget(buildTestWidget(conflict: conflict));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Changed fields:'), findsNothing);
    });

    testWidgets('tapping Restore resolves with local', (tester) async {
      final conflict = createDeletionConflict(entityId: 'deletion-restore');
      await tester.pumpWidget(buildTestWidget(conflict: conflict));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Restore'));
      await tester.pumpAndSettle();

      verify(() => mockSyncService.resolveConflictWithLocal('deletion-restore'))
          .called(1);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('tapping Delete resolves with server', (tester) async {
      final conflict = createDeletionConflict(entityId: 'deletion-delete');
      await tester.pumpWidget(buildTestWidget(conflict: conflict));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      verify(
        () => mockSyncService.resolveConflictWithServer('deletion-delete'),
      ).called(1);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('shows "Deleted on" text with formatted date', (tester) async {
      final conflict = createDeletionConflict();
      await tester.pumpWidget(buildTestWidget(conflict: conflict));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Find text that starts with "Deleted on"
      expect(
        find.textContaining('Deleted on'),
        findsOneWidget,
      );
    });
  });
}
