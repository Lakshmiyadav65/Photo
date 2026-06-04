import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/photo.dart';
import '../models/photo_data.dart';

/// Data boundary for a roll's photos (Firestore metadata docs). The actual byte
/// upload to Cloudflare R2 is performed by a media uploader (media phase);
/// [addPhoto] records the resulting metadata once the bytes are in R2.
abstract class PhotosRepository {
  /// A roll's photos, newest first.
  Stream<List<Photo>> watchPhotos(String eventId);

  /// Record an uploaded photo's metadata (bytes already in R2). Also bumps the
  /// roll's photo count / activity in the same write.
  Future<void> addPhoto({required String eventId, required PhotoData photo});

  Future<void> toggleFavorite({
    required String eventId,
    required String photoId,
    required bool favorite,
  });

  /// Delete a photo's metadata doc. (R2 object cleanup is handled out-of-band.)
  Future<void> deletePhoto({required String eventId, required String photoId});
}

/// Overridden in `main.dart` once Firebase is initialised.
final photosRepositoryProvider = Provider<PhotosRepository>(
  (_) => throw UnimplementedError(
    'photosRepositoryProvider must be overridden in main.dart after Firebase init',
  ),
);
