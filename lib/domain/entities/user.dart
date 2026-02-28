import 'package:equatable/equatable.dart';

import 'package:fishfeed/domain/entities/subscription_status.dart';
import 'package:fishfeed/domain/entities/user_settings.dart';

/// Domain entity representing a user.
class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarKey,
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

  /// S3 object key for user's avatar image.
  final String? avatarKey;

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
    String? avatarKey,
    DateTime? createdAt,
    SubscriptionStatus? subscriptionStatus,
    int? freeAiScansRemaining,
    UserSettings? settings,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarKey: avatarKey ?? this.avatarKey,
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
    avatarKey,
    createdAt,
    subscriptionStatus,
    freeAiScansRemaining,
    settings,
  ];
}
