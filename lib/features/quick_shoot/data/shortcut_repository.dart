// Dart bridge to the native pinned-shortcut method channel (MainActivity.kt).
//
//   isPinShortcutSupported → does the current launcher support pinning?
//   pinShortcut            → requestPinShortcut; returns a rich result so the
//                            UI can explain failures (ColorOS/MIUI launchers
//                            often reject silently).
//   removeShortcut         → disable pinned + clear dynamic.
//   initialMoment / listen → cold/warm launch of the pinned icon → camera.
//
// Every call logs under "[Shortcut]" so a `flutter logs` / logcat capture shows
// exactly what happened on-device.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Structured outcome of a pin request.
class ShortcutResult {
  const ShortcutResult({
    required this.success,
    required this.reason,
    this.alreadyPinned = false,
    this.path = 'pin',
    this.needsPermissionHint = false,
    this.raw,
  });

  final bool success;
  final String reason;

  /// True when the icon was already pinned and we just re-enabled it (no system
  /// "Add to Home screen?" dialog is shown in that case).
  final bool alreadyPinned;

  /// Which native path ran: 'legacy' (silent OEM broadcast) or 'pin'
  /// (requestPinShortcut, one-tap OS dialog).
  final String path;

  /// Legacy path only: the broadcast is silent + unconfirmable, so the UI
  /// should gently tell the user where to look / how to grant the permission.
  final bool needsPermissionHint;
  final Object? raw;

  bool get isLegacy => path == 'legacy';

  factory ShortcutResult.fromMap(Map<dynamic, dynamic> map) => ShortcutResult(
        success: map['success'] == true,
        reason: (map['reason'] as String?) ?? 'Unknown',
        alreadyPinned: map['alreadyPinned'] == true,
        path: (map['path'] as String?) ?? 'pin',
        needsPermissionHint: map['needsPermissionHint'] == true,
        raw: map,
      );
}

class ShortcutRepository {
  const ShortcutRepository();

  static const _channel = MethodChannel('gangroll/shortcut');

  /// Whether the active launcher supports `requestPinShortcut`. Note: some
  /// ColorOS/MIUI launchers return true here but still drop the request.
  Future<bool> isPinShortcutSupported() async {
    try {
      final ok = await _channel.invokeMethod<bool>('isPinShortcutSupported');
      debugPrint('[Shortcut] isPinShortcutSupported = $ok');
      return ok ?? false;
    } catch (e) {
      debugPrint('[Shortcut] isPinShortcutSupported error: $e');
      return false;
    }
  }

  /// Lowest-friction enable: native picks the path (legacy silent broadcast on
  /// OEM launchers, else requestPinShortcut). Result.path tells which ran.
  Future<ShortcutResult> enableShortcut({
    required String momentId,
    required String momentName,
  }) async {
    try {
      debugPrint('[Shortcut] enableShortcut: $momentId / $momentName');
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'enableShortcut',
        {'momentId': momentId, 'momentName': momentName},
      );
      if (result == null) {
        return const ShortcutResult(
            success: false, reason: 'Native returned null');
      }
      final parsed = ShortcutResult.fromMap(result);
      debugPrint('[Shortcut] enable result: path=${parsed.path} '
          'success=${parsed.success}');
      return parsed;
    } on PlatformException catch (e) {
      return ShortcutResult(success: false, reason: e.message ?? e.code);
    } catch (e) {
      return ShortcutResult(success: false, reason: e.toString());
    }
  }

  /// Request a pinned home-screen icon for [momentName] that deep-launches the
  /// Quick Shoot camera bound to [momentId].
  Future<ShortcutResult> pinShortcut({
    required String momentId,
    required String momentName,
  }) async {
    try {
      debugPrint('[Shortcut] pinShortcut: $momentId / $momentName');
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'pinShortcut',
        {'momentId': momentId, 'momentName': momentName},
      );
      if (result == null) {
        return const ShortcutResult(
            success: false, reason: 'Native returned null');
      }
      final parsed = ShortcutResult.fromMap(result);
      debugPrint(
          '[Shortcut] result: success=${parsed.success}, reason=${parsed.reason}');
      return parsed;
    } on PlatformException catch (e) {
      debugPrint('[Shortcut] PlatformException: ${e.code} ${e.message}');
      return ShortcutResult(success: false, reason: e.message ?? e.code);
    } catch (e) {
      debugPrint('[Shortcut] Unknown error: $e');
      return ShortcutResult(success: false, reason: e.toString());
    }
  }

  /// Disable our pinned shortcuts and clear dynamic ones. Android cannot delete
  /// a pinned icon programmatically — the user removes it manually.
  Future<void> removeShortcut() async {
    try {
      await _channel.invokeMethod('removeShortcut');
    } catch (e) {
      debugPrint('[Shortcut] remove failed: $e');
    }
  }

  /// The moment id the app was cold-launched with via the pinned icon, if any.
  Future<String?> initialMoment() async {
    try {
      return await _channel.invokeMethod<String>('getInitialShortcutMoment');
    } catch (e) {
      debugPrint('[Shortcut] initialMoment error: $e');
      return null;
    }
  }

  /// Registers [onLaunch] for warm-start taps of the pinned icon.
  void listen(void Function(String momentId) onLaunch) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onShortcutLaunch' && call.arguments is String) {
        onLaunch(call.arguments as String);
      }
      return null;
    });
  }
}
