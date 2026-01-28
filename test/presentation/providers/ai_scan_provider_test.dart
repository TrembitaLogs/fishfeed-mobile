import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/data/models/ai_scan_result.dart';
import 'package:fishfeed/data/repositories/ai_scan_repository.dart';
import 'package:fishfeed/presentation/providers/ai_scan_provider.dart';

class MockAiScanRepository extends Mock implements AiScanRepository {}

void main() {
  late MockAiScanRepository mockRepository;
  late AiScanNotifier notifier;

  final testImageBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]);

  const testScanResult = AiScanResult(
    speciesId: 'species-123',
    speciesName: 'Goldfish',
    confidence: 0.85,
    recommendations: ['Feed twice daily'],
  );

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    mockRepository = MockAiScanRepository();
    notifier = AiScanNotifier(repository: mockRepository);
  });

  group('AiScanNotifier', () {
    group('initial state', () {
      test('should start with AiScanIdle state', () {
        expect(notifier.state, isA<AiScanIdle>());
      });
    });

    group('scanImage', () {
      test(
        'should transition to loading then success on successful scan',
        () async {
          when(
            () => mockRepository.scanFishImage(
              imageBytes: any(named: 'imageBytes'),
            ),
          ).thenAnswer((_) async => const Right(testScanResult));

          // Capture state changes
          final states = <AiScanState>[];
          notifier.addListener((state) => states.add(state));

          await notifier.scanImage(testImageBytes);

          // Should have gone through loading
          expect(states.any((s) => s is AiScanLoading), true);

          // Should end in success
          expect(notifier.state, isA<AiScanSuccess>());
          final successState = notifier.state as AiScanSuccess;
          expect(successState.result.speciesId, 'species-123');
          expect(successState.result.speciesName, 'Goldfish');
        },
      );

      test('should transition to loading then error on failed scan', () async {
        when(
          () => mockRepository.scanFishImage(
            imageBytes: any(named: 'imageBytes'),
          ),
        ).thenAnswer((_) async => const Left(NetworkFailure()));

        final states = <AiScanState>[];
        notifier.addListener((state) => states.add(state));

        await notifier.scanImage(testImageBytes);

        // Should have gone through loading
        expect(states.any((s) => s is AiScanLoading), true);

        // Should end in error
        expect(notifier.state, isA<AiScanError>());
        final errorState = notifier.state as AiScanError;
        expect(errorState.message, 'Check your connection');
        expect(errorState.canRetry, true);
      });

      test('should show loading message during scan', () async {
        when(
          () => mockRepository.scanFishImage(
            imageBytes: any(named: 'imageBytes'),
          ),
        ).thenAnswer((_) async {
          // Add delay to capture loading state
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return const Right(testScanResult);
        });

        final scanFuture = notifier.scanImage(testImageBytes);

        // Check loading state immediately
        expect(notifier.state, isA<AiScanLoading>());
        final loadingState = notifier.state as AiScanLoading;
        expect(loadingState.message, 'Analyzing...');

        await scanFuture;
      });
    });

    group('error messages', () {
      test('should show correct message for NetworkFailure', () async {
        when(
          () => mockRepository.scanFishImage(
            imageBytes: any(named: 'imageBytes'),
          ),
        ).thenAnswer((_) async => const Left(NetworkFailure()));

        await notifier.scanImage(testImageBytes);

        final errorState = notifier.state as AiScanError;
        expect(errorState.message, 'Check your connection');
        expect(errorState.canRetry, true);
      });

      test('should show correct message for ServerFailure', () async {
        when(
          () => mockRepository.scanFishImage(
            imageBytes: any(named: 'imageBytes'),
          ),
        ).thenAnswer((_) async => const Left(ServerFailure()));

        await notifier.scanImage(testImageBytes);

        final errorState = notifier.state as AiScanError;
        expect(errorState.message, 'Server error. Try again later');
        expect(errorState.canRetry, true);
      });

      test('should show correct message for AuthenticationFailure', () async {
        when(
          () => mockRepository.scanFishImage(
            imageBytes: any(named: 'imageBytes'),
          ),
        ).thenAnswer(
          (_) async => const Left(AuthenticationFailure(message: 'Log in')),
        );

        await notifier.scanImage(testImageBytes);

        final errorState = notifier.state as AiScanError;
        expect(errorState.message, 'Log in');
        expect(errorState.canRetry, false);
      });

      test('should show correct message for ValidationFailure', () async {
        when(
          () => mockRepository.scanFishImage(
            imageBytes: any(named: 'imageBytes'),
          ),
        ).thenAnswer(
          (_) async => const Left(ValidationFailure(message: 'Bad image')),
        );

        await notifier.scanImage(testImageBytes);

        final errorState = notifier.state as AiScanError;
        expect(errorState.message, 'Bad image');
        expect(errorState.canRetry, false);
      });

      test('should show fallback message for UnexpectedFailure', () async {
        when(
          () => mockRepository.scanFishImage(
            imageBytes: any(named: 'imageBytes'),
          ),
        ).thenAnswer((_) async => const Left(UnexpectedFailure()));

        await notifier.scanImage(testImageBytes);

        final errorState = notifier.state as AiScanError;
        expect(errorState.message, 'Failed to analyze image');
        expect(errorState.canRetry, true);
      });
    });

    group('retry', () {
      test('should retry with same image bytes', () async {
        when(
          () => mockRepository.scanFishImage(
            imageBytes: any(named: 'imageBytes'),
          ),
        ).thenAnswer((_) async => const Left(NetworkFailure()));

        await notifier.scanImage(testImageBytes);
        expect(notifier.state, isA<AiScanError>());

        // Now make it succeed
        when(
          () => mockRepository.scanFishImage(
            imageBytes: any(named: 'imageBytes'),
          ),
        ).thenAnswer((_) async => const Right(testScanResult));

        await notifier.retry();

        expect(notifier.state, isA<AiScanSuccess>());
        verify(
          () => mockRepository.scanFishImage(imageBytes: testImageBytes),
        ).called(2);
      });

      test('should do nothing if no previous scan', () async {
        await notifier.retry();

        expect(notifier.state, isA<AiScanIdle>());
        verifyNever(
          () => mockRepository.scanFishImage(
            imageBytes: any(named: 'imageBytes'),
          ),
        );
      });
    });

    group('reset', () {
      test('should reset to idle state', () async {
        when(
          () => mockRepository.scanFishImage(
            imageBytes: any(named: 'imageBytes'),
          ),
        ).thenAnswer((_) async => const Right(testScanResult));

        await notifier.scanImage(testImageBytes);
        expect(notifier.state, isA<AiScanSuccess>());

        notifier.reset();

        expect(notifier.state, isA<AiScanIdle>());
      });

      test('should clear stored image bytes', () async {
        when(
          () => mockRepository.scanFishImage(
            imageBytes: any(named: 'imageBytes'),
          ),
        ).thenAnswer((_) async => const Right(testScanResult));

        await notifier.scanImage(testImageBytes);
        notifier.reset();

        // Retry should do nothing since image bytes are cleared
        await notifier.retry();
        expect(notifier.state, isA<AiScanIdle>());
      });
    });
  });

  group('AiScanState', () {
    test('AiScanIdle is correct type', () {
      const state = AiScanIdle();
      expect(state, isA<AiScanState>());
    });

    test('AiScanLoading has default message', () {
      const state = AiScanLoading();
      expect(state.message, 'Analyzing...');
    });

    test('AiScanLoading can have custom message', () {
      const state = AiScanLoading(message: 'Processing...');
      expect(state.message, 'Processing...');
    });

    test('AiScanSuccess contains result', () {
      const state = AiScanSuccess(result: testScanResult);
      expect(state.result.speciesName, 'Goldfish');
    });

    test('AiScanError has message and retry flag', () {
      const state = AiScanError(message: 'Error', canRetry: false);
      expect(state.message, 'Error');
      expect(state.canRetry, false);
    });

    test('AiScanError defaults canRetry to true', () {
      const state = AiScanError(message: 'Error');
      expect(state.canRetry, true);
    });
  });
}
