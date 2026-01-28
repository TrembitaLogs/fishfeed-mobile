import 'package:flutter_test/flutter_test.dart';

import 'package:fishfeed/domain/entities/family_member.dart';

void main() {
  group('FamilyMember', () {
    final now = DateTime.now();
    final owner = FamilyMember(
      id: 'member-1',
      userId: 'user-1',
      aquariumId: 'aquarium-1',
      role: FamilyMemberRole.owner,
      joinedAt: now,
      displayName: 'Owner User',
      avatarUrl: 'https://example.com/avatar.png',
    );

    final member = FamilyMember(
      id: 'member-2',
      userId: 'user-2',
      aquariumId: 'aquarium-1',
      role: FamilyMemberRole.member,
      joinedAt: now,
    );

    test('isOwner returns true for owner role', () {
      expect(owner.isOwner, true);
    });

    test('isOwner returns false for member role', () {
      expect(member.isOwner, false);
    });

    test('copyWith creates copy with updated fields', () {
      final updated = member.copyWith(
        displayName: 'Updated Name',
        avatarUrl: 'https://example.com/new-avatar.png',
      );

      expect(updated.id, member.id);
      expect(updated.userId, member.userId);
      expect(updated.aquariumId, member.aquariumId);
      expect(updated.role, member.role);
      expect(updated.displayName, 'Updated Name');
      expect(updated.avatarUrl, 'https://example.com/new-avatar.png');
    });

    test('copyWith can change role', () {
      final promoted = member.copyWith(role: FamilyMemberRole.owner);
      expect(promoted.isOwner, true);
    });

    test('equality works correctly', () {
      final copy = FamilyMember(
        id: 'member-1',
        userId: 'user-1',
        aquariumId: 'aquarium-1',
        role: FamilyMemberRole.owner,
        joinedAt: owner.joinedAt,
        displayName: 'Owner User',
        avatarUrl: 'https://example.com/avatar.png',
      );

      expect(owner, equals(copy));
    });

    test('different members are not equal', () {
      expect(owner, isNot(equals(member)));
    });

    test('nullable fields are optional', () {
      final minimal = FamilyMember(
        id: 'member-3',
        userId: 'user-3',
        aquariumId: 'aquarium-1',
        role: FamilyMemberRole.member,
        joinedAt: now,
      );

      expect(minimal.displayName, isNull);
      expect(minimal.avatarUrl, isNull);
    });
  });

  group('FamilyMemberRole', () {
    test('has all expected values', () {
      expect(FamilyMemberRole.values, [
        FamilyMemberRole.owner,
        FamilyMemberRole.member,
      ]);
    });
  });
}
