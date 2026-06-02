// Quick Shoot shortcut — the home-screen launcher shortcut that jumps straight
// into the custom camera, bound to one chosen moment.
//
// Two persisted pieces of state, both in shared_preferences:
//   • enabled flag  (camera_shortcut_enabled)  — off by default (Bug #1).
//   • bound moment  (quick_shoot_moment_*)      — code + denormalized name.
//
// The OS shortcut is registered via quick_actions. Its label is
// "Quick Shoot — {moment name}" so the user can see, on long-press of the app
// icon, exactly where shots will land. Enabling without a bound moment leaves
// no shortcut (the settings screen blocks that path); changing the moment while
// enabled re-labels the shortcut.
//
// On Android, quick_actions exposes items via long-press on the app icon
// (Android 7.1+). Some launchers (Nova, Pixel) let the user drag these onto the
// home screen for a true pinned shortcut.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kEnabledKey = 'camera_shortcut_enabled';
const _kMomentCodeKey = 'quick_shoot_moment_code';
const _kMomentNameKey = 'quick_shoot_moment_name';

// Off by default — users must intentionally turn the shortcut on (Bug #1).
const _kDefaultEnabled = false;

/// App shortcut type id — retained for the (dormant) quick-action launch hook
/// in app.dart. Quick Shoot now uses a *pinned* home-screen icon instead of a
/// dynamic (long-press) shortcut, so this store no longer creates dynamic ones.
const String kCameraShortcutType = 'capture_camera';

/// One moment bound to the Quick Shoot shortcut. [name] is denormalized so the
/// shortcut label and settings UI can render offline without resolving the code.
class QuickShootBinding {
  const QuickShootBinding({required this.code, required this.name});

  final String code;
  final String name;
}

// ── Enabled flag ───────────────────────────────────────────────────────────

class CameraShortcutNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kEnabledKey) ?? _kDefaultEnabled;
  }

  /// Persist the enabled flag. The actual home-screen icon is pinned separately
  /// via [ShortcutRepository] (a pinned shortcut can't be re-created silently on
  /// every launch — it needs the user's one-time "Add to Home screen" consent).
  Future<void> set(bool enabled) async {
    state = AsyncValue.data(enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabledKey, enabled);
  }
}

final cameraShortcutProvider =
    AsyncNotifierProvider<CameraShortcutNotifier, bool>(
  CameraShortcutNotifier.new,
);

// ── Bound moment ─────────────────────────────────────────────────────────────

class QuickShootBindingNotifier extends AsyncNotifier<QuickShootBinding?> {
  @override
  Future<QuickShootBinding?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kMomentCodeKey);
    final name = prefs.getString(_kMomentNameKey);
    if (code == null || name == null) return null;
    return QuickShootBinding(code: code, name: name);
  }

  /// Bind [code]/[name] as the Quick Shoot destination.
  Future<void> bind(String code, String name) async {
    state = AsyncValue.data(QuickShootBinding(code: code, name: name));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kMomentCodeKey, code);
    await prefs.setString(_kMomentNameKey, name);
  }

  /// Drop the binding (e.g. the moment was deleted).
  Future<void> clear() async {
    state = const AsyncValue.data(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kMomentCodeKey);
    await prefs.remove(_kMomentNameKey);
  }
}

final quickShootBindingProvider =
    AsyncNotifierProvider<QuickShootBindingNotifier, QuickShootBinding?>(
  QuickShootBindingNotifier.new,
);

/// Flipped to true when the user launches the app via the Quick Shoot shortcut.
/// The splash consumes this to route straight to the custom camera; the tab
/// shell clears it after triggering, so the trigger fires once per launch.
class CameraShortcutLaunchNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final cameraShortcutLaunchProvider =
    NotifierProvider<CameraShortcutLaunchNotifier, bool>(
  CameraShortcutLaunchNotifier.new,
);

/// The moment code a pinned-icon **cold start** delivered, awaiting consumption
/// by the splash (which routes to /home then pushes the camera over it, so the
/// camera survives the splash's own navigation). Null when not launched via the
/// pinned icon. Warm-start taps navigate directly and don't use this.
class PendingShortcutMomentNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? code) => state = code;
}

final pendingShortcutMomentProvider =
    NotifierProvider<PendingShortcutMomentNotifier, String?>(
  PendingShortcutMomentNotifier.new,
);
