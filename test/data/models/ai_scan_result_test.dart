import 'package:flutter_test/flutter_test.dart';

import 'package:fishfeed/data/models/ai_scan_result.dart';

void main() {
  group('AiScanResult', () {
    final testJson = {
      'species_id': 'species-123',
      'species_name': 'Goldfish',
      'confidence': 0.85,
      'recommendations': ['Feed twice daily', 'Keep water temperature 20-24C'],
      'image_url': 'https://example.com/goldfish.jpg',
      'feeding_frequency': 'twice_daily',
      'care_level': 'beginner',
    };

    final minimalJson = {
      'species_id': 'species-456',
      'species_name': 'Betta',
      'confidence': 0.42,
    };

    group('fromJson', () {
      test('should parse all fields correctly', () {
        final result = AiScanResult.fromJson(testJson);

        expect(result.speciesId, 'species-123');
        expect(result.speciesName, 'Goldfish');
        expect(result.confidence, 0.85);
        expect(result.recommendations, hasLength(2));
        expect(result.recommendations[0], 'Feed twice daily');
        expect(result.imageUrl, 'https://example.com/goldfish.jpg');
        expect(result.feedingFrequency, 'twice_daily');
        expect(result.careLevel, 'beginner');
      });

      test('should handle minimal JSON with defaults', () {
        final result = AiScanResult.fromJson(minimalJson);

        expect(result.speciesId, 'species-456');
        expect(result.speciesName, 'Betta');
        expect(result.confidence, 0.42);
        expect(result.recommendations, isEmpty);
        expect(result.imageUrl, isNull);
        expect(result.feedingFrequency, isNull);
        expect(result.careLevel, isNull);
      });

      test('should handle empty recommendations array', () {
        final json = {
          ...minimalJson,
          'recommendations': <String>[],
        };
        final result = AiScanResult.fromJson(json);

        expect(result.recommendations, isEmpty);
      });
    });

    group('toJson', () {
      test('should serialize all fields correctly', () {
        const result = AiScanResult(
          speciesId: 'species-789',
          speciesName: 'Neon Tetra',
          confidence: 0.92,
          recommendations: ['School fish', 'Soft water preferred'],
          imageUrl: 'https://example.com/tetra.jpg',
          feedingFrequency: 'daily',
          careLevel: 'intermediate',
        );

        final json = result.toJson();

        expect(json['species_id'], 'species-789');
        expect(json['species_name'], 'Neon Tetra');
        expect(json['confidence'], 0.92);
        expect(json['recommendations'], hasLength(2));
        expect(json['image_url'], 'https://example.com/tetra.jpg');
        expect(json['feeding_frequency'], 'daily');
        expect(json['care_level'], 'intermediate');
      });
    });

    group('isHighConfidence', () {
      test('should return true for confidence >= 0.8', () {
        final result = AiScanResult.fromJson({
          ...minimalJson,
          'confidence': 0.8,
        });

        expect(result.isHighConfidence, true);
      });

      test('should return true for confidence > 0.8', () {
        final result = AiScanResult.fromJson({
          ...minimalJson,
          'confidence': 0.95,
        });

        expect(result.isHighConfidence, true);
      });

      test('should return false for confidence < 0.8', () {
        final result = AiScanResult.fromJson({
          ...minimalJson,
          'confidence': 0.79,
        });

        expect(result.isHighConfidence, false);
      });
    });

    group('isLowConfidence', () {
      test('should return true for confidence < 0.5', () {
        final result = AiScanResult.fromJson({
          ...minimalJson,
          'confidence': 0.49,
        });

        expect(result.isLowConfidence, true);
      });

      test('should return false for confidence >= 0.5', () {
        final result = AiScanResult.fromJson({
          ...minimalJson,
          'confidence': 0.5,
        });

        expect(result.isLowConfidence, false);
      });
    });

    group('confidencePercent', () {
      test('should format 0.85 as 85%', () {
        final result = AiScanResult.fromJson(testJson);

        expect(result.confidencePercent, '85%');
      });

      test('should format 1.0 as 100%', () {
        final result = AiScanResult.fromJson({
          ...minimalJson,
          'confidence': 1.0,
        });

        expect(result.confidencePercent, '100%');
      });

      test('should format 0.0 as 0%', () {
        final result = AiScanResult.fromJson({
          ...minimalJson,
          'confidence': 0.0,
        });

        expect(result.confidencePercent, '0%');
      });

      test('should round 0.856 to 86%', () {
        final result = AiScanResult.fromJson({
          ...minimalJson,
          'confidence': 0.856,
        });

        expect(result.confidencePercent, '86%');
      });
    });

    group('equality', () {
      test('should be equal for same values', () {
        final result1 = AiScanResult.fromJson(testJson);
        final result2 = AiScanResult.fromJson(testJson);

        expect(result1, equals(result2));
      });

      test('should not be equal for different species', () {
        final result1 = AiScanResult.fromJson(testJson);
        final result2 = AiScanResult.fromJson({
          ...testJson,
          'species_id': 'different-species',
        });

        expect(result1, isNot(equals(result2)));
      });

      test('should not be equal for different confidence', () {
        final result1 = AiScanResult.fromJson(testJson);
        final result2 = AiScanResult.fromJson({
          ...testJson,
          'confidence': 0.5,
        });

        expect(result1, isNot(equals(result2)));
      });
    });

    group('copyWith', () {
      test('should copy with updated species', () {
        final original = AiScanResult.fromJson(testJson);
        final copied = original.copyWith(
          speciesId: 'new-species',
          speciesName: 'New Fish',
        );

        expect(copied.speciesId, 'new-species');
        expect(copied.speciesName, 'New Fish');
        expect(copied.confidence, original.confidence);
        expect(copied.recommendations, original.recommendations);
      });

      test('should copy with updated confidence', () {
        final original = AiScanResult.fromJson(testJson);
        final copied = original.copyWith(confidence: 0.99);

        expect(copied.confidence, 0.99);
        expect(copied.speciesId, original.speciesId);
      });
    });
  });
}
