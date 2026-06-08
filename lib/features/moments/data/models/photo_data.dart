import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/firestore_helpers.dart';
import '../../domain/photo.dart';

/// The `events/{id}/photos/{photoId}` document — metadata only. The image/video
/// bytes live in Cloudflare R2 at [storageKey], served from [url] (with a
/// smaller [thumbUrl] for grids).
class PhotoData {
  const PhotoData({
    required this.id,
    required this.uploaderId,
    required this.uploaderName,
    required this.url,
    this.thumbUrl,
    this.storageKey,
    this.thumbStorageKey,
    this.isVideo = false,
    this.favorite = false,
    this.uploadedAt,
  });

  final String id;
  final String uploaderId;
  final String uploaderName;
  final String url;
  final String? thumbUrl;

  /// R2 object key of the full image (for out-of-band cleanup on delete).
  final String? storageKey;

  /// R2 object key of the grid thumbnail, when one was uploaded.
  final String? thumbStorageKey;
  final bool isVideo;
  final bool favorite;
  final DateTime? uploadedAt;

  factory PhotoData.fromMap(Map<String, dynamic> data, String id) => PhotoData(
        id: id,
        uploaderId: (data['uploaderId'] ?? '') as String,
        uploaderName: (data['uploaderName'] ?? '') as String,
        url: (data['url'] ?? '') as String,
        thumbUrl: data['thumbUrl'] as String?,
        storageKey: data['storageKey'] as String?,
        thumbStorageKey: data['thumbStorageKey'] as String?,
        isVideo: (data['isVideo'] ?? false) as bool,
        favorite: (data['favorite'] ?? false) as bool,
        uploadedAt: dateFromFirestore(data['uploadedAt']),
      );

  Map<String, dynamic> toMap() => {
        'uploaderId': uploaderId,
        'uploaderName': uploaderName,
        'url': url,
        if (thumbUrl != null) 'thumbUrl': thumbUrl,
        if (storageKey != null) 'storageKey': storageKey,
        if (thumbStorageKey != null) 'thumbStorageKey': thumbStorageKey,
        'isVideo': isVideo,
        'favorite': favorite,
        if (uploadedAt != null) 'uploadedAt': Timestamp.fromDate(uploadedAt!),
      };

  Photo toPhoto({String? eventId}) => Photo(
        id: id,
        uploader: uploaderName,
        uploadedAt: uploadedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        favorite: favorite,
        url: url,
        thumbUrl: thumbUrl ?? url,
        isVideo: isVideo,
        eventId: eventId,
        uploaderId: uploaderId,
        storageKey: storageKey,
        thumbStorageKey: thumbStorageKey,
      );
}
