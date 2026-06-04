import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/gang.dart';
import '../models/gang_data.dart';

/// Data boundary for gangs (personal, owner-private member groupings). The
/// Firebase-backed implementation is wired in `main.dart`.
abstract class GangsRepository {
  /// The signed-in user's gangs, newest first.
  Stream<List<Gang>> watchMyGangs(String uid);

  /// Create a gang from a hand-picked set of members.
  Future<Gang> createGang({
    required String ownerId,
    required String name,
    required List<GangMember> members,
  });

  Future<void> setMuted({required String gangId, required bool muted});

  Future<void> deleteGang(String gangId);
}

/// Overridden in `main.dart` once Firebase is initialised.
final gangsRepositoryProvider = Provider<GangsRepository>(
  (_) => throw UnimplementedError(
    'gangsRepositoryProvider must be overridden in main.dart after Firebase init',
  ),
);
