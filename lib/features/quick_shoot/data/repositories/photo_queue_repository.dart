// CRUD for the Quick Shoot upload queue (`pending_photos` table).
//
// sqflite has no change-stream, so [watchPendingForMoment] is a lightweight
// broadcast wrapper: every mutation bumps a [_revision] notifier and listeners
// re-query. Good enough for a single-user local queue; swap for a real reactive
// store if this ever grows.

import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../../../../shared/database/app_database.dart';
import '../models/pending_photo.dart';

class PhotoQueueRepository {
  PhotoQueueRepository({AppDatabase? db})
      : _appDb = db ?? AppDatabase.instance;

  final AppDatabase _appDb;

  // Bumped on every write so streams know to re-read.
  static final StreamController<void> _revision =
      StreamController<void>.broadcast();

  Future<Database> get _db => _appDb.database;

  void _notify() {
    if (!_revision.isClosed) _revision.add(null);
  }

  /// Insert a freshly-captured photo as `pending`.
  Future<void> insert(PendingPhoto photo) async {
    final db = await _db;
    await db.insert(
      'pending_photos',
      photo.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _notify();
  }

  /// Photos for a moment that still need attention (pending/uploading/failed),
  /// oldest first — the order they'll upload in.
  Future<List<PendingPhoto>> outstandingForMoment(String momentId) async {
    final db = await _db;
    final rows = await db.query(
      'pending_photos',
      where: "moment_id = ? AND status IN ('pending', 'uploading', 'failed')",
      whereArgs: [momentId],
      orderBy: 'captured_at ASC',
    );
    return rows.map(PendingPhoto.fromRow).toList();
  }

  /// Every non-cancelled local photo for a moment (pending → uploaded), newest
  /// first. Drives the moment grid: outstanding tiles show greyed, uploaded
  /// ones full colour.
  Future<List<PendingPhoto>> allForMoment(String momentId) async {
    final db = await _db;
    final rows = await db.query(
      'pending_photos',
      where: "moment_id = ? AND status != 'cancelled'",
      whereArgs: [momentId],
      orderBy: 'captured_at DESC',
    );
    return rows.map(PendingPhoto.fromRow).toList();
  }

  /// Emits [allForMoment] now and after every mutation.
  Stream<List<PendingPhoto>> watchAllForMoment(String momentId) async* {
    yield await allForMoment(momentId);
    yield* _revision.stream.asyncMap((_) => allForMoment(momentId));
  }

  /// All photos still queued for upload across every moment (used by the
  /// uploader to drain the queue), oldest first.
  Future<List<PendingPhoto>> uploadableForMoment(String momentId) async {
    final db = await _db;
    final rows = await db.query(
      'pending_photos',
      where: "moment_id = ? AND status IN ('pending', 'failed')",
      whereArgs: [momentId],
      orderBy: 'captured_at ASC',
    );
    return rows.map(PendingPhoto.fromRow).toList();
  }

  Future<int> outstandingCount(String momentId) async {
    final db = await _db;
    final r = await db.rawQuery(
      'SELECT COUNT(*) c FROM pending_photos '
      "WHERE moment_id = ? AND status IN ('pending', 'uploading', 'failed')",
      [momentId],
    );
    return Sqflite.firstIntValue(r) ?? 0;
  }

  Future<void> updateStatus(
    String id,
    PendingStatus status, {
    String? remoteUrl,
    DateTime? uploadedAt,
    String? errorMessage,
    int? retryCount,
  }) async {
    final db = await _db;
    await db.update(
      'pending_photos',
      {
        'status': status.name,
        'remote_url': ?remoteUrl,
        if (uploadedAt != null) 'uploaded_at': uploadedAt.millisecondsSinceEpoch,
        'error_message': errorMessage,
        'retry_count': ?retryCount,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    _notify();
  }

  /// Mark cancelled — keeps the row and the on-device file, just removes it from
  /// the queue and the moment view.
  Future<void> cancel(String id) async {
    await updateStatus(id, PendingStatus.cancelled);
  }

  /// Reset a failed/cancelled photo back to `pending` so it re-enters the queue.
  Future<void> retry(String id) async {
    await updateStatus(id, PendingStatus.pending, errorMessage: null);
  }

  /// Emits the outstanding list for [momentId] now and after every mutation.
  Stream<List<PendingPhoto>> watchPendingForMoment(String momentId) async* {
    yield await outstandingForMoment(momentId);
    yield* _revision.stream.asyncMap((_) => outstandingForMoment(momentId));
  }
}
