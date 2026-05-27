// Placeholder — Phase 5: live photo grid for one moment.
//
// Streams events/<code>/photos ordered by uploadedAt desc. Camera FAB →
// /camera?moment=<code>. Tap photo → /moment/<code>/photo/<pid>.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/placeholder_screen.dart';

class MomentDetailScreen extends StatelessWidget {
  const MomentDetailScreen({super.key, required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Moment · $code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => context.push('/moment/$code/share'),
          ),
          IconButton(
            icon: const Icon(Icons.insights_outlined),
            onPressed: () => context.push('/moment/$code/insights'),
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () => context.push('/moment/$code/settings'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/camera?moment=$code'),
        child: const Icon(Icons.camera_alt),
      ),
      body: PlaceholderScreen(
        title: 'Moment $code',
        todo: 'Phase 5: real-time photo grid streamed from '
            '/events/$code/photos. Tap → fullscreen photo viewer.',
        showBack: false,
      ),
    );
  }
}
