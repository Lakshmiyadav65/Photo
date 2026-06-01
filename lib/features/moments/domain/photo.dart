// A single photo in a moment's roll. Frontend uses a gradient placeholder for
// the image (keyed off [id]); real thumbnails arrive with upload (Phase 5).

class Photo {
  const Photo({
    required this.id,
    required this.uploader,
    required this.uploadedAt,
    this.favorite = false,
  });

  final String id;

  /// Display name of the member who uploaded it.
  final String uploader;

  final DateTime uploadedAt;

  final bool favorite;

  Photo copyWith({bool? favorite}) => Photo(
        id: id,
        uploader: uploader,
        uploadedAt: uploadedAt,
        favorite: favorite ?? this.favorite,
      );
}
