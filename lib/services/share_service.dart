import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import 'package:fishfeed/core/constants/achievements.dart';
import 'package:fishfeed/domain/entities/achievement.dart';

/// Result of a share operation.
enum ShareStatus {
  /// Share completed successfully.
  success,

  /// User dismissed the share dialog.
  dismissed,

  /// Share is not available on this platform/device.
  unavailable,

  /// An error occurred during sharing.
  error,
}

/// Result of a share operation with optional error details.
class ShareOperationResult {
  const ShareOperationResult({required this.status, this.errorMessage});

  final ShareStatus status;
  final String? errorMessage;

  bool get isSuccess => status == ShareStatus.success;
}

/// Service for sharing achievements and content.
///
/// Provides methods for:
/// - Sharing achievements as images with the share card
/// - Sharing simple text for streak milestones
/// - Platform-specific share sheet handling
class ShareService {
  ShareService({ScreenshotController? screenshotController})
    : _screenshotController = screenshotController ?? ScreenshotController();

  final ScreenshotController _screenshotController;

  /// Screenshot controller for capturing widgets.
  ScreenshotController get screenshotController => _screenshotController;

  /// Shares an achievement as an image with text.
  ///
  /// Captures the provided [widget] (typically a ShareCard) as an image,
  /// saves it to a temporary file, and opens the native share sheet.
  ///
  /// [widget] - The widget to capture (should be a ShareCard).
  /// [achievement] - The achievement being shared (used for share text).
  /// [pixelRatio] - The pixel ratio for image capture (default: 3.0 for high quality).
  /// [shareText] - Optional localized share text. If not provided, uses default.
  /// [subject] - Optional localized subject line for the share.
  Future<ShareOperationResult> shareAchievementWithWidget({
    required Widget widget,
    required Achievement achievement,
    double pixelRatio = 3.0,
    String? shareText,
    String? subject,
  }) async {
    try {
      // Capture widget as image
      final imageBytes = await _screenshotController.captureFromWidget(
        widget,
        pixelRatio: pixelRatio,
        delay: const Duration(milliseconds: 100),
      );

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${tempDir.path}/achievement_$timestamp.png';
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      // Get share text
      final text = shareText ?? getShareText(achievement);

      // Share via native share sheet
      final result = await Share.shareXFiles(
        [XFile(filePath)],
        text: text,
        subject: subject ?? 'Achievement Unlocked - FishFeed',
      );

      // Clean up temp file
      try {
        await file.delete();
      } catch (e) {
        debugPrint('ShareService: Failed to clean up temp file: $e');
      }

      return ShareOperationResult(status: _mapShareResult(result.status));
    } catch (e) {
      return ShareOperationResult(
        status: ShareStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Shares an achievement using a GlobalKey for widget capture.
  ///
  /// This method is useful when you have a widget already in the tree
  /// and want to capture it using its GlobalKey with RepaintBoundary.
  ///
  /// [shareText] - Optional localized share text. If not provided, uses default.
  /// [subject] - Optional localized subject line for the share.
  Future<ShareOperationResult> shareAchievementFromKey({
    required GlobalKey key,
    required Achievement achievement,
    double pixelRatio = 3.0,
    String? shareText,
    String? subject,
  }) async {
    try {
      // Find the RenderRepaintBoundary
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        return const ShareOperationResult(
          status: ShareStatus.error,
          errorMessage: 'Widget not found or not ready for capture',
        );
      }

      // Capture to image
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        return const ShareOperationResult(
          status: ShareStatus.error,
          errorMessage: 'Failed to convert widget to image',
        );
      }

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${tempDir.path}/achievement_$timestamp.png';
      final file = File(filePath);
      await file.writeAsBytes(byteData.buffer.asUint8List());

      // Get share text
      final text = shareText ?? getShareText(achievement);

      // Share via native share sheet
      final result = await Share.shareXFiles(
        [XFile(filePath)],
        text: text,
        subject: subject ?? 'Achievement Unlocked - FishFeed',
      );

      // Clean up temp file
      try {
        await file.delete();
      } catch (e) {
        debugPrint('ShareService: Failed to clean up temp file: $e');
      }

      return ShareOperationResult(status: _mapShareResult(result.status));
    } catch (e) {
      return ShareOperationResult(
        status: ShareStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Shares simple text content.
  ///
  /// Useful for sharing streak milestones or quick updates.
  Future<ShareOperationResult> shareText(String text) async {
    try {
      final result = await Share.share(text, subject: 'FishFeed');

      return ShareOperationResult(status: _mapShareResult(result.status));
    } catch (e) {
      return ShareOperationResult(
        status: ShareStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Shares a streak milestone.
  ///
  /// Creates a formatted message about the user's streak achievement.
  Future<ShareOperationResult> shareStreakMilestone({
    required int streakDays,
    String? appName = 'FishFeed',
  }) async {
    final text = _getStreakMilestoneText(streakDays, appName!);
    return shareText(text);
  }

  /// Generates localized share text for an achievement.
  ///
  /// Returns Ukrainian text by default.
  String getShareText(Achievement achievement) {
    final achievementType = achievement.achievementType;

    if (achievementType != null) {
      return _getLocalizedShareText(achievementType);
    }

    // Fallback generic text
    return 'I unlocked "${achievement.title}" in FishFeed! 🐟🏆';
  }

  String _getLocalizedShareText(AchievementType type) {
    switch (type) {
      // Feeding
      case AchievementType.firstFeeding:
        return 'I started caring for fish in FishFeed! 🐟 First Feeding complete! 🎉';
      case AchievementType.streak7:
        return 'A week without misses! 🔥 My FishFeed streak: 7 days! 🏆';
      case AchievementType.streak30:
        return 'A month of excellence! 🌟 30 days of feedings in a row in FishFeed! 🔥';
      case AchievementType.streak100:
        return 'Legendary streak! 💎 100 days of feedings without misses in FishFeed! 🏆🔥';
      case AchievementType.streak365:
        return 'A full year! 🏅 365 days of feedings without misses in FishFeed! 🐟💎🔥';
      case AchievementType.weekWithoutMiss:
        return 'Perfect Week! ✨ No missed feedings in FishFeed! 🐟';
      case AchievementType.earlyBird:
        return 'Early Bird! 🌅 Fed my fish before sunrise in FishFeed! 🐟';
      case AchievementType.nightOwl:
        return 'Night Owl! 🌙 Late-night feeding in FishFeed! 🐟';
      case AchievementType.feedings50:
        return 'Dedicated Caretaker! 🐠 50 feedings completed in FishFeed! 🎉';
      case AchievementType.feedings100:
        return '100 feedings! 🎯 Fed my fish 100 times in FishFeed! 🐟';
      case AchievementType.feedings500:
        return 'Feeding Master! 👑 500 feedings in FishFeed! My fish are in good hands! 🐟🏆';
      case AchievementType.feedings1000:
        return 'Fish Whisperer! 🌊 1000 feedings in FishFeed! True dedication! 🐟💎';
      // Fish
      case AchievementType.firstFish:
        return 'My first fish! 🐟 Added my first fish to FishFeed! 🎉';
      case AchievementType.fishCollector10:
        return 'Fish Collector! 🐠 10 fish in my FishFeed aquariums! 🏆';
      case AchievementType.fishCollector50:
        return 'Master Collector! 🐟 50 fish in FishFeed! A true aquarist! 🏆💎';
      case AchievementType.speciesExplorer5:
        return 'Species Explorer! 🔍 5 different species in FishFeed! 🐟';
      case AchievementType.speciesExplorer10:
        return 'Species Expert! 🧬 10 different species in FishFeed! 🐠🏆';
      case AchievementType.speciesExplorer20:
        return 'Species Master! 🌊 20 different species in FishFeed! True biodiversity! 🐟💎';
      // Aquarium
      case AchievementType.firstAquarium:
        return 'My first aquarium! 🏠 Set up my first aquarium in FishFeed! 🐟';
      case AchievementType.aquariumCollector3:
        return 'Aquarium Enthusiast! 🏠 3 aquariums in FishFeed! 🐟🏆';
      case AchievementType.aquariumCollector10:
        return 'Aquarium Empire! 🏰 10 aquariums in FishFeed! A true master! 🐟💎';
      // Family
      case AchievementType.familyFirst:
        return 'Teamwork! 👨‍👩‍👧 Invited my first family member to FishFeed! 🐟';
      case AchievementType.familyTeam3:
        return 'Family Team! 👨‍👩‍👧‍👦 3 family members caring for fish in FishFeed! 🐟🏆';
      // Social
      case AchievementType.firstShare:
        return 'Shared my first achievement in FishFeed! 📢 Join me! 🐟';
    }
  }

  String _getStreakMilestoneText(int days, String appName) {
    if (days >= 100) {
      return 'Incredible! 💎 My streak in $appName: $days days! 🔥🏆';
    } else if (days >= 30) {
      return 'Amazing! 🌟 My streak in $appName: $days days! 🔥';
    } else if (days >= 7) {
      return 'Great! 🔥 My streak in $appName: $days days!';
    } else {
      return 'My streak in $appName: $days days! 🐟';
    }
  }

  ShareStatus _mapShareResult(ShareResultStatus status) {
    switch (status) {
      case ShareResultStatus.success:
        return ShareStatus.success;
      case ShareResultStatus.dismissed:
        return ShareStatus.dismissed;
      case ShareResultStatus.unavailable:
        return ShareStatus.unavailable;
    }
  }

  /// Checks if sharing is available on this device.
  ///
  /// Note: On most platforms, sharing is always available.
  /// This mainly checks for web browser support.
  bool get isShareAvailable {
    // share_plus handles platform availability internally
    // On web, it checks for Web Share API support
    return true;
  }
}
