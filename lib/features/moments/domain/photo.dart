// A single photo in a moment's roll. Frontend uses a gradient placeholder for
// the image (keyed off [id]); real thumbnails arrive with upload (Phase 5).

class Photo {
  const Photo({
    required this.id,
    required this.uploader,
    required this.uploadedAt,
    this.favorite = false,
    this.url,
    this.thumbUrl,
    this.isVideo = false,
    this.eventId,
    this.uploaderId,
    this.storageKey,
    this.thumbStorageKey,
  });

  final String id;

  /// Display name of the member who uploaded it.
  final String uploader;

  final DateTime uploadedAt;

  final bool favorite;

  /// Parent roll's Firestore event id — lets the viewer favorite/delete a photo
  /// even when paging the cross-moment "All Photos" collection. Null for legacy
  /// mock tiles.
  final String? eventId;

  /// Uid of the uploader — used to gate delete to the photo's owner (rules).
  final String? uploaderId;

  /// Remote media URL (Cloudflare R2). Null for legacy gradient-placeholder
  /// tiles; when present, the UI renders the real image.
  final String? url;

  /// Smaller variant for grids; falls back to [url] when null.
  final String? thumbUrl;

  /// R2 object key of the full image — lets the owner's delete also clean up the
  /// stored bytes (out-of-band, via the upload Worker). Null for legacy tiles.
  final String? storageKey;

  /// R2 object key of the grid thumbnail, when one was uploaded.
  final String? thumbStorageKey;

  final bool isVideo;

  Photo copyWith({bool? favorite}) => Photo(
        id: id,
        uploader: uploader,
        uploadedAt: uploadedAt,
        favorite: favorite ?? this.favorite,
        url: url,
        thumbUrl: thumbUrl,
        isVideo: isVideo,
        eventId: eventId,
        uploaderId: uploaderId,
        storageKey: storageKey,
        thumbStorageKey: thumbStorageKey,
      );
}
