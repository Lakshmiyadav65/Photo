// A single not-yet-uploaded photo in the moment grid. Shows the on-device
// image dimmed to ~60% with a status badge + caption. Long-press surfaces
// Cancel / Retry. Cancel keeps the file on the device, just drops it from the
// queue (spec).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../data/models/pending_photo.dart';
import '../../data/providers/photo_queue_provider.dart';

class PendingPhotoTile extends ConsumerWidget {
  const PendingPhotoTile({super.key, required this.photo});

  final PendingPhoto photo;

  String get _caption => switch (photo.status) {
        PendingStatus.uploading => 'Uploading…',
        PendingStatus.failed => 'Failed — long-press to retry',
        _ => 'Pending',
      };

  IconData get _badge => switch (photo.status) {
        PendingStatus.uploading => Icons.cloud_upload_rounded,
        PendingStatus.failed => Icons.error_outline_rounded,
        _ => Icons.pause_rounded,
      };

  Future<void> _menu(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(photoQueueRepositoryProvider);
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.paper,
      builder: (_) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (photo.isFailed)
              ListTile(
                leading: const Icon(Icons.refresh_rounded),
                title: const Text('Retry now'),
                onTap: () => Navigator.of(context).pop('retry'),
              ),
            ListTile(
              leading: const Icon(Icons.close_rounded, color: AppTheme.coral),
              title: const Text('Cancel from queue'),
              subtitle: const Text('Stays in your device gallery'),
              onTap: () => Navigator.of(context).pop('cancel'),
            ),
          ],
        ),
      ),
    );
    if (action == 'cancel') await repo.cancel(photo.id);
    if (action == 'retry') await repo.retry(photo.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Uploaded → full colour, no overlay or badge (indistinguishable from a
    // real shared photo). Only the long-press menu is dropped since there's
    // nothing left to cancel/retry.
    if (photo.isUploaded) {
      return Image.file(File(photo.localPath), fit: BoxFit.cover);
    }

    return GestureDetector(
      onLongPress: () => _menu(context, ref),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Dimmed local image.
          Opacity(
            opacity: 0.6,
            child: Image.file(File(photo.localPath), fit: BoxFit.cover),
          ),
          // Animated overlay while uploading — a centered spinner over the
          // dimmed thumbnail; the tile flips to full colour when it completes.
          if (photo.isUploading)
            const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            ),
          // Status badge.
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_badge, size: 14, color: Colors.white),
            ),
          ),
          // Caption.
          Positioned(
            left: 6,
            right: 6,
            bottom: 6,
            child: Text(
              _caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.mono(
                fontSize: 9,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
