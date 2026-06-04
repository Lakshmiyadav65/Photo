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
  });

  final String id;

  /// Display name of the member who uploaded it.
  final String uploader;

  final DateTime uploadedAt;

  final bool favorite;

  /// Remote media URL (Cloudflare R2). Null for legacy gradient-placeholder
  /// tiles; when present, the UI renders the real image.
  final String? url;

  /// Smaller variant for grids; falls back to [url] when null.
  final String? thumbUrl;

  final bool isVideo;

  Photo copyWith({bool? favorite}) => Photo(
        id: id,
        uploader: uploader,
        uploadedAt: uploadedAt,
        favorite: favorite ?? this.favorite,
        url: url,
        thumbUrl: thumbUrl,
        isVideo: isVideo,
      );
}
