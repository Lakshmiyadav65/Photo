// A single photo moving through the upload queue. The image is a real device
// file (when picked via camera/gallery) or a gradient stand-in (mock seeds).
// [progress] is driven by a simulated uploader until Phase 5 wires Storage.

enum UploadStatus { pending, uploading, done }

class UploadItem {
  const UploadItem({
    required this.id,
    required this.filename,
    required this.sizeMb,
    this.filePath,
    this.progress = 0,
    this.status = UploadStatus.pending,
  });

  /// Stable id for the row (file path for real picks, mock seed for demos).
  /// Also seeds the gradient placeholder when [filePath] is null.
  final String id;
  final String filename;
  final double sizeMb;

  /// Real on-device file path. Set when the photo came from the camera or
  /// the gallery picker; null for mock items which fall back to a gradient.
  final String? filePath;

  /// 0–1 upload completion for the [uploading] state.
  final double progress;
  final UploadStatus status;

  bool get isDone => status == UploadStatus.done;
  bool get isUploading => status == UploadStatus.uploading;
  bool get isPending => status == UploadStatus.pending;

  /// Per-tick ramp speed, derived from id so each row fills at its own pace —
  /// gives the queue its natural staggered cascade.
  double get speed => 0.014 + (id.hashCode.abs() % 16) * 0.0016;

  UploadItem copyWith({double? progress, UploadStatus? status}) => UploadItem(
        id: id,
        filename: filename,
        sizeMb: sizeMb,
        filePath: filePath,
        progress: progress ?? this.progress,
        status: status ?? this.status,
      );
}
