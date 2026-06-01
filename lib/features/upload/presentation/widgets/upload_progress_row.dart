// One row in the upload queue: real-file thumbnail (or gradient stand-in),
// filename, and a quiet status line. Trailing indicator carries the state —
// a coral progress ring while uploading, a muted sage tick when done (never a
// loud green), a soft hollow ring while pending. Airy, borderless, lightweight.

import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../moments/presentation/widgets/photo_thumb.dart';
import '../../domain/upload_item.dart';

class UploadProgressRow extends StatelessWidget {
  const UploadProgressRow({super.key, required this.item});

  final UploadItem item;

  String get _status => switch (item.status) {
        UploadStatus.done => 'done',
        UploadStatus.uploading =>
          '${(item.progress * 100).round()}%  ·  ${item.sizeMb.toStringAsFixed(1)} MB',
        UploadStatus.pending => 'waiting  ·  ${item.sizeMb.toStringAsFixed(1)} MB',
      };

  @override
  Widget build(BuildContext context) {
    final pending = item.isPending;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          AnimatedOpacity(
            opacity: pending ? 0.55 : 1,
            duration: const Duration(milliseconds: 260),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusChip),
              child: SizedBox(
                width: 46,
                height: 46,
                // Real picks render the file directly; mock items fall back
                // to the shared gradient placeholder.
                child: item.filePath != null
                    ? Image.file(
                        File(item.filePath!),
                        fit: BoxFit.cover,
                        cacheWidth: 132,
                        errorBuilder: (_, _, _) => PhotoThumb(id: item.id),
                      )
                    : PhotoThumb(id: item.id),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.filename,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: pending ? AppTheme.muted : AppTheme.ink,
                      ),
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: AppText.mono(
                    fontSize: 11,
                    color: item.isDone ? AppTheme.sage : AppTheme.muted,
                  ),
                  child: Text(_status),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _StatusIndicator(item: item),
        ],
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({required this.item});

  final UploadItem item;

  @override
  Widget build(BuildContext context) {
    const size = 24.0;
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        switchInCurve: Curves.easeOutBack,
        transitionBuilder: (child, anim) =>
            ScaleTransition(scale: anim, child: child),
        child: switch (item.status) {
          UploadStatus.done => Container(
              key: const ValueKey('done'),
              decoration: BoxDecoration(
                color: AppTheme.sage.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  size: 15, color: AppTheme.sage),
            ),
          UploadStatus.uploading => SizedBox(
              key: const ValueKey('uploading'),
              width: size,
              height: size,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: item.progress.clamp(0.04, 1)),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                builder: (_, value, _) => CircularProgressIndicator(
                  value: value,
                  strokeWidth: 2.4,
                  backgroundColor: AppTheme.cream2,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppTheme.coral),
                  strokeCap: StrokeCap.round,
                ),
              ),
            ),
          UploadStatus.pending => Container(
              key: const ValueKey('pending'),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.line, width: 2),
              ),
            ),
        },
      ),
    );
  }
}
