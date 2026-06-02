// Sticky banner above a moment's grid. Five states (spec):
//   idle      → "📤 N photos ready to upload"      [Resume Upload]
//   uploading → "📤 Uploading X of Y · Z%"  bar    [Pause]
//   paused    → "⏸ Paused at X of Y"               [Resume]
//   failed    → "⚠ N photos failed"                [Retry All]
//   complete  → "✓ All Y shared"  (auto-dismiss after 3s)
//
// When there's nothing pending and no active session for this moment, the
// banner renders nothing.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../data/providers/photo_queue_provider.dart';
import '../../data/providers/upload_state_provider.dart';

class UploadProgressBanner extends ConsumerStatefulWidget {
  const UploadProgressBanner({super.key, required this.momentId});

  final String momentId;

  @override
  ConsumerState<UploadProgressBanner> createState() =>
      _UploadProgressBannerState();
}

class _UploadProgressBannerState extends ConsumerState<UploadProgressBanner> {
  Timer? _dismissTimer;

  void _resume() =>
      ref.read(uploadControllerProvider.notifier).start(widget.momentId);

  void _pause() => ref.read(uploadControllerProvider.notifier).pause();

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(uploadControllerProvider);
    final pendingCount = ref.watch(pendingCountProvider(widget.momentId));
    final mine = session.isFor(widget.momentId);

    // Completed → show briefly, then auto-dismiss.
    if (mine && session.phase == UploadPhase.completed) {
      _dismissTimer ??= Timer(const Duration(seconds: 3), () {
        if (mounted) ref.read(uploadControllerProvider.notifier).dismiss();
      });
      return _Bar(
        icon: Icons.check_circle_rounded,
        color: AppTheme.sage,
        label: 'All ${session.total} shared',
      );
    }
    _dismissTimer?.cancel();
    _dismissTimer = null;

    if (mine && session.phase == UploadPhase.uploading) {
      final pct = (session.fraction * 100).round();
      return _Bar(
        icon: Icons.cloud_upload_rounded,
        color: AppTheme.coral,
        label: 'Uploading ${session.uploaded} of ${session.total} · $pct%',
        progress: session.fraction,
        actionLabel: 'Pause',
        onAction: _pause,
      );
    }

    if (mine && session.phase == UploadPhase.paused) {
      return _Bar(
        icon: Icons.pause_circle_rounded,
        color: AppTheme.amber,
        label: 'Paused at ${session.uploaded} of ${session.total}',
        actionLabel: 'Resume',
        onAction: _resume,
      );
    }

    if (mine && session.phase == UploadPhase.failed) {
      return _Bar(
        icon: Icons.warning_amber_rounded,
        color: AppTheme.coralDeep,
        label: '${session.failed} photo${session.failed == 1 ? '' : 's'} failed',
        actionLabel: 'Retry All',
        onAction: _resume,
      );
    }

    // Idle: something is queued but no active session.
    if (pendingCount > 0) {
      return _Bar(
        icon: Icons.cloud_upload_outlined,
        color: AppTheme.coral,
        label: '$pendingCount photo${pendingCount == 1 ? '' : 's'} ready '
            'to upload',
        actionLabel: 'Resume Upload',
        onAction: _resume,
      );
    }

    return const SizedBox.shrink();
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.icon,
    required this.color,
    required this.label,
    this.progress,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color color;
  final String label;
  final double? progress;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppTheme.paper,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (actionLabel != null)
                TextButton(
                  onPressed: onAction,
                  child: Text(
                    actionLabel!,
                    style: AppText.mono(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.coral,
                    ),
                  ),
                ),
            ],
          ),
          if (progress != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, right: 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: AppTheme.cream2,
                  valueColor: const AlwaysStoppedAnimation(AppTheme.coral),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
