// A photo captured by the Quick Shoot camera, persisted in the local
// `pending_photos` table and (for now) uploaded only when the user explicitly
// taps Resume. Maps 1:1 to a DB row via [fromRow] / [toRow].

/// Lifecycle of a queued photo. `cancelled` rows are kept in the DB (and the
/// file stays on device) but never re-enter the upload queue.
enum PendingStatus { pending, uploading, uploaded, failed, cancelled }

PendingStatus _statusFrom(String raw) => PendingStatus.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => PendingStatus.pending,
    );

class PendingPhoto {
  const PendingPhoto({
    required this.id,
    required this.localPath,
    required this.momentId,
    required this.momentName,
    required this.status,
    required this.capturedAt,
    this.uploadedAt,
    this.remoteUrl,
    this.retryCount = 0,
    this.errorMessage,
  });

  final String id; // UUID
  final String localPath; // file on device (app dir copy used for display)
  final String momentId; // moment code/id this photo uploads to
  final String momentName; // denormalized for offline display
  final PendingStatus status;
  final DateTime capturedAt;
  final DateTime? uploadedAt;
  final String? remoteUrl; // populated after a successful upload
  final int retryCount;
  final String? errorMessage;

  bool get isPending => status == PendingStatus.pending;
  bool get isUploading => status == PendingStatus.uploading;
  bool get isUploaded => status == PendingStatus.uploaded;
  bool get isFailed => status == PendingStatus.failed;

  /// Rows that should appear in the moment view as not-yet-shared.
  bool get isOutstanding =>
      status == PendingStatus.pending ||
      status == PendingStatus.uploading ||
      status == PendingStatus.failed;

  factory PendingPhoto.fromRow(Map<String, Object?> row) => PendingPhoto(
        id: row['id'] as String,
        localPath: row['local_path'] as String,
        momentId: row['moment_id'] as String,
        momentName: row['moment_name'] as String,
        status: _statusFrom(row['status'] as String),
        capturedAt:
            DateTime.fromMillisecondsSinceEpoch(row['captured_at'] as int),
        uploadedAt: row['uploaded_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(row['uploaded_at'] as int),
        remoteUrl: row['remote_url'] as String?,
        retryCount: (row['retry_count'] as int?) ?? 0,
        errorMessage: row['error_message'] as String?,
      );

  Map<String, Object?> toRow() => {
        'id': id,
        'local_path': localPath,
        'moment_id': momentId,
        'moment_name': momentName,
        'status': status.name,
        'captured_at': capturedAt.millisecondsSinceEpoch,
        'uploaded_at': uploadedAt?.millisecondsSinceEpoch,
        'remote_url': remoteUrl,
        'retry_count': retryCount,
        'error_message': errorMessage,
      };

  PendingPhoto copyWith({
    PendingStatus? status,
    DateTime? uploadedAt,
    String? remoteUrl,
    int? retryCount,
    String? errorMessage,
  }) =>
      PendingPhoto(
        id: id,
        localPath: localPath,
        momentId: momentId,
        momentName: momentName,
        status: status ?? this.status,
        capturedAt: capturedAt,
        uploadedAt: uploadedAt ?? this.uploadedAt,
        remoteUrl: remoteUrl ?? this.remoteUrl,
        retryCount: retryCount ?? this.retryCount,
        errorMessage: errorMessage,
      );
}
