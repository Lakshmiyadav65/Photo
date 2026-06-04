// gang.roll — entry point.
//
//   1. Wrap the app in a Riverpod ProviderScope.
//   2. Attempt Firebase init; gracefully no-op if `flutterfire configure`
//      hasn't been run yet — so the app still runs during scaffolding.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/constants.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/firebase_auth_repository.dart';
import 'features/gangs/data/repositories/firebase_gangs_repository.dart';
import 'features/gangs/data/repositories/gangs_repository.dart';
import 'features/moments/data/repositories/events_repository.dart';
import 'features/moments/data/repositories/firebase_events_repository.dart';
import 'features/moments/data/repositories/firebase_photos_repository.dart';
import 'features/moments/data/repositories/photos_repository.dart';
import 'features/quick_shoot/data/repositories/r2_photo_uploader.dart';
import 'features/quick_shoot/data/repositories/upload_repository.dart';
import 'shared/services/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseStatus = await bootstrapFirebase();

  runApp(
    ProviderScope(
      overrides: [
        firebaseStatusProvider.overrideWithValue(firebaseStatus),
        // Wire the real auth repository only when Firebase actually came up;
        // otherwise the provider keeps throwing (the app still runs in the
        // pre-Firebase mock flow).
        if (firebaseStatus == FirebaseStatus.ready)
          authRepositoryProvider.overrideWithValue(
            FirebaseAuthRepository(
              FirebaseAuth.instance,
              FirebaseFirestore.instance,
            ),
          ),
        if (firebaseStatus == FirebaseStatus.ready)
          eventsRepositoryProvider.overrideWithValue(
            FirebaseEventsRepository(FirebaseFirestore.instance),
          ),
        if (firebaseStatus == FirebaseStatus.ready)
          gangsRepositoryProvider.overrideWithValue(
            FirebaseGangsRepository(FirebaseFirestore.instance),
          ),
        if (firebaseStatus == FirebaseStatus.ready)
          photosRepositoryProvider.overrideWithValue(
            FirebasePhotosRepository(FirebaseFirestore.instance),
          ),
        // Real uploader only once the Worker URL is configured; otherwise the
        // simulated uploader keeps the app usable.
        if (firebaseStatus == FirebaseStatus.ready &&
            AppConstants.r2WorkerBaseUrl.isNotEmpty)
          photoUploaderProvider.overrideWithValue(
            R2PhotoUploader(
              workerBaseUrl: AppConstants.r2WorkerBaseUrl,
              auth: FirebaseAuth.instance,
              photos: FirebasePhotosRepository(FirebaseFirestore.instance),
            ),
          ),
      ],
      child: const GangRollApp(),
    ),
  );
}
