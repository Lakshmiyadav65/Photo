// Grid tab — "All photos": every photo across the user's rolls in one mosaic.
// Tiles are the real Photo objects (gradient stand-ins until Phase 5 swaps in
// cached_network_image), so tapping one opens the shared fullscreen viewer
// paging the whole All Photos collection — the same experience as a moment.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../moments/data/mock_photos.dart';
import '../../moments/domain/photo.dart';
import '../../moments/presentation/widgets/photo_thumb.dart';

class GridScreen extends ConsumerWidget {
  const GridScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref.watch(allPhotosProvider);
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 14),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('All photos', style: AppText.display(fontSize: 26)),
                    Text('${photos.length} FRAMES', style: AppText.label()),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _Tile(
                    photo: photos[i],
                    onTap: () => context.push('/photos/all/${photos[i].id}'),
                  ),
                  childCount: photos.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.photo, required this.onTap});

  final Photo photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PhotoThumb(id: photo.id),
            if (photo.favorite)
              const Positioned(
                top: 6,
                right: 6,
                child: Icon(Icons.favorite_rounded,
                    size: 14, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}
