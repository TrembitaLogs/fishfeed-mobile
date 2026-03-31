import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/domain/entities/ai_scan_result.dart';

/// Repository interface for AI fish scanning operations.
abstract interface class AiScanRepository {
  /// Scans a fish image and returns the detected species.
  ///
  /// [imageBytes] - Compressed image bytes to upload.
  ///
  /// Returns [Right] with [AiScanResult] on success.
  /// Returns [Left] with [Failure] on error.
  Future<Either<Failure, AiScanResult>> scanFishImage({
    required Uint8List imageBytes,
  });
}
