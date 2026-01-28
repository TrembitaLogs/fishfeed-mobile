import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:fishfeed/data/models/base_hive_model.dart';

/// Test implementation of BaseHiveModel for testing purposes.
class TestHiveModel extends BaseHiveModel {

  TestHiveModel({
    required this.name,
    super.createdAt,
    super.updatedAt,
  });
  final String name;
}

void main() {
  group('BaseHiveModel', () {
    test('should set createdAt to current time when not provided', () {
      final before = DateTime.now();
      final model = TestHiveModel(name: 'test');
      final after = DateTime.now();

      expect(model.createdAt.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(model.createdAt.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });

    test('should set updatedAt to current time when not provided', () {
      final before = DateTime.now();
      final model = TestHiveModel(name: 'test');
      final after = DateTime.now();

      expect(model.updatedAt.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(model.updatedAt.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });

    test('should use provided createdAt value', () {
      final customTime = DateTime(2024, 1, 15, 10, 30);
      final model = TestHiveModel(name: 'test', createdAt: customTime);

      expect(model.createdAt, customTime);
    });

    test('should use provided updatedAt value', () {
      final customTime = DateTime(2024, 1, 15, 10, 30);
      final model = TestHiveModel(name: 'test', updatedAt: customTime);

      expect(model.updatedAt, customTime);
    });

    test('touch should update updatedAt to current time', () async {
      final oldTime = DateTime(2024, 1, 1);
      final model = TestHiveModel(name: 'test', updatedAt: oldTime);

      expect(model.updatedAt, oldTime);

      // Small delay to ensure different timestamp
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final before = DateTime.now();
      model.touch();
      final after = DateTime.now();

      expect(model.updatedAt.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(model.updatedAt.isBefore(after.add(const Duration(seconds: 1))), isTrue);
      expect(model.updatedAt.isAfter(oldTime), isTrue);
    });

    test('touch should not affect createdAt', () {
      final createdTime = DateTime(2024, 1, 1);
      final model = TestHiveModel(name: 'test', createdAt: createdTime);

      model.touch();

      expect(model.createdAt, createdTime);
    });

    test('should extend HiveObject', () {
      final model = TestHiveModel(name: 'test');
      expect(model, isA<HiveObject>());
    });
  });
}
