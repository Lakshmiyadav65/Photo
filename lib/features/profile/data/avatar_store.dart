// Local avatar store — the user's chosen profile photo.
//
// firebase_storage was removed from this project (Kotlin/AGP incompatibility,
// see pubspec), so there is no remote bucket to upload an avatar to yet. We
// keep the avatar fully local instead:
//
//   1. The picked image (already downscaled by image_picker) is copied into an
//      app-owned `avatar/` directory so it survives the source being deleted.
//   2. The stable path is persisted in shared_preferences.
//
// Every copy uses a fresh filename so `Image.file`'s path-keyed cache never
// serves a stale avatar after a change. When a remote bucket lands later, this
// store is the single place to also push `photoUrl` to users/{uid}.

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kAvatarPathKey = 'user_avatar_path';
const _avatarDirName = 'avatar';

class AvatarNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_kAvatarPathKey);
    if (path == null) return null;
    // Guard against a stale pref pointing at a file that's since been removed.
    return await File(path).exists() ? path : null;
  }

  /// Copy [sourcePath] into app storage as the user's avatar and persist it.
  Future<void> setFromFile(String sourcePath) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, _avatarDirName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final ext = p.extension(sourcePath).isEmpty ? '.jpg' : p.extension(sourcePath);
    final dest = p.join(
      dir.path,
      'avatar_${DateTime.now().millisecondsSinceEpoch}$ext',
    );
    await File(sourcePath).copy(dest);

    final prefs = await SharedPreferences.getInstance();
    final old = prefs.getString(_kAvatarPathKey);
    await prefs.setString(_kAvatarPathKey, dest);
    state = AsyncValue.data(dest);

    // Best-effort cleanup of the previous avatar so the dir doesn't grow.
    if (old != null && old != dest) {
      try {
        await File(old).delete();
      } catch (_) {/* already gone — fine */}
    }
  }

  /// Drop the avatar, reverting to the generated initials avatar.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    final old = prefs.getString(_kAvatarPathKey);
    await prefs.remove(_kAvatarPathKey);
    state = const AsyncValue.data(null);
    if (old != null) {
      try {
        await File(old).delete();
      } catch (_) {/* already gone — fine */}
    }
  }
}

/// The current user's avatar image path (null → use the generated avatar).
final userAvatarProvider = AsyncNotifierProvider<AvatarNotifier, String?>(
  AvatarNotifier.new,
);
