// Drives the Quick Shoot upload session: drains a moment's queue one photo at a
// time, honoring Pause (current photo finishes, queue halts) and Resume
// (re-snapshots the queue and continues). A single global session is enough —
// the user uploads from one moment at a time — and [UploadSession.momentId]
// tells the banner which moment it belongs to.
//
// No background work: this only runs while the app is foregrounded and the user
// has tapped Resume (per spec — no foreground service / workmanager).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pending_photo.dart';
import '../repositories/photo_queue_repository.dart';
import '../repositories/upload_repository.dart';
import 'photo_queue_provider.dart';

enum UploadPhase { idle, uploading, paused, completed, failed }

class UploadSession {
  const UploadSession({
    required this.phase,
    required this.momentId,
    required this.uploaded,
    required this.total,
    required this.failed,
  });

  const UploadSession.idle()
      : phase = UploadPhase.idle,
        momentId = null,
        uploaded = 0,
        total = 0,
        failed = 0;

  final UploadPhase phase;
  final String? momentId;
  final int uploaded;
  final int total;
  final int failed;

  double get fraction => total == 0 ? 0 : uploaded / total;

  /// True when this session is the active one for [momentId].
  bool isFor(String momentId) => this.momentId == momentId;

  UploadSession copyWith({
    UploadPhase? phase,
    String? momentId,
    int? uploaded,
    int? total,
    int? failed,
  }) =>
      UploadSession(
        phase: phase ?? this.phase,
        momentId: momentId ?? this.momentId,
        uploaded: uploaded ?? this.uploaded,
        total: total ?? this.total,
        failed: failed ?? this.failed,
      );
}

class UploadController extends Notifier<UploadSession> {
  // Stubbed uploader until Firebase Storage is wired; swap behind the interface.
  final PhotoUploader _uploader = const MockPhotoUploader();

  bool _paused = false;
  bool _running = false;

  @override
  UploadSession build() => const UploadSession.idle();

  PhotoQueueRepository get _queue => ref.read(photoQueueRepositoryProvider);

  /// Begin (or resume) draining [momentId]'s queue. Snapshots the uploadable
  /// rows once so a photo that fails this pass isn't retried in the same run.
  Future<void> start(String momentId) async {
    if (_running) return;
    _running = true;
    _paused = false;

    final batch = await _queue.uploadableForMoment(momentId);
    if (batch.isEmpty) {
      _running = false;
      state = const UploadSession.idle();
      return;
    }

    var uploaded = 0;
    var failed = 0;
    state = UploadSession(
      phase: UploadPhase.uploading,
      momentId: momentId,
      uploaded: 0,
      total: batch.length,
      failed: 0,
    );

    for (final photo in batch) {
      // Pause check happens BEFORE the next photo, so a photo mid-upload always
      // finishes naturally (spec).
      if (_paused) {
        state = state.copyWith(phase: UploadPhase.paused);
        _running = false;
        return;
      }

      await _queue.updateStatus(photo.id, PendingStatus.uploading);
      try {
        final url = await _uploader.upload(photo);
        await _queue.updateStatus(
          photo.id,
          PendingStatus.uploaded,
          remoteUrl: url,
          uploadedAt: DateTime.now(),
        );
        uploaded++;
      } catch (e) {
        await _queue.updateStatus(
          photo.id,
          PendingStatus.failed,
          errorMessage: e.toString(),
          retryCount: photo.retryCount + 1,
        );
        failed++;
      }
      state = state.copyWith(uploaded: uploaded, failed: failed);
    }

    _running = false;
    state = state.copyWith(
      phase: failed > 0 ? UploadPhase.failed : UploadPhase.completed,
    );
  }

  /// Request a pause. Takes effect after the in-flight photo completes.
  void pause() => _paused = true;

  /// Clear a completed/failed/idle banner.
  void dismiss() => state = const UploadSession.idle();
}

final uploadControllerProvider =
    NotifierProvider<UploadController, UploadSession>(UploadController.new);
