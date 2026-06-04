import 'package:flutter_test/flutter_test.dart';
import 'package:gang_roll/features/auth/domain/user_profile.dart';
import 'package:gang_roll/features/gangs/data/models/gang_data.dart';
import 'package:gang_roll/features/moments/data/models/event_data.dart';
import 'package:gang_roll/features/moments/data/models/photo_data.dart';

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
        favorite: true,
        uploadedAt: at,
      );

      final round = PhotoData.fromMap(photo.toMap(), 'p1');
      expect(round.uploaderName, 'Diya');
      expect(round.url, photo.url);
      expect(round.thumbUrl, photo.thumbUrl);
      expect(round.favorite, isTrue);
      expect(round.uploadedAt!.isAtSameMomentAs(at), isTrue);

      final ui = round.toPhoto();
      expect(ui.uploader, 'Diya');
      expect(ui.favorite, isTrue);
      expect(ui.uploadedAt.isAtSameMomentAs(at), isTrue);
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
