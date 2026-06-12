// First-run permissions — what the app asks for once and remembers. We persist
// only the "user has walked through the screen" flag; the live grant statuses
// come from the OS each time we check, so revocation through Settings is
// detected on the next launch.

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/platform_info.dart';

const _kCompletedKey = 'permissions_setup_completed';
const _kOnboardedKey = 'onboarding_completed';

/// Snapshot of all the permission state the app routes off of.
class PermissionsState {
  const PermissionsState({
    required this.onboarded,
    required this.completed,
    required this.cameraGranted,
    required this.galleryGranted,
  });

  /// User has finished the first-run onboarding (the intro carousel). Once true,
  /// onboarding never shows again — the app goes straight to the dashboard.
  final bool onboarded;

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
    bool? onboarded,
    bool? completed,
    bool? cameraGranted,
    bool? galleryGranted,
  }) =>
      PermissionsState(
        onboarded: onboarded ?? this.onboarded,
        completed: completed ?? this.completed,
        cameraGranted: cameraGranted ?? this.cameraGranted,
        galleryGranted: galleryGranted ?? this.galleryGranted,
      );
}

bool _isGrantedStatus(PermissionStatus s) =>
    s.isGranted || s.isLimited || s.isProvisional;

/// The permission that actually gates gallery access on this device.
///
/// permission_handler's [Permission.photos] auto-reports *granted* on Android
/// below 13 (there's no granular media permission there), which made the
/// gallery card look granted before the user opted in — and indistinguishable
/// from the camera grant. On those devices the real, promptable permission is
/// [Permission.storage] (READ_EXTERNAL_STORAGE). Android 13+ and iOS use
/// [Permission.photos]. A 0/unknown SDK falls back to photos (assume modern).
Future<Permission> _galleryPermission() async {
  if (!Platform.isAndroid) return Permission.photos;
  final sdk = await PlatformInfo.androidSdkInt();
  if (sdk == 0) return Permission.photos;
  return sdk >= 33 ? Permission.photos : Permission.storage;
}

class PermissionsNotifier extends AsyncNotifier<PermissionsState> {
  @override
  Future<PermissionsState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final onboarded = prefs.getBool(_kOnboardedKey) ?? false;
    final completed = prefs.getBool(_kCompletedKey) ?? false;
    final cam = await Permission.camera.status;
    final gal = await (await _galleryPermission()).status;
    return PermissionsState(
      onboarded: onboarded,
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
          onboarded: false,
          completed: false,
          cameraGranted: false,
          galleryGranted: false,
        );
    state = AsyncValue.data(current.copyWith(cameraGranted: granted));
    return granted;
  }

  Future<bool> requestGallery() async {
    final status = await (await _galleryPermission()).request();
    final granted = _isGrantedStatus(status);
    final current = state.value ??
        const PermissionsState(
          onboarded: false,
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
    final gal = await (await _galleryPermission()).status;
    final current = state.value ??
        const PermissionsState(
          onboarded: false,
          completed: false,
          cameraGranted: false,
          galleryGranted: false,
        );
    state = AsyncValue.data(current.copyWith(
      cameraGranted: _isGrantedStatus(cam),
      galleryGranted: _isGrantedStatus(gal),
    ));
  }

  /// Mark the onboarding permissions step completed.
  Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kCompletedKey, true);
    final current = state.value ??
        const PermissionsState(
          onboarded: false,
          completed: false,
          cameraGranted: false,
          galleryGranted: false,
        );
    state = AsyncValue.data(current.copyWith(completed: true));
  }

  /// Mark the first-run onboarding (intro carousel) finished. Persisted
  /// immediately so onboarding never shows again on any later launch.
  Future<void> markOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardedKey, true);
    final current = state.value ??
        const PermissionsState(
          onboarded: false,
          completed: false,
          cameraGranted: false,
          galleryGranted: false,
        );
    state = AsyncValue.data(current.copyWith(onboarded: true));
  }
}

final permissionsProvider =
    AsyncNotifierProvider<PermissionsNotifier, PermissionsState>(
  PermissionsNotifier.new,
);
