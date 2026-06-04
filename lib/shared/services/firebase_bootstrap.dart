// Safe Firebase bootstrap.
//
// Until `flutterfire configure` is run, the generated `firebase_options.dart`
// doesn't exist and calling Firebase.initializeApp() throws. This function
// tries to init lazily and reports the result via [FirebaseStatus] so the app
// still runs (in offline / placeholder mode) before backend wiring.
//
// After `flutterfire configure`, replace the body of [bootstrapFirebase] with:
//
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   return FirebaseStatus.ready;
//
// and uncomment the imports below.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../firebase_options.dart';

enum FirebaseStatus {
  /// Firebase initialised — full feature set available.
  ready,

  /// `flutterfire configure` hasn't been run yet. App still runs in
  /// offline / placeholder mode.
  notConfigured,

  /// Init was attempted but threw. See logs.
  failed,
}

Future<FirebaseStatus> bootstrapFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return FirebaseStatus.ready;
  } catch (e, st) {
    debugPrint('Firebase init failed: $e\n$st');
    return FirebaseStatus.failed;
  }
}

/// Read with `ref.watch(firebaseStatusProvider)` anywhere in the app to
/// branch on whether Firebase is wired up.
final firebaseStatusProvider = Provider<FirebaseStatus>((_) {
  throw UnimplementedError('Override in ProviderScope in main.dart');
});
