import 'package:flutter_test/flutter_test.dart';

import 'package:fishfeed/domain/entities/family_invite.dart';

void main() {
  group('FamilyInvite', () {
    final now = DateTime.now();
    final validInvite = FamilyInvite(
      id: 'invite-1',
      aquariumId: 'aquarium-1',
      inviteCode: 'ABC12345',
      createdBy: 'user-1',
      createdAt: now,
      expiresAt: now.add(const Duration(hours: 48)),
      status: FamilyInviteStatus.pending,
    );

    test('deepLink returns correct format', () {
      expect(validInvite.deepLink, 'fishfeed://join/ABC12345');
    });

    test('isValid returns true for pending invite before expiration', () {
      expect(validInvite.isValid, true);
    });

    test('isValid returns false for expired invite', () {
      final expiredInvite = FamilyInvite(
        id: 'invite-2',
        aquariumId: 'aquarium-1',
        inviteCode: 'XYZ98765',
        createdBy: 'user-1',
        createdAt: now.subtract(const Duration(hours: 50)),
        expiresAt: now.subtract(const Duration(hours: 2)),
        status: FamilyInviteStatus.pending,
      );
      expect(expiredInvite.isValid, false);
    });

    test('isValid returns false for accepted invite', () {
      final acceptedInvite = validInvite.copyWith(
        status: FamilyInviteStatus.accepted,
      );
      expect(acceptedInvite.isValid, false);
    });

    test('isValid returns false for cancelled invite', () {
      final cancelledInvite = validInvite.copyWith(
        status: FamilyInviteStatus.cancelled,
      );
      expect(cancelledInvite.isValid, false);
    });

    test('remainingTime returns positive duration for valid invite', () {
      expect(validInvite.remainingTime.isNegative, false);
      expect(validInvite.remainingTime.inHours, greaterThanOrEqualTo(47));
    });

    test('remainingTime returns zero for expired invite', () {
      final expiredInvite = FamilyInvite(
        id: 'invite-3',
        aquariumId: 'aquarium-1',
        inviteCode: 'EXP00000',
        createdBy: 'user-1',
        createdAt: now.subtract(const Duration(hours: 50)),
        expiresAt: now.subtract(const Duration(hours: 2)),
        status: FamilyInviteStatus.pending,
      );
      expect(expiredInvite.remainingTime, Duration.zero);
    });

    test('copyWith creates copy with updated fields', () {
      final updated = validInvite.copyWith(
        status: FamilyInviteStatus.accepted,
        acceptedBy: 'user-2',
        acceptedAt: now,
      );

      expect(updated.id, validInvite.id);
      expect(updated.aquariumId, validInvite.aquariumId);
      expect(updated.inviteCode, validInvite.inviteCode);
      expect(updated.status, FamilyInviteStatus.accepted);
      expect(updated.acceptedBy, 'user-2');
      expect(updated.acceptedAt, now);
    });

    test('equality works correctly', () {
      final copy = FamilyInvite(
        id: 'invite-1',
        aquariumId: 'aquarium-1',
        inviteCode: 'ABC12345',
        createdBy: 'user-1',
        createdAt: validInvite.createdAt,
        expiresAt: validInvite.expiresAt,
        status: FamilyInviteStatus.pending,
      );

      expect(validInvite, equals(copy));
    });

    test('different invites are not equal', () {
      final different = validInvite.copyWith(id: 'invite-different');
      expect(validInvite, isNot(equals(different)));
    });
  });

  group('FamilyInviteStatus', () {
    test('has all expected values', () {
      expect(FamilyInviteStatus.values, [
        FamilyInviteStatus.pending,
        FamilyInviteStatus.accepted,
        FamilyInviteStatus.expired,
        FamilyInviteStatus.cancelled,
      ]);
    });
  });
}
