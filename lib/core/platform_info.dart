// Tiny bridge for native platform facts Dart can't read on its own. Currently
// just the Android API level, fetched via the existing MainActivity method
// channel (no extra plugin needed) and cached for the session.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PlatformInfo {
  PlatformInfo._();

  // Reuses MainActivity's channel — see android/.../MainActivity.kt (getSdkInt).
  static const _channel = MethodChannel('gangroll/shortcut');
  static int? _androidSdkInt;

  /// Android API level (e.g. 33 for Android 13), cached after the first call.
  /// Returns 0 on non-Android platforms or if the channel call fails — callers
  /// should treat 0 as "unknown / assume modern".
  static Future<int> androidSdkInt() async {
    if (!Platform.isAndroid) return 0;
    if (_androidSdkInt != null) return _androidSdkInt!;
    try {
      _androidSdkInt = await _channel.invokeMethod<int>('getSdkInt') ?? 0;
    } catch (e) {
      debugPrint('[PlatformInfo] getSdkInt failed: $e');
      _androidSdkInt = 0;
    }
    return _androidSdkInt!;
  }
}
