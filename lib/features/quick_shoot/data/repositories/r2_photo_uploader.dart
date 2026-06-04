import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../../../core/constants.dart';
import '../../../moments/data/models/photo_data.dart';
import '../../../moments/data/repositories/photos_repository.dart';
import '../models/pending_photo.dart';
import 'upload_repository.dart';

/// Real [PhotoUploader]: compresses the captured/picked image, asks the
/// Cloudflare Worker for a presigned URL, PUTs the bytes straight to R2 (so they
/// never pass through our backend), then records the photo metadata in Firestore
/// via [PhotosRepository]. Returns the public R2 URL.
class R2PhotoUploader implements PhotoUploader {
  R2PhotoUploader({
    required this.workerBaseUrl,
    required this.auth,
    required this.photos,
  });

  /// Deployed Worker base URL, e.g. https://gangroll-r2-uploads.<sub>.workers.dev
  final String workerBaseUrl;
  final FirebaseAuth auth;
  final PhotosRepository photos;

  @override
  Future<String> upload(
    PendingPhoto photo, {
    void Function(double progress)? onProgress,
  }) async {
    final user = auth.currentUser;
    if (user == null) {
      throw StateError('Not signed in — cannot upload.');
    }
    onProgress?.call(0.1);

    // 1. Compress on-device (per spec: compress at upload, not at capture).
    final bytes = await FlutterImageCompress.compressWithFile(
      photo.localPath,
      minWidth: AppConstants.maxPhotoDimensionPx,
      minHeight: AppConstants.maxPhotoDimensionPx,
      quality: AppConstants.photoJpegQuality,
    );
    if (bytes == null) {
      throw StateError('Could not process the image.');
    }
    onProgress?.call(0.3);

    final client = HttpClient();
    try {
      // 2. Presign via the Worker (verifies the Firebase ID token).
      final idToken = await user.getIdToken();
      final req = await client.postUrl(Uri.parse('$workerBaseUrl/uploads'));
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $idToken');
      req.headers.contentType = ContentType.json;
      req.add(utf8.encode(jsonEncode({
        'eventId': photo.momentId,
        'contentType': 'image/jpeg',
      })));
      final resp = await req.close();
      final body = await resp.transform(utf8.decoder).join();
      if (resp.statusCode != 200) {
        throw HttpException('Upload authorization failed (${resp.statusCode}).');
      }
      final data = jsonDecode(body) as Map<String, dynamic>;
      onProgress?.call(0.5);

      // 3. PUT the bytes straight to R2 via the presigned URL.
      final put = await client.putUrl(Uri.parse(data['uploadUrl'] as String));
      put.headers.contentType = ContentType('image', 'jpeg');
      put.add(bytes);
      final putResp = await put.close();
      await putResp.drain<void>();
      if (putResp.statusCode < 200 || putResp.statusCode >= 300) {
        throw HttpException('Storage upload failed (${putResp.statusCode}).');
      }
      onProgress?.call(0.9);

      // 4. Record metadata + bump the roll's photo count in Firestore.
      final publicUrl = data['publicUrl'] as String;
      await photos.addPhoto(
        eventId: photo.momentId,
        photo: PhotoData(
          id: data['photoId'] as String,
          uploaderId: user.uid,
          uploaderName: _displayName(user),
          url: publicUrl,
          thumbUrl: publicUrl,
          storageKey: data['key'] as String?,
          uploadedAt: DateTime.now(),
        ),
      );
      onProgress?.call(1);
      return publicUrl;
    } finally {
      client.close();
    }
  }

  String _displayName(User u) =>
      (u.displayName != null && u.displayName!.trim().isNotEmpty)
          ? u.displayName!.trim()
          : (u.email ?? 'Friend').split('@').first;
}
