import 'package:flutter_test/flutter_test.dart';

import 'package:fishfeed/data/models/auth_response_dto.dart';
import 'package:fishfeed/data/models/user_dto.dart';

void main() {
  group('AuthResponseDto', () {
    final testJson = {
      'user': {
        'id': 'user-123',
        'email': 'test@example.com',
        'display_name': 'Test User',
        'avatar_url': 'https://example.com/avatar.png',
        'created_at': '2024-01-15T10:30:00.000Z',
        'subscription_status': 'free',
        'free_ai_scans_remaining': 5,
      },
      'access_token': 'access-token-123',
      'refresh_token': 'refresh-token-456',
    };

    group('fromJson', () {
      test('should parse user and tokens correctly', () {
        final dto = AuthResponseDto.fromJson(testJson);

        expect(dto.user.id, 'user-123');
        expect(dto.user.email, 'test@example.com');
        expect(dto.user.displayName, 'Test User');
        expect(dto.accessToken, 'access-token-123');
        expect(dto.refreshToken, 'refresh-token-456');
      });

      test('should provide tokens getter for compatibility', () {
        final dto = AuthResponseDto.fromJson(testJson);

        expect(dto.tokens.accessToken, 'access-token-123');
        expect(dto.tokens.refreshToken, 'refresh-token-456');
      });

      test('should parse nested user with all fields', () {
        final dto = AuthResponseDto.fromJson(testJson);

        expect(dto.user.avatarUrl, 'https://example.com/avatar.png');
        expect(dto.user.createdAt, DateTime.utc(2024, 1, 15, 10, 30));
        expect(dto.user.subscriptionStatus, 'free');
        expect(dto.user.freeAiScansRemaining, 5);
      });
    });

    group('toJson', () {
      test('should serialize all fields correctly', () {
        final dto = AuthResponseDto(
          user: UserDto(
            id: 'user-789',
            email: 'serialize@example.com',
            displayName: 'Serialize Test',
            createdAt: DateTime.utc(2024, 6, 1),
          ),
          accessToken: 'new-access',
          refreshToken: 'new-refresh',
        );

        final json = dto.toJson();
        final userJson = json['user'] as Map<String, dynamic>;

        expect(userJson['id'], 'user-789');
        expect(userJson['email'], 'serialize@example.com');
        expect(userJson['display_name'], 'Serialize Test');
        expect(json['access_token'], 'new-access');
        expect(json['refresh_token'], 'new-refresh');
      });
    });

    group('equality', () {
      test('should be equal for same values', () {
        final dto1 = AuthResponseDto.fromJson(testJson);
        final dto2 = AuthResponseDto.fromJson(testJson);

        expect(dto1, equals(dto2));
      });

      test('should not be equal for different user', () {
        final dto1 = AuthResponseDto.fromJson(testJson);
        final differentUserJson = {
          ...testJson,
          'user': {
            ...(testJson['user']! as Map<String, dynamic>),
            'id': 'different-user',
          },
        };
        final dto2 = AuthResponseDto.fromJson(differentUserJson);

        expect(dto1, isNot(equals(dto2)));
      });

      test('should not be equal for different tokens', () {
        final dto1 = AuthResponseDto.fromJson(testJson);
        final differentTokensJson = {
          ...testJson,
          'access_token': 'different-token',
        };
        final dto2 = AuthResponseDto.fromJson(differentTokensJson);

        expect(dto1, isNot(equals(dto2)));
      });
    });

    group('copyWith', () {
      test('should copy with updated user', () {
        final original = AuthResponseDto.fromJson(testJson);
        final newUser = UserDto(
          id: 'new-user-id',
          email: 'new@example.com',
          createdAt: DateTime.utc(2024, 1, 1),
        );
        final copied = original.copyWith(user: newUser);

        expect(copied.user.id, 'new-user-id');
        expect(copied.accessToken, original.accessToken);
        expect(copied.refreshToken, original.refreshToken);
      });

      test('should copy with updated tokens', () {
        final original = AuthResponseDto.fromJson(testJson);
        final copied = original.copyWith(
          accessToken: 'updated-access',
          refreshToken: 'updated-refresh',
        );

        expect(copied.accessToken, 'updated-access');
        expect(copied.refreshToken, 'updated-refresh');
        expect(copied.user, original.user);
      });
    });
  });
}
