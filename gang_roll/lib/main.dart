// gang.roll — entry point.
//
//   1. Wrap the app in a Riverpod ProviderScope.
//   2. Attempt Firebase init; gracefully no-op if `flutterfire configure`
//      hasn't been run yet — so the app still runs during scaffolding.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'shared/services/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseStatus = await bootstrapFirebase();

  runApp(
    ProviderScope(
      overrides: [
        firebaseStatusProvider.overrideWithValue(firebaseStatus),
      ],
      child: const GangRollApp(),
    ),
  );
}
