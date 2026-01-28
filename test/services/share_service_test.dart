import 'package:flutter_test/flutter_test.dart';

import 'package:fishfeed/core/constants/achievements.dart';
import 'package:fishfeed/domain/entities/achievement.dart';
import 'package:fishfeed/services/share_service.dart';

void main() {
  group('ShareService', () {
    late ShareService shareService;

    setUp(() {
      shareService = ShareService();
    });

    group('getShareText', () {
      test('returns correct text for firstFeeding achievement', () {
        final achievement = Achievement.fromType(
          id: 'test-1',
          userId: 'user-1',
          achievementType: AchievementType.firstFeeding,
          unlockedAt: DateTime.now(),
        );

        final text = shareService.getShareText(achievement);

        expect(text, contains('FishFeed'));
        expect(text, contains('First Feeding'));
      });

      test('returns correct text for streak7 achievement', () {
        final achievement = Achievement.fromType(
          id: 'test-2',
          userId: 'user-1',
          achievementType: AchievementType.streak7,
          unlockedAt: DateTime.now(),
        );

        final text = shareService.getShareText(achievement);

        expect(text, contains('7 days'));
        expect(text, contains('FishFeed'));
      });

      test('returns correct text for streak30 achievement', () {
        final achievement = Achievement.fromType(
          id: 'test-3',
          userId: 'user-1',
          achievementType: AchievementType.streak30,
          unlockedAt: DateTime.now(),
        );

        final text = shareService.getShareText(achievement);

        expect(text, contains('30 days'));
        expect(text, contains('FishFeed'));
      });

      test('returns correct text for streak100 achievement', () {
        final achievement = Achievement.fromType(
          id: 'test-4',
          userId: 'user-1',
          achievementType: AchievementType.streak100,
          unlockedAt: DateTime.now(),
        );

        final text = shareService.getShareText(achievement);

        expect(text, contains('100 days'));
        expect(text, contains('Legendary'));
      });

      test('returns correct text for weekWithoutMiss achievement', () {
        final achievement = Achievement.fromType(
          id: 'test-5',
          userId: 'user-1',
          achievementType: AchievementType.weekWithoutMiss,
          unlockedAt: DateTime.now(),
        );

        final text = shareService.getShareText(achievement);

        expect(text, contains('Perfect Week'));
        expect(text, contains('FishFeed'));
      });

      test('returns correct text for feedings100 achievement', () {
        final achievement = Achievement.fromType(
          id: 'test-6',
          userId: 'user-1',
          achievementType: AchievementType.feedings100,
          unlockedAt: DateTime.now(),
        );

        final text = shareService.getShareText(achievement);

        expect(text, contains('100'));
        expect(text, contains('FishFeed'));
      });

      test('returns correct text for feedings500 achievement', () {
        final achievement = Achievement.fromType(
          id: 'test-7',
          userId: 'user-1',
          achievementType: AchievementType.feedings500,
          unlockedAt: DateTime.now(),
        );

        final text = shareService.getShareText(achievement);

        expect(text, contains('500'));
        expect(text, contains('Master'));
      });

      test('returns fallback text for unknown achievement type', () {
        const achievement = Achievement(
          id: 'test-unknown',
          userId: 'user-1',
          type: 'unknown_type',
          title: 'Test Achievement',
        );

        final text = shareService.getShareText(achievement);

        expect(text, contains('Test Achievement'));
        expect(text, contains('FishFeed'));
      });
    });

    group('isShareAvailable', () {
      test('returns true', () {
        expect(shareService.isShareAvailable, isTrue);
      });
    });

    group('ShareOperationResult', () {
      test('isSuccess returns true for success status', () {
        const result = ShareOperationResult(status: ShareStatus.success);
        expect(result.isSuccess, isTrue);
      });

      test('isSuccess returns false for dismissed status', () {
        const result = ShareOperationResult(status: ShareStatus.dismissed);
        expect(result.isSuccess, isFalse);
      });

      test('isSuccess returns false for error status', () {
        const result = ShareOperationResult(
          status: ShareStatus.error,
          errorMessage: 'Test error',
        );
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, 'Test error');
      });

      test('isSuccess returns false for unavailable status', () {
        const result = ShareOperationResult(status: ShareStatus.unavailable);
        expect(result.isSuccess, isFalse);
      });
    });
  });
}
