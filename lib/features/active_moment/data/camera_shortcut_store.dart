// Camera Shortcut preference + system shortcut sync. Enabling registers an
// app shortcut (long-press on the launcher icon) so the user can jump
// straight into the camera; disabling clears it. On launch via the shortcut,
// [cameraShortcutLaunchProvider] is flipped to true so the splash routes
// directly to the camera flow.
//
// Note on Android: quick_actions exposes items via long-press on the app icon
// (Android 7.1+). Some launchers (Nova, Pixel Launcher) let the user drag
// these onto the home screen for a true pinned shortcut.
//
//   ON (user enabled): tap shutter → camera (uses Active Moment if set, else
//                      prompts once).
//   OFF (default): tap shutter → "Take photo / Upload from gallery" sheet.
//
// Persisted via shared_preferences so the choice survives restarts.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kPrefsKey = 'camera_shortcut_enabled';
// Off by default — users must intentionally turn the shortcut on during
// onboarding (or from Profile later). Persists once toggled.
const _kDefault = false;

/// App shortcut type id — matches what the handler in app.dart listens for.
const String kCameraShortcutType = 'capture_camera';

final _quickActions = const QuickActions();

Future<void> _setSystemShortcut(bool enabled) async {
  try {
    if (enabled) {
      await _quickActions.setShortcutItems(const [
        ShortcutItem(
          type: kCameraShortcutType,
          localizedTitle: 'Camera',
          // Uses the app's launcher icon; OS scales to the shortcut size.
          icon: 'ic_launcher',
        ),
      ]);
    } else {
      await _quickActions.clearShortcutItems();
    }
  } catch (_) {
    // Best-effort — some platforms / launchers don't support quick actions.
  }
}

class CameraShortcutNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_kPrefsKey) ?? _kDefault;
    // Keep the OS shortcut state in sync with the persisted preference on
    // every cold start, so toggles set in a previous session still hold.
    await _setSystemShortcut(enabled);
    return enabled;
  }

  Future<void> set(bool enabled) async {
    state = AsyncValue.data(enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPrefsKey, enabled);
    await _setSystemShortcut(enabled);
  }
}

final cameraShortcutProvider =
    AsyncNotifierProvider<CameraShortcutNotifier, bool>(
  CameraShortcutNotifier.new,
);

/// Flipped to true when the user launches the app via the Camera quick action.
/// The splash consumes this to route straight to camera; the tab shell clears
/// it after triggering the shutter, so the trigger fires once per launch.
class CameraShortcutLaunchNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final cameraShortcutLaunchProvider =
    NotifierProvider<CameraShortcutLaunchNotifier, bool>(
  CameraShortcutLaunchNotifier.new,
);
