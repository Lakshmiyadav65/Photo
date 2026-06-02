// Capture / gallery actions — the single entry points the bottom shutter and
// the moment FAB call into. Both verify the required permission, resolve a
// destination moment, pull from the device (camera/gallery), then queue the
// picks straight into that moment's photo grid as optimistic `pending` tiles
// and kick off the (stubbed) upload — which animates them grey → colour in
// place. There is NO separate upload screen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../active_moment/data/active_moment_store.dart';
import '../../active_moment/presentation/active_moment_picker.dart';
import '../../moments/data/mock_moments.dart';
import '../../onboarding/data/permissions_store.dart';
import '../../quick_shoot/data/models/pending_photo.dart';
import '../../quick_shoot/data/providers/photo_queue_provider.dart';
import '../../quick_shoot/data/providers/upload_state_provider.dart';
import '../../quick_shoot/data/services/local_storage_service.dart';

final _picker = ImagePicker();
const _uuid = Uuid();
const _storage = LocalStorageService();

/// Resolves which moment a new upload lands in. Returns the Active Moment's
/// code, or — if none is set — opens the picker and returns the user's choice.
/// Null means the user cancelled the picker.
Future<String?> _resolveDestination(
    BuildContext context, WidgetRef ref) async {
  final active = ref.read(activeMomentProvider);
  if (active != null) return active.code;
  if (!context.mounted) return null;
  return showActiveMomentPicker(context);
}

/// Persist [files] into [code]'s queue as `pending`, then start the (stubbed)
/// upload so they animate grey → colour inside the moment grid.
Future<void> _queueAndUpload(
  WidgetRef ref,
  String code,
  List<XFile> files,
) async {
  final momentName = ref.read(momentByCodeProvider(code))?.title ?? code;
  final repo = ref.read(photoQueueRepositoryProvider);
  final baseMs = DateTime.now().millisecondsSinceEpoch;
  for (var i = 0; i < files.length; i++) {
    final capturedAtMs = baseMs + i;
    final saved = await _storage.persist(
      sourcePath: files[i].path,
      momentId: code,
      capturedAtMs: capturedAtMs,
    );
    await repo.insert(PendingPhoto(
      id: _uuid.v4(),
      localPath: saved.localPath,
      momentId: code,
      momentName: momentName,
      status: PendingStatus.pending,
      capturedAt: DateTime.fromMillisecondsSinceEpoch(capturedAtMs),
    ));
  }
  // Auto-upload (stub flips pending → uploaded ~400ms each). Real backend
  // swaps in behind the same PhotoUploader interface.
  // TODO: wire to Firebase/Supabase Storage.
  await ref.read(uploadControllerProvider.notifier).start(code);
}

/// Camera path. Verifies camera permission, resolves a destination, opens the
/// system camera, queues the shot into the moment grid, then shows the moment.
Future<void> captureWithCamera(BuildContext context, WidgetRef ref) async {
  final perms = ref.read(permissionsProvider).value;
  if (perms != null && !perms.cameraGranted) {
    context.push('/permissions');
    return;
  }

  final destination = await _resolveDestination(context, ref);
  if (destination == null || !context.mounted) return;

  final XFile? file = await _picker.pickImage(source: ImageSource.camera);
  if (file == null || !context.mounted) return;

  // Land on the moment so the user watches the upload animate in place.
  context.push('/moment/$destination');
  await _queueAndUpload(ref, destination, [file]);
}

/// Gallery path. Verifies gallery permission, resolves a destination (or uses
/// the explicit [momentCode] when launched from a moment), opens the system
/// gallery picker, then queues the picks into the moment grid.
///
/// [fromMoment] is true when called from inside the moment detail screen — we
/// stay put and let the grid update in place; otherwise we navigate to the
/// moment so the user sees the upload.
Future<void> pickFromGallery(
  BuildContext context,
  WidgetRef ref, {
  String? momentCode,
  bool fromMoment = false,
}) async {
  final perms = ref.read(permissionsProvider).value;
  if (perms != null && !perms.galleryGranted) {
    context.push('/permissions');
    return;
  }

  final destination = momentCode ?? await _resolveDestination(context, ref);
  if (destination == null || !context.mounted) return;

  final List<XFile> files = await _picker.pickMultiImage();
  if (files.isEmpty || !context.mounted) return;

  if (!fromMoment) context.push('/moment/$destination');
  await _queueAndUpload(ref, destination, files);
}
