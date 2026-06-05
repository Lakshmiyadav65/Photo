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

      // 3. PUT the bytes straight to R2 via the presigned URL.
      // R2/S3 require Content-Length (they reject chunked PUTs with 411), so set
      // it explicitly — otherwise dart:io streams the body chunked.
      final put = await client.putUrl(Uri.parse(data['uploadUrl'] as String));
      put.headers.contentType = ContentType('image', 'jpeg');
      put.contentLength = bytes.length;
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
        eventId: eventId,
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
