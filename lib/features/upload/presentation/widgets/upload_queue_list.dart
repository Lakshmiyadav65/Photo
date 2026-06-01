// The vertical upload queue. Rows fade and rise in with a short per-row stagger
// on first paint, so the list assembles itself calmly rather than snapping in.

import 'package:flutter/material.dart';

import '../../domain/upload_item.dart';
import 'upload_progress_row.dart';

class UploadQueueList extends StatelessWidget {
  const UploadQueueList({
    super.key,
    required this.items,
    this.padding = const EdgeInsets.fromLTRB(24, 8, 24, 24),
  });

  final List<UploadItem> items;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      itemCount: items.length,
      itemBuilder: (_, i) => _Entrance(
        index: i,
        child: UploadProgressRow(item: items[i]),
      ),
    );
  }
}

class _Entrance extends StatelessWidget {
  const _Entrance({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 360 + (index.clamp(0, 8) * 60)),
      curve: Curves.easeOutCubic,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 12), child: child),
      ),
      child: child,
    );
  }
}
