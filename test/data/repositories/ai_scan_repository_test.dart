import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/errors/api_exceptions.dart';
import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/data/datasources/remote/ai_scan_remote_ds.dart';
import 'package:fishfeed/data/models/ai_scan_result.dart';
import 'package:fishfeed/data/repositories/ai_scan_repository.dart';

class MockAiScanRemoteDataSource extends Mock
    implements AiScanRemoteDataSource {}

void main() {
  late MockAiScanRemoteDataSource mockRemoteDataSource;
  late AiScanRepositoryImpl repository;

  final testImageBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]);

  const testScanResult = AiScanResult(
    speciesId: 'species-123',
    speciesName: 'Goldfish',
    confidence: 0.85,
    recommendations: ['Feed twice daily'],
    imageUrl: 'https://example.com/goldfish.jpg',
  );

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    mockRemoteDataSource = MockAiScanRemoteDataSource();
    repository = AiScanRepositoryImpl(remoteDataSource: mockRemoteDataSource);
  });

  group('scanFishImage', () {
    test('should return AiScanResult on successful scan', () async {
      when(
        () => mockRemoteDataSource.scanFishImage(
          imageBytes: any(named: 'imageBytes'),
          filename: any(named: 'filename'),
        ),
      ).thenAnswer((_) async => testScanResult);

      final result = await repository.scanFishImage(imageBytes: testImageBytes);

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should be Right'),
        (scanResult) {
          expect(scanResult.speciesId, 'species-123');
          expect(scanResult.speciesName, 'Goldfish');
          expect(scanResult.confidence, 0.85);
        },
      );

      verify(
        () => mockRemoteDataSource.scanFishImage(
          imageBytes: testImageBytes,
        ),
      ).called(1);
    });

    test('should return NetworkFailure on NetworkException', () async {
      when(
        () => mockRemoteDataSource.scanFishImage(
          imageBytes: any(named: 'imageBytes'),
          filename: any(named: 'filename'),
        ),
      ).thenThrow(const NetworkException());

      final result = await repository.scanFishImage(imageBytes: testImageBytes);

      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(failure.message, 'Check your connection');
        },
        (_) => fail('Should be Left'),
      );
    });

    test('should return ServerFailure on ServerException', () async {
      when(
        () => mockRemoteDataSource.scanFishImage(
          imageBytes: any(named: 'imageBytes'),
          filename: any(named: 'filename'),
        ),
      ).thenThrow(const ServerException());

      final result = await repository.scanFishImage(imageBytes: testImageBytes);

      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'Server error. Try again later');
        },
        (_) => fail('Should be Left'),
      );
    });

    test('should return AuthenticationFailure on UnauthorizedException',
        () async {
      when(
        () => mockRemoteDataSource.scanFishImage(
          imageBytes: any(named: 'imageBytes'),
          filename: any(named: 'filename'),
        ),
      ).thenThrow(const UnauthorizedException());

      final result = await repository.scanFishImage(imageBytes: testImageBytes);

      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<AuthenticationFailure>());
          expect(failure.message, 'Please log in to use AI scan');
        },
        (_) => fail('Should be Left'),
      );
    });

    test('should return ValidationFailure on ValidationException', () async {
      when(
        () => mockRemoteDataSource.scanFishImage(
          imageBytes: any(named: 'imageBytes'),
          filename: any(named: 'filename'),
        ),
      ).thenThrow(const ValidationException(message: 'Invalid image format'));

      final result = await repository.scanFishImage(imageBytes: testImageBytes);

      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, 'Invalid image format');
        },
        (_) => fail('Should be Left'),
      );
    });

    test('should return AuthenticationFailure on ForbiddenException', () async {
      when(
        () => mockRemoteDataSource.scanFishImage(
          imageBytes: any(named: 'imageBytes'),
          filename: any(named: 'filename'),
        ),
      ).thenThrow(const ForbiddenException());

      final result = await repository.scanFishImage(imageBytes: testImageBytes);

      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<AuthenticationFailure>());
          expect(failure.message, 'AI scan not available for your account');
        },
        (_) => fail('Should be Left'),
      );
    });

    test('should return ServerFailure on NotFoundException', () async {
      when(
        () => mockRemoteDataSource.scanFishImage(
          imageBytes: any(named: 'imageBytes'),
          filename: any(named: 'filename'),
        ),
      ).thenThrow(const NotFoundException());

      final result = await repository.scanFishImage(imageBytes: testImageBytes);

      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'AI scan service unavailable');
        },
        (_) => fail('Should be Left'),
      );
    });

    test('should return UnexpectedFailure on UnknownApiException', () async {
      when(
        () => mockRemoteDataSource.scanFishImage(
          imageBytes: any(named: 'imageBytes'),
          filename: any(named: 'filename'),
        ),
      ).thenThrow(const UnknownApiException(message: 'Something went wrong'));

      final result = await repository.scanFishImage(imageBytes: testImageBytes);

      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<UnexpectedFailure>());
          expect(failure.message, 'Something went wrong');
        },
        (_) => fail('Should be Left'),
      );
    });

    test('should return UnexpectedFailure on generic exception', () async {
      when(
        () => mockRemoteDataSource.scanFishImage(
          imageBytes: any(named: 'imageBytes'),
          filename: any(named: 'filename'),
        ),
      ).thenThrow(Exception('Generic error'));

      final result = await repository.scanFishImage(imageBytes: testImageBytes);

      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<UnexpectedFailure>());
          expect(failure.message, 'Failed to analyze image');
        },
        (_) => fail('Should be Left'),
      );
    });
  });
}
