// Screen C — a moment view that surfaces Quick Shoot photos waiting to upload.
//
// Pending shots (grey, 60% opacity) sit above the sticky upload banner; once
// the backend is wired, already-developed photos from Firestore render below
// the "older photos" divider in full colour. Until then this focuses on the
// local pending queue, which is the new surface this feature introduces.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../moments/data/mock_moments.dart';
import '../data/providers/photo_queue_provider.dart';
import 'widgets/pending_photo_tile.dart';
import 'widgets/upload_progress_banner.dart';

class MomentWithPendingScreen extends ConsumerWidget {
  const MomentWithPendingScreen({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moment = ref.watch(momentByCodeProvider(code));
    final pendingAsync = ref.watch(pendingPhotosProvider(code));

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(title: Text(moment?.title ?? 'Moment')),
      body: Column(
        children: [
          UploadProgressBanner(momentId: code),
          Expanded(
            child: pendingAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.coral),
              ),
              error: (e, _) => Center(
                child: Text('Couldn’t load the queue.\n$e',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall),
              ),
              data: (pending) {
                if (pending.isEmpty) {
                  return const _EmptyPending();
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                  ),
                  itemCount: pending.length,
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: PendingPhotoTile(photo: pending[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPending extends StatelessWidget {
  const _EmptyPending();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.photo_camera_back_outlined,
                color: AppTheme.muted, size: 40),
            const SizedBox(height: 14),
            Text('No photos waiting to upload',
                style: AppText.display(fontSize: 18)),
            const SizedBox(height: 6),
            Text(
              'Shots from your Quick Shoot shortcut show up here, ready to share.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
