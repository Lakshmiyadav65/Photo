// Capture / gallery actions — the single entry points the bottom shutter and
// the moment FAB call into. Both verify the required permission (sending the
// user to the Permissions screen if missing), resolve an Active Moment
// destination (prompting once when none is set), then hand off to the real
// device source via image_picker before showing the upload progress screen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../active_moment/data/active_moment_store.dart';
import '../../active_moment/presentation/active_moment_picker.dart';
import '../../onboarding/data/permissions_store.dart';

final _picker = ImagePicker();

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

/// Camera path. Verifies camera permission, resolves a destination, opens the
/// system camera, then pushes the upload progress screen.
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
  context.push(
    '/upload-progress?moment=$destination',
    extra: <XFile>[file],
  );
}

/// Gallery path. Verifies gallery permission, resolves a destination (or uses
/// the explicit [momentCode] when launched from a moment), opens the system
/// gallery picker, then pushes the upload progress screen.
Future<void> pickFromGallery(
  BuildContext context,
  WidgetRef ref, {
  String? momentCode,
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
  context.push(
    '/upload-progress?moment=$destination',
    extra: files,
  );
}
