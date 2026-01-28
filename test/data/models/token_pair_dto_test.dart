import 'package:flutter_test/flutter_test.dart';

import 'package:fishfeed/data/models/token_pair_dto.dart';

void main() {
  group('TokenPairDto', () {
    final testJson = {
      'access_token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.access',
      'refresh_token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.refresh',
      'expires_in': 3600,
    };

    final minimalJson = {
      'access_token': 'access-token',
      'refresh_token': 'refresh-token',
    };

    group('fromJson', () {
      test('should parse all fields correctly', () {
        final dto = TokenPairDto.fromJson(testJson);

        expect(dto.accessToken, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.access');
        expect(
          dto.refreshToken,
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.refresh',
        );
        expect(dto.expiresIn, 3600);
      });

      test('should handle missing expires_in', () {
        final dto = TokenPairDto.fromJson(minimalJson);

        expect(dto.accessToken, 'access-token');
        expect(dto.refreshToken, 'refresh-token');
        expect(dto.expiresIn, isNull);
      });

      test('should handle null expires_in', () {
        final jsonWithNull = {...testJson, 'expires_in': null};
        final dto = TokenPairDto.fromJson(jsonWithNull);

        expect(dto.expiresIn, isNull);
      });
    });

    group('toJson', () {
      test('should serialize all fields correctly', () {
        const dto = TokenPairDto(
          accessToken: 'access-token-123',
          refreshToken: 'refresh-token-456',
          expiresIn: 7200,
        );

        final json = dto.toJson();

        expect(json['access_token'], 'access-token-123');
        expect(json['refresh_token'], 'refresh-token-456');
        expect(json['expires_in'], 7200);
      });

      test('should serialize without expires_in', () {
        const dto = TokenPairDto(
          accessToken: 'access',
          refreshToken: 'refresh',
        );

        final json = dto.toJson();

        expect(json['access_token'], 'access');
        expect(json['refresh_token'], 'refresh');
        expect(json['expires_in'], isNull);
      });
    });

    group('equality', () {
      test('should be equal for same values', () {
        final dto1 = TokenPairDto.fromJson(testJson);
        final dto2 = TokenPairDto.fromJson(testJson);

        expect(dto1, equals(dto2));
      });

      test('should not be equal for different tokens', () {
        final dto1 = TokenPairDto.fromJson(testJson);
        final dto2 = TokenPairDto.fromJson(minimalJson);

        expect(dto1, isNot(equals(dto2)));
      });
    });

    group('copyWith', () {
      test('should copy with updated access token', () {
        final original = TokenPairDto.fromJson(testJson);
        final copied = original.copyWith(accessToken: 'new-access-token');

        expect(copied.accessToken, 'new-access-token');
        expect(copied.refreshToken, original.refreshToken);
        expect(copied.expiresIn, original.expiresIn);
      });
    });
  });
}
