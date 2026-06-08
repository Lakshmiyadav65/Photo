import 'package:flutter_test/flutter_test.dart';
import 'package:gang_roll/features/auth/domain/user_profile.dart';
import 'package:gang_roll/features/gangs/data/models/gang_data.dart';
import 'package:gang_roll/features/moments/data/models/activity_data.dart';
import 'package:gang_roll/features/moments/data/models/event_data.dart';
import 'package:gang_roll/features/moments/data/models/photo_data.dart';
import 'package:gang_roll/features/moments/domain/activity.dart';
import 'package:gang_roll/features/moments/domain/moment.dart';

void main() {
  group('Firestore model mappers round-trip', () {
    test('EventData toMap → fromMap preserves fields and maps to Moment', () {
      final created = DateTime.utc(2026, 1, 1, 10);
      final active = DateTime.utc(2026, 1, 2, 12, 30);
      final event = EventData(
        id: 'evt1',
        title: 'Goa Trip',
        code: 'GOA001',
        hostId: 'u1',
        hostName: 'Aarav',
        members: const [
          EventMember(uid: 'u1', name: 'Aarav', role: 'host'),
          EventMember(uid: 'u2', name: 'Diya'),
        ],
        vibe: 'cinematic',
        photoCount: 3,
        viewCount: 7,
        createdAt: created,
        lastActiveAt: active,
      );

      final round = EventData.fromMap(event.toMap(), 'evt1');
      expect(round.title, 'Goa Trip');
      expect(round.code, 'GOA001');
      expect(round.hostId, 'u1');
      expect(round.memberIds, ['u1', 'u2']);
      expect(round.photoCount, 3);
      expect(round.viewCount, 7);
      expect(round.createdAt!.isAtSameMomentAs(created), isTrue);
      expect(round.lastActiveAt!.isAtSameMomentAs(active), isTrue);

      final moment = round.toMoment();
      expect(moment.memberCount, 2);
      expect(moment.members.first, 'Aarav'); // host ordered first
      expect(moment.hostName, 'Aarav');
      expect(moment.coverUrlOverride, isNull);
    });

    test('endsAt round-trips and drives develop-lock state', () {
      EventData withEnd(DateTime? endsAt) => EventData(
            id: 'e',
            title: 't',
            code: 'C',
            hostId: 'u1',
            hostName: 'A',
            members: const [EventMember(uid: 'u1', name: 'A', role: 'host')],
            endsAt: endsAt,
          );

      // Future endsAt → Live (locked); survives a Firestore round-trip.
      final future = withEnd(DateTime.now().add(const Duration(days: 1)));
      final roundFuture = EventData.fromMap(future.toMap(), 'e');
      expect(roundFuture.endsAt, isNotNull);
      expect(roundFuture.toMoment().state, RollState.live);
      expect(roundFuture.toMoment().isLive, isTrue);

      // Past endsAt → Developed (revealed); developedAt is set.
      final past = withEnd(DateTime.now().subtract(const Duration(days: 1)));
      final moment = EventData.fromMap(past.toMap(), 'e').toMoment();
      expect(moment.state, RollState.developed);
      expect(moment.developedAt, isNotNull);

      // No endsAt → open album, treated as developed (visible), no developedAt.
      final openMoment = withEnd(null).toMoment();
      expect(openMoment.state, RollState.developed);
      expect(openMoment.endsAt, isNull);
      expect(openMoment.developedAt, isNull);
    });

    test('memberIds derives from members', () {
      const event = EventData(
        id: 'e',
        title: 't',
        code: 'C',
        hostId: 'u1',
        hostName: 'A',
        members: [EventMember(uid: 'u1', name: 'A', role: 'host')],
      );
      expect(event.memberIds, ['u1']);
    });

    test('PhotoData round-trips and maps to Photo', () {
      final at = DateTime.utc(2026, 3, 4, 9);
      final photo = PhotoData(
        id: 'p1',
        uploaderId: 'u2',
        uploaderName: 'Diya',
        url: 'https://media.x/events/e/p1.jpg',
        thumbUrl: 'https://media.x/events/e/p1_thumb.jpg',
        storageKey: 'events/e/p1.jpg',
        thumbStorageKey: 'events/e/p1_thumb.jpg',
        favorite: true,
        uploadedAt: at,
      );

      final round = PhotoData.fromMap(photo.toMap(), 'p1');
      expect(round.uploaderName, 'Diya');
      expect(round.url, photo.url);
      expect(round.thumbUrl, photo.thumbUrl);
      expect(round.storageKey, 'events/e/p1.jpg');
      expect(round.thumbStorageKey, 'events/e/p1_thumb.jpg');
      expect(round.favorite, isTrue);
      expect(round.uploadedAt!.isAtSameMomentAs(at), isTrue);

      // Storage keys flow through to the UI type so the owner's delete can clean
      // up the R2 objects.
      final ui = round.toPhoto();
      expect(ui.uploader, 'Diya');
      expect(ui.favorite, isTrue);
      expect(ui.storageKey, 'events/e/p1.jpg');
      expect(ui.thumbStorageKey, 'events/e/p1_thumb.jpg');
      expect(ui.uploadedAt.isAtSameMomentAs(at), isTrue);
    });

    test('ActivityData round-trips and maps to Activity', () {
      final at = DateTime.utc(2026, 4, 5, 14, 20);
      final activity = ActivityData(
        type: ActivityType.uploaded,
        actorId: 'u2',
        actorName: 'Diya',
        at: at,
      );

      final round = ActivityData.toActivity(activity.toMap(), 'a1');
      expect(round.id, 'a1');
      expect(round.type, ActivityType.uploaded);
      expect(round.actorId, 'u2');
      expect(round.actorName, 'Diya');
      expect(round.at.isAtSameMomentAs(at), isTrue);
    });

    test('ActivityData.typeFrom maps known + unknown types', () {
      expect(ActivityData.typeFrom('created'), ActivityType.created);
      expect(ActivityData.typeFrom('joined'), ActivityType.joined);
      expect(ActivityData.typeFrom('uploaded'), ActivityType.uploaded);
      expect(ActivityData.typeFrom('something_new'), ActivityType.unknown);
      expect(ActivityData.typeFrom(null), ActivityType.unknown);
    });

    test('GangData round-trips and maps to Gang', () {
      final created = DateTime.utc(2025, 6, 1);
      final gang = GangData(
        id: 'g1',
        name: 'Goa Gang',
        ownerId: 'u1',
        members: const [
          GangMember(uid: 'u1', name: 'Aarav'),
          GangMember(uid: 'u2', name: 'Diya'),
        ],
        momentCount: 4,
        muted: true,
        createdAt: created,
      );

      final round = GangData.fromMap(gang.toMap(), 'g1');
      expect(round.name, 'Goa Gang');
      expect(round.ownerId, 'u1');
      expect(round.memberIds, ['u1', 'u2']);
      expect(round.momentCount, 4);
      expect(round.muted, isTrue);
      expect(round.createdAt!.isAtSameMomentAs(created), isTrue);

      final ui = round.toGang();
      expect(ui.members, ['Aarav', 'Diya']);
      expect(ui.momentCount, 4);
      expect(ui.muted, isTrue);
    });

    test('UserProfile round-trips', () {
      final created = DateTime.utc(2026, 1, 1);
      final user = UserProfile(
        uid: 'u1',
        displayName: 'Aarav',
        email: 'aarav@example.com',
        photoUrl: 'https://x/a.jpg',
        createdAt: created,
      );

      final round = UserProfile.fromMap(user.toMap(), 'u1');
      expect(round.displayName, 'Aarav');
      expect(round.email, 'aarav@example.com');
      expect(round.photoUrl, 'https://x/a.jpg');
      expect(round.createdAt!.isAtSameMomentAs(created), isTrue);
    });
  });
}
