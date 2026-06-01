// Upload Progress — opens after the user picks photos from the device gallery
// or captures one from the camera. Renders the real picks as a live queue with
// a thin coral progress line, a few rows uploading at once with a calm cascade,
// and a "Back to <moment>" CTA when everything lands. Frontend simulates the
// upload via a periodic timer; Phase 5 swaps it for Storage put.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme.dart';
import '../../moments/data/mock_moments.dart';
import '../domain/upload_item.dart';
import 'widgets/upload_queue_list.dart';

/// How many photos upload concurrently — enough to feel lively, few enough to
/// read as an ordered queue.
const int _kConcurrency = 3;

class UploadProgressScreen extends ConsumerStatefulWidget {
  const UploadProgressScreen({
    super.key,
    required this.files,
    required this.momentCode,
    required this.momentTitle,
  });

  /// Real device files (camera capture or gallery pick), in selection order.
  final List<XFile> files;
  final String momentCode;
  final String momentTitle;

  @override
  ConsumerState<UploadProgressScreen> createState() =>
      _UploadProgressScreenState();
}

class _UploadProgressScreenState extends ConsumerState<UploadProgressScreen> {
  late List<UploadItem> _items;
  Timer? _timer;
  bool _complete = false;
  bool _bumped = false;

  @override
  void initState() {
    super.initState();
    _items = [
      for (var i = 0; i < widget.files.length; i++) _itemFor(i, widget.files[i]),
    ];
    if (_items.isNotEmpty) {
      _timer = Timer.periodic(const Duration(milliseconds: 90), (_) => _tick());
    }
  }

  UploadItem _itemFor(int index, XFile file) {
    // Real on-device size — synchronous on mobile via dart:io. Defaults to 0
    // on platforms where the file isn't available (e.g. web blob).
    var sizeMb = 0.0;
    try {
      final bytes = File(file.path).lengthSync();
      sizeMb = bytes / (1024 * 1024);
    } catch (_) {
      // best-effort — leave at 0
    }
    return UploadItem(
      id: file.path,
      filename: file.name,
      sizeMb: sizeMb,
      filePath: file.path,
      status: index < _kConcurrency
          ? UploadStatus.uploading
          : UploadStatus.pending,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    var changed = false;
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (!item.isUploading) continue;
      final next = item.progress + item.speed;
      if (next >= 1) {
        _items[i] = item.copyWith(progress: 1, status: UploadStatus.done);
      } else {
        _items[i] = item.copyWith(progress: next);
      }
      changed = true;
    }

    // Backfill the upload slots from the pending queue, in order.
    var active = _items.where((i) => i.isUploading).length;
    for (var i = 0; i < _items.length && active < _kConcurrency; i++) {
      if (_items[i].isPending) {
        _items[i] = _items[i].copyWith(status: UploadStatus.uploading);
        active++;
        changed = true;
      }
    }

    final allDone = _items.every((i) => i.isDone);
    if (allDone && !_complete) {
      _complete = true;
      _timer?.cancel();
      HapticFeedback.mediumImpact();
      // Bump the moment so the dashboard re-sorts to Recently Active.
      if (!_bumped) {
        _bumped = true;
        ref.read(momentsProvider.notifier).bumpActivity(widget.momentCode);
      }
    }
    if (changed || allDone) setState(() {});
  }

  int get _doneCount => _items.where((i) => i.isDone).length;

  double get _overall => _items.isEmpty
      ? 0
      : _items.map((i) => i.progress).reduce((a, b) => a + b) / _items.length;

  void _onBack() => context.pop();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _ProgressHeader(
              complete: _complete,
              doneCount: _doneCount,
              total: _items.length,
              onBack: _onBack,
            ),
            _ProgressBar(value: _overall),
            Expanded(
              child: _items.isEmpty
                  ? const _EmptyState()
                  : UploadQueueList(items: _items),
            ),
            _CompletionBar(
              visible: _complete,
              momentTitle: widget.momentTitle,
              onDone: _onBack,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.complete,
    required this.doneCount,
    required this.total,
    required this.onBack,
  });

  final bool complete;
  final int doneCount;
  final int total;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppTheme.ink,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: Text(
                    complete ? 'all done' : 'uploading…',
                    key: ValueKey(complete),
                    style: AppText.display(fontSize: 20),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$doneCount OF $total DONE',
                  style: AppText.label(fontSize: 9.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: SizedBox(
          height: 3,
          child: Stack(
            children: [
              const Positioned.fill(child: ColoredBox(color: AppTheme.cream2)),
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOut,
                alignment: Alignment.centerLeft,
                widthFactor: value.clamp(0, 1),
                child: const DecoratedBox(
                  decoration: BoxDecoration(color: AppTheme.coral),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletionBar extends StatelessWidget {
  const _CompletionBar({
    required this.visible,
    required this.momentTitle,
    required this.onDone,
  });

  final bool visible;
  final String momentTitle;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      child: visible
          ? Container(
              decoration: const BoxDecoration(
                color: AppTheme.cream,
                border: Border(top: BorderSide(color: AppTheme.line)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
                  child: Row(
                    children: [
                      const Expanded(child: _DoneLabel()),
                      const SizedBox(width: 12),
                      FilledButton(
                        style: AppTheme.coralButton.copyWith(
                          minimumSize:
                              const WidgetStatePropertyAll(Size(0, 44)),
                          padding: const WidgetStatePropertyAll(
                              EdgeInsets.symmetric(horizontal: 18)),
                        ),
                        onPressed: onDone,
                        child: Text('Back to $momentTitle'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}

class _DoneLabel extends StatelessWidget {
  const _DoneLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppTheme.sage.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, size: 14, color: AppTheme.sage),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            'added to your moment',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.label(fontSize: 11, color: AppTheme.ink),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'no photos to upload',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
