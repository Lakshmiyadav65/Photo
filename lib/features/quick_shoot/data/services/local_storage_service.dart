// Persists a freshly-captured Quick Shoot photo in two places:
//
//   1. An app-owned directory (Documents/gang_roll_pending/) — the stable
//      `local_path` the queue + `Image.file()` thumbnails read from. This copy
//      is never auto-deleted, so a captured photo survives even if the user
//      clears it from the device gallery.
//   2. The device gallery (album "gang.roll") via image_gallery_saver_plus, so
//      the shot shows up in the user's Photos app like a normal camera capture.
//
// We DO NOT compress or modify the photo here — originals are saved full
// quality. Compression happens only at upload time (see upload_repository).
//
// Note on Android scoped storage (API 29+): the exact on-disk folder is chosen
// by MediaStore; passing the album name is best-effort. The spec's
// "Pictures/gang.roll/" is the album the OS groups these under.

import 'dart:io';

import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class SavedCapture {
  const SavedCapture({required this.localPath, required this.savedToGallery});

  /// App-owned copy used as the queue's `local_path`.
  final String localPath;

  /// Whether the gallery write reported success (best-effort).
  final bool savedToGallery;
}

class LocalStorageService {
  const LocalStorageService();

  /// Album / folder name shown in the device gallery.
  static const albumName = 'gang.roll';
  static const _pendingDirName = 'gang_roll_pending';

  /// Copy [sourcePath] (the camera's temp file) into app storage and register a
  /// copy in the device gallery. Returns the stable local path for the queue.
  Future<SavedCapture> persist({
    required String sourcePath,
    required String momentId,
    required int capturedAtMs,
  }) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, _pendingDirName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final fileName = 'gangroll_${momentId}_$capturedAtMs.jpg';
    final destPath = p.join(dir.path, fileName);
    await File(sourcePath).copy(destPath);

    var savedToGallery = false;
    try {
      final result = await ImageGallerySaverPlus.saveFile(
        destPath,
        name: p.basenameWithoutExtension(fileName),
      );
      // Plugin returns a Map like {isSuccess: true, filePath: ...}.
      if (result is Map && result['isSuccess'] == true) {
        savedToGallery = true;
      }
    } catch (_) {
      // Gallery write is best-effort — the app-owned copy is the source of
      // truth for the upload queue, so a failure here doesn't lose the photo.
    }

    return SavedCapture(localPath: destPath, savedToGallery: savedToGallery);
  }
}
