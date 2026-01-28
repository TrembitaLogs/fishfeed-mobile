import 'package:flutter_test/flutter_test.dart';

import 'package:fishfeed/data/models/user_dto.dart';

void main() {
  group('UserDto', () {
    final testJson = {
      'id': 'user-123',
      'email': 'test@example.com',
      'display_name': 'Test User',
      'avatar_url': 'https://example.com/avatar.png',
      'created_at': '2024-01-15T10:30:00.000Z',
      'subscription_status': 'premium',
      'free_ai_scans_remaining': 10,
    };

    final minimalJson = {
      'id': 'user-456',
      'email': 'minimal@example.com',
      'created_at': '2024-01-15T10:30:00.000Z',
    };

    group('fromJson', () {
      test('should parse all fields correctly', () {
        final dto = UserDto.fromJson(testJson);

        expect(dto.id, 'user-123');
        expect(dto.email, 'test@example.com');
        expect(dto.displayName, 'Test User');
        expect(dto.avatarUrl, 'https://example.com/avatar.png');
        expect(dto.createdAt, DateTime.utc(2024, 1, 15, 10, 30));
        expect(dto.subscriptionStatus, 'premium');
        expect(dto.freeAiScansRemaining, 10);
      });

      test('should use default values for optional fields', () {
        final dto = UserDto.fromJson(minimalJson);

        expect(dto.id, 'user-456');
        expect(dto.email, 'minimal@example.com');
        expect(dto.displayName, isNull);
        expect(dto.avatarUrl, isNull);
        expect(dto.subscriptionStatus, 'free');
        expect(dto.freeAiScansRemaining, 5);
      });

      test('should handle null display_name', () {
        final jsonWithNull = {...testJson, 'display_name': null};
        final dto = UserDto.fromJson(jsonWithNull);

        expect(dto.displayName, isNull);
      });

      test('should handle null avatar_url', () {
        final jsonWithNull = {...testJson, 'avatar_url': null};
        final dto = UserDto.fromJson(jsonWithNull);

        expect(dto.avatarUrl, isNull);
      });
    });

    group('toJson', () {
      test('should serialize all fields correctly', () {
        final dto = UserDto(
          id: 'user-123',
          email: 'test@example.com',
          displayName: 'Test User',
          avatarUrl: 'https://example.com/avatar.png',
          createdAt: DateTime.utc(2024, 1, 15, 10, 30),
          subscriptionStatus: 'premium',
          freeAiScansRemaining: 10,
        );

        final json = dto.toJson();

        expect(json['id'], 'user-123');
        expect(json['email'], 'test@example.com');
        expect(json['display_name'], 'Test User');
        expect(json['avatar_url'], 'https://example.com/avatar.png');
        expect(json['created_at'], '2024-01-15T10:30:00.000Z');
        expect(json['subscription_status'], 'premium');
        expect(json['free_ai_scans_remaining'], 10);
      });

      test('should serialize null optional fields', () {
        final dto = UserDto(
          id: 'user-456',
          email: 'minimal@example.com',
          createdAt: DateTime.utc(2024, 1, 15),
        );

        final json = dto.toJson();

        expect(json['display_name'], isNull);
        expect(json['avatar_url'], isNull);
      });
    });

    group('equality', () {
      test('should be equal for same values', () {
        final dto1 = UserDto.fromJson(testJson);
        final dto2 = UserDto.fromJson(testJson);

        expect(dto1, equals(dto2));
      });

      test('should not be equal for different values', () {
        final dto1 = UserDto.fromJson(testJson);
        final dto2 = UserDto.fromJson(minimalJson);

        expect(dto1, isNot(equals(dto2)));
      });
    });

    group('copyWith', () {
      test('should copy with updated values', () {
        final original = UserDto.fromJson(testJson);
        final copied = original.copyWith(email: 'new@example.com');

        expect(copied.email, 'new@example.com');
        expect(copied.id, original.id);
        expect(copied.displayName, original.displayName);
      });
    });
  });
}
