import 'package:hive_flutter/hive_flutter.dart';

/// Base class for all Hive models in the application.
///
/// Provides common fields and functionality shared across all local data models:
/// - [createdAt]: Timestamp when the record was first created locally
/// - [updatedAt]: Timestamp when the record was last modified locally
///
/// All models that extend this class automatically inherit timestamp tracking.
///
/// Example:
/// ```dart
/// @HiveType(typeId: 1)
/// class UserModel extends BaseHiveModel {
///   @HiveField(2)
///   final String name;
///
///   UserModel({
///     required this.name,
///     super.createdAt,
///     super.updatedAt,
///   });
/// }
/// ```
abstract class BaseHiveModel extends HiveObject {
  BaseHiveModel({
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Timestamp when this record was created locally.
  ///
  /// Set automatically when the model is first instantiated if not provided.
  DateTime createdAt;

  /// Timestamp when this record was last updated locally.
  ///
  /// Should be updated whenever the model data changes.
  DateTime updatedAt;

  /// Updates the [updatedAt] timestamp to the current time.
  ///
  /// Call this method before saving changes to the model.
  void touch() {
    updatedAt = DateTime.now();
  }

  /// Saves the model to its box with updated timestamp.
  ///
  /// Automatically calls [touch] before saving.
  @override
  Future<void> save() {
    touch();
    return super.save();
  }
}
