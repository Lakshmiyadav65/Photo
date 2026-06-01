// First-run permissions — what the app asks for once and remembers. We persist
// only the "user has walked through the screen" flag; the live grant statuses
// come from the OS each time we check, so revocation through Settings is
// detected on the next launch.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kCompletedKey = 'permissions_setup_completed';

/// Snapshot of all the permission state the app routes off of.
class PermissionsState {
  const PermissionsState({
    required this.completed,
    required this.cameraGranted,
    required this.galleryGranted,
  });

  /// User has walked through the onboarding permissions screen at least once.
  final bool completed;

  /// Camera permission is currently granted (or limited).
  final bool cameraGranted;

  /// Gallery / photos permission is currently granted (or limited).
  final bool galleryGranted;

  /// Final gate: dashboard-ready when the user has completed onboarding AND
  /// the OS still has both critical permissions. If either is revoked later,
  /// we surface the Permissions screen on the next launch.
  bool get readyForApp => completed && cameraGranted && galleryGranted;

  PermissionsState copyWith({
    bool? completed,
    bool? cameraGranted,
    bool? galleryGranted,
  }) =>
      PermissionsState(
        completed: completed ?? this.completed,
        cameraGranted: cameraGranted ?? this.cameraGranted,
        galleryGranted: galleryGranted ?? this.galleryGranted,
      );
}

bool _isGrantedStatus(PermissionStatus s) =>
    s.isGranted || s.isLimited || s.isProvisional;

class PermissionsNotifier extends AsyncNotifier<PermissionsState> {
  @override
  Future<PermissionsState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool(_kCompletedKey) ?? false;
    final cam = await Permission.camera.status;
    final gal = await Permission.photos.status;
    return PermissionsState(
      completed: completed,
      cameraGranted: _isGrantedStatus(cam),
      galleryGranted: _isGrantedStatus(gal),
    );
  }

  /// Ask the OS for camera access. Returns the new granted-ness so callers
  /// can react inline.
  Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    final granted = _isGrantedStatus(status);
    final current = state.value ??
        const PermissionsState(
          completed: false,
          cameraGranted: false,
          galleryGranted: false,
        );
    state = AsyncValue.data(current.copyWith(cameraGranted: granted));
    return granted;
  }

  Future<bool> requestGallery() async {
    final status = await Permission.photos.request();
    final granted = _isGrantedStatus(status);
    final current = state.value ??
        const PermissionsState(
          completed: false,
          cameraGranted: false,
          galleryGranted: false,
        );
    state = AsyncValue.data(current.copyWith(galleryGranted: granted));
    return granted;
  }

  /// Re-pull statuses from the OS — used on app resume / splash to detect
  /// revocations made through device Settings.
  Future<void> refresh() async {
    final cam = await Permission.camera.status;
    final gal = await Permission.photos.status;
    final current = state.value ??
        const PermissionsState(
          completed: false,
          cameraGranted: false,
          galleryGranted: false,
        );
    state = AsyncValue.data(current.copyWith(
      cameraGranted: _isGrantedStatus(cam),
      galleryGranted: _isGrantedStatus(gal),
    ));
  }

  /// Mark the onboarding screen as completed. Persisted so we don't show it
  /// again unless permissions get revoked.
  Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kCompletedKey, true);
    final current = state.value ??
        const PermissionsState(
          completed: false,
          cameraGranted: false,
          galleryGranted: false,
        );
    state = AsyncValue.data(current.copyWith(completed: true));
  }
}

final permissionsProvider =
    AsyncNotifierProvider<PermissionsNotifier, PermissionsState>(
  PermissionsNotifier.new,
);
