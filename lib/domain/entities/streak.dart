import 'package:equatable/equatable.dart';

/// Default number of freeze days available per month.
const int kDefaultFreezePerMonth = 2;

/// Domain entity representing a user's feeding streak.
///
/// Tracks consecutive days of feeding activity for gamification.
/// Includes freeze day mechanics to prevent streak loss.
class Streak extends Equatable {
  const Streak({
    required this.id,
    required this.userId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastFeedingDate,
    this.streakStartDate,
    this.freezeAvailable = kDefaultFreezePerMonth,
    this.frozenDays = const [],
    this.lastFreezeResetDate,
    this.synced = false,
    this.updatedAt,
    this.serverUpdatedAt,
  });

  /// Unique identifier for this streak record.
  final String id;

  /// ID of the user this streak belongs to.
  final String userId;

  /// Current consecutive days of feeding.
  final int currentStreak;

  /// Longest streak ever achieved.
  final int longestStreak;

  /// Date of the last feeding event.
  final DateTime? lastFeedingDate;

  /// When the current streak started.
  final DateTime? streakStartDate;

  /// Number of freeze days available this month (1-2 per month).
  /// Freeze days can be used to prevent streak loss on missed days.
  final int freezeAvailable;

  /// History of dates when freeze was used.
  /// Each entry represents a day where freeze prevented streak loss.
  final List<DateTime> frozenDays;

  /// Date when freeze availability was last reset (monthly reset).
  final DateTime? lastFreezeResetDate;

  /// Whether this streak has been synced to the server.
  final bool synced;

  /// When this record was last updated locally.
  final DateTime? updatedAt;

  /// Timestamp from server indicating when it was last updated there.
  final DateTime? serverUpdatedAt;

  /// Whether a freeze day can be used to prevent streak loss.
  bool get canUseFreeze => freezeAvailable > 0;

  /// Whether the streak is currently active (has at least 1 day).
  bool get isActive => currentStreak > 0;

  /// Creates a copy with updated fields.
  Streak copyWith({
    String? id,
    String? userId,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastFeedingDate,
    DateTime? streakStartDate,
    int? freezeAvailable,
    List<DateTime>? frozenDays,
    DateTime? lastFreezeResetDate,
    bool? synced,
    DateTime? updatedAt,
    DateTime? serverUpdatedAt,
  }) {
    return Streak(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastFeedingDate: lastFeedingDate ?? this.lastFeedingDate,
      streakStartDate: streakStartDate ?? this.streakStartDate,
      freezeAvailable: freezeAvailable ?? this.freezeAvailable,
      frozenDays: frozenDays ?? this.frozenDays,
      lastFreezeResetDate: lastFreezeResetDate ?? this.lastFreezeResetDate,
      synced: synced ?? this.synced,
      updatedAt: updatedAt ?? this.updatedAt,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        currentStreak,
        longestStreak,
        lastFeedingDate,
        streakStartDate,
        freezeAvailable,
        frozenDays,
        lastFreezeResetDate,
        synced,
        updatedAt,
        serverUpdatedAt,
      ];
}
