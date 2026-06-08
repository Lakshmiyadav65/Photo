import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
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
    required this.db,
    required this.photos,
  });

  /// Deployed Worker base URL, e.g. https://gangroll-r2-uploads.<sub>.workers.dev
  final String workerBaseUrl;
  final FirebaseAuth auth;
  final FirebaseFirestore db;
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

    // The queue stores the roll's share CODE as momentId, but Firestore keys
    // events by an auto-generated doc id. Resolve it by querying my rolls
    // (memberIds arrayContains me — the only events-query the rules allow) and
    // matching the code client-side.
    final code = photo.momentId.toUpperCase();
    final q = await db
        .collection('events')
        .where('memberIds', arrayContains: user.uid)
        .get();
    final match = q.docs.where((d) => (d.data()['code'] as String?) == code);
    if (match.isEmpty) {
      throw StateError('Roll "${photo.momentId}" not found.');
    }
    final eventId = match.first.id;

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
    // A small, separate grid thumbnail so the gallery never pulls full-res bytes.
    // Best-effort: a thumbnail failure must not sink the upload.
    final thumbBytes = await FlutterImageCompress.compressWithFile(
      photo.localPath,
      minWidth: AppConstants.thumbnailDimensionPx,
      minHeight: AppConstants.thumbnailDimensionPx,
      quality: AppConstants.thumbnailJpegQuality,
    );
    onProgress?.call(0.3);

    final client = HttpClient();
    try {
      // 2. Presign via the Worker (verifies the Firebase ID token).
      final idToken = await user.getIdToken();
      final req = await client.postUrl(Uri.parse('$workerBaseUrl/uploads'));
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $idToken');
      req.headers.contentType = ContentType.json;
      req.add(utf8.encode(jsonEncode({
        'eventId': eventId,
        'contentType': 'image/jpeg',
      })));
      final resp = await req.close();
      final body = await resp.transform(utf8.decoder).join();
      if (resp.statusCode != 200) {
        throw HttpException('Upload authorization failed (${resp.statusCode}).');
      }
      final data = jsonDecode(body) as Map<String, dynamic>;
      onProgress?.call(0.5);

      // 3. PUT the full-size bytes straight to R2 via the presigned URL.
      await _putToR2(client, data['uploadUrl'] as String, bytes);
      onProgress?.call(0.8);

      // 3b. PUT the thumbnail to its own presigned URL. If anything goes wrong we
      //     fall back to serving the full image in grids (thumbUrl = publicUrl).
      final publicUrl = data['publicUrl'] as String;
      final thumbUploadUrl = data['thumbUploadUrl'] as String?;
      var thumbUrl = publicUrl;
      String? thumbStorageKey;
      if (thumbBytes != null && thumbUploadUrl != null) {
        try {
          await _putToR2(client, thumbUploadUrl, thumbBytes);
          thumbUrl = (data['thumbUrl'] as String?) ?? publicUrl;
          thumbStorageKey = data['thumbKey'] as String?;
        } catch (_) {
          // Keep the full-image fallback; the photo still works.
        }
      }
      onProgress?.call(0.9);

      // 4. Record metadata + bump the roll's photo count in Firestore.
      await photos.addPhoto(
        eventId: eventId,
        photo: PhotoData(
          id: data['photoId'] as String,
          uploaderId: user.uid,
          uploaderName: _displayName(user),
          url: publicUrl,
          thumbUrl: thumbUrl,
          storageKey: data['key'] as String?,
          thumbStorageKey: thumbStorageKey,
          uploadedAt: DateTime.now(),
        ),
      );
      onProgress?.call(1);
      return publicUrl;
    } finally {
      client.close();
    }
  }

  /// PUT [bytes] to a presigned R2 URL. R2/S3 require Content-Length (they reject
  /// chunked PUTs with 411), so set it explicitly — otherwise dart:io streams the
  /// body chunked. Throws on a non-2xx response.
  Future<void> _putToR2(HttpClient client, String url, List<int> bytes) async {
    final put = await client.putUrl(Uri.parse(url));
    put.headers.contentType = ContentType('image', 'jpeg');
    put.contentLength = bytes.length;
    put.add(bytes);
    final putResp = await put.close();
    await putResp.drain<void>();
    if (putResp.statusCode < 200 || putResp.statusCode >= 300) {
      throw HttpException('Storage upload failed (${putResp.statusCode}).');
    }
  }

  @override
  Future<void> deleteMedia({
    required String eventId,
    required List<String?> keys,
  }) async {
    final user = auth.currentUser;
    final objectKeys = [
      for (final k in keys)
        if (k != null && k.isNotEmpty) k,
    ];
    if (user == null || objectKeys.isEmpty) return;

    final client = HttpClient();
    try {
      final idToken = await user.getIdToken();
      final req = await client.openUrl(
        'DELETE',
        Uri.parse('$workerBaseUrl/uploads'),
      );
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $idToken');
      req.headers.contentType = ContentType.json;
      req.add(utf8.encode(jsonEncode({
        'eventId': eventId,
        'keys': objectKeys,
      })));
      final resp = await req.close();
      await resp.drain<void>();
      // Best-effort: a non-2xx just means the object lingers; never rethrow.
    } finally {
      client.close();
    }
  }

  String _displayName(User u) =>
      (u.displayName != null && u.displayName!.trim().isNotEmpty)
          ? u.displayName!.trim()
          : (u.email ?? 'Friend').split('@').first;
}
