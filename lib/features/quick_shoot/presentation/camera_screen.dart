// Quick Shoot — full-screen camera. Reads `momentCode` from query
// (`/camera?moment=<code>`); the on-screen "uploading to" chip reflects the
// Active Moment and lets the user switch destination without leaving the camera.
//
// Frontend stub for Phase 7: real viewfinder + capture + compress + upload
// (camera plugin + flutter_image_compress) lands with the data layer.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../active_moment/presentation/active_moment_chip.dart';

class CameraScreen extends ConsumerWidget {
  const CameraScreen({super.key, this.momentCode});

  /// Pre-bound destination from the route. The Active Moment chip is the live
  /// truth and reflects edits the user makes in-screen.
  final String? momentCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(onClose: () => context.pop()),
            const SizedBox(height: 8),
            // Active Moment selector — only surfaces inside Camera/Upload.
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ActiveMomentChip(),
              ),
            ),
            const Expanded(child: _ViewfinderPlaceholder()),
            const _ShutterRow(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.flash_off_rounded, color: Colors.white),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.flip_camera_ios_rounded,
                color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _ViewfinderPlaceholder extends StatelessWidget {
  const _ViewfinderPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Color(0xFF1A1A1A)),
          child: Center(
            child: Text(
              'viewfinder',
              style: AppText.mono(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.35),
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShutterRow extends StatelessWidget {
  const _ShutterRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: DecoratedBox(
              decoration:
                  BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            ),
          ),
        ),
      ],
    );
  }
}
