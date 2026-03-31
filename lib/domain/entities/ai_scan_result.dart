import 'package:equatable/equatable.dart';

/// Domain entity for AI fish scan result.
///
/// Contains the detected species information and AI recommendations.
class AiScanResult extends Equatable {
  const AiScanResult({
    required this.speciesId,
    required this.speciesName,
    required this.confidence,
    this.recommendations = const [],
    this.imageUrl,
    this.feedingFrequency,
    this.careLevel,
  });

  /// Unique identifier of the detected species.
  final String speciesId;

  /// Common name of the detected species.
  final String speciesName;

  /// Confidence score of the detection (0.0 to 1.0).
  final double confidence;

  /// AI-generated care recommendations for this species.
  final List<String> recommendations;

  /// Optional image URL for the detected species.
  final String? imageUrl;

  /// Optional feeding frequency recommendation.
  final String? feedingFrequency;

  /// Optional care level (beginner, intermediate, advanced).
  final String? careLevel;

  /// Whether the confidence is high enough to auto-confirm.
  bool get isHighConfidence => confidence >= 0.8;

  /// Whether the confidence is too low for reliable detection.
  bool get isLowConfidence => confidence < 0.5;

  /// Confidence as a percentage string (e.g., "85%").
  String get confidencePercent => '${(confidence * 100).round()}%';

  @override
  List<Object?> get props => [
    speciesId,
    speciesName,
    confidence,
    recommendations,
    imageUrl,
    feedingFrequency,
    careLevel,
  ];
}
