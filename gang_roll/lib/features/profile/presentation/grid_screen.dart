// Grid tab — every developed photo across the user's rolls, in one mosaic.
// Frontend uses gradient stand-in tiles; Phase 5 swaps in cached_network_image.

import 'package:flutter/material.dart';

import '../../../app/theme.dart';

class GridScreen extends StatelessWidget {
  const GridScreen({super.key});

  // Warm film palettes — stand-ins for developed photos.
  static const _palettes = [
    [AppTheme.coral, Color(0xFF7A3E2D)],
    [Color(0xFF2A4A5A), Color(0xFF1A3A4A)],
    [AppTheme.amber, Color(0xFFC87534)],
    [AppTheme.sage, Color(0xFF5A6F50)],
    [Color(0xFF7A3E2D), Color(0xFF5A2E1D)],
    [Color(0xFF1A3A4A), AppTheme.amber],
  ];

  @override
  Widget build(BuildContext context) {
    const tileCount = 24;
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
                    Text('$tileCount FRAMES', style: AppText.label()),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final colors = _palettes[i % _palettes.length];
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          colors: colors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    );
                  },
                  childCount: tileCount,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
