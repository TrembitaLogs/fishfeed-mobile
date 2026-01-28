import 'package:equatable/equatable.dart';

import 'package:fishfeed/domain/entities/subscription_status.dart';
import 'package:fishfeed/domain/entities/user_settings.dart';

/// Domain entity representing a user.
class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
    required this.createdAt,
    this.subscriptionStatus = const SubscriptionStatus.free(),
    this.freeAiScansRemaining = 5,
    this.settings = const UserSettings(),
  });

  /// Unique identifier for the user.
  final String id;

  /// User's email address.
  final String email;

  /// User's display name (nickname).
  final String? displayName;

  /// URL to user's avatar image.
  final String? avatarUrl;

  /// When the user account was created.
  final DateTime createdAt;

  /// User's subscription status.
  final SubscriptionStatus subscriptionStatus;

  /// Number of free AI scans remaining.
  final int freeAiScansRemaining;

  /// User's application settings.
  final UserSettings settings;

  /// Creates a copy with updated fields.
  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? avatarUrl,
    DateTime? createdAt,
    SubscriptionStatus? subscriptionStatus,
    int? freeAiScansRemaining,
    UserSettings? settings,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      freeAiScansRemaining: freeAiScansRemaining ?? this.freeAiScansRemaining,
      settings: settings ?? this.settings,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        avatarUrl,
        createdAt,
        subscriptionStatus,
        freeAiScansRemaining,
        settings,
      ];
}
