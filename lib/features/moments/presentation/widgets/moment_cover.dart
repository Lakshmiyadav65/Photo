// The cover image for a moment. Priority:
//   1. host-selected cover  (Moment.coverUrlOverride)
//   2. first uploaded photo (real R2 image, streamed via coverPhotoProvider)
//   3. a name-derived design — a deterministic gradient keyed off the moment's
//      title with its initial — so a brand-new roll reads as intentional and
//      the *name* drives the look until a real photo lands.
//
// Intentionally just the fill: the dark legibility wash, title, avatars and date
// pill stay with the calling card so this stays reusable at any size (full-bleed
// hero or 56×56 thumbnail).

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../data/mock_moments.dart';
import '../../data/mock_photos.dart';
import '../../domain/moment.dart';
import 'photo_thumb.dart';

class MomentCover extends ConsumerWidget {
  const MomentCover({
    super.key,
    required this.moment,
    this.memCacheWidth,
  });

  final Moment moment;

  /// Decode size for thumbnails — pass roughly the rendered pixel width to keep
  /// memory in check on small tiles (e.g. 96–128 for a 56pt thumbnail at 2x).
  final int? memCacheWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fallback = _NameCover(moment: moment);

    // Develop-locked rolls show NO real image — not the auto cover and not a
    // host-set cover (which would otherwise leak a photo). Just the gradient.
    if (!ref.watch(rollDevelopedProvider(moment.code))) return fallback;

    // 1. host override, else 2. first uploaded photo.
    final override = moment.coverUrlOverride;
    final coverUrl = (override != null && override.isNotEmpty)
        ? override
        : ref.watch(coverPhotoProvider(moment.code)).value?.url;

    if (coverUrl == null || coverUrl.isEmpty) return fallback;
    return CachedNetworkImage(
      imageUrl: coverUrl,
      fit: BoxFit.cover,
      memCacheWidth: memCacheWidth,
      fadeInDuration: const Duration(milliseconds: 220),
      fadeOutDuration: Duration.zero,
      placeholder: (_, _) => fallback,
      errorWidget: (_, _, _) => fallback,
    );
  }
}

/// The name-driven placeholder: a gradient derived from the title with its
/// initial as a soft watermark. Scales with the available height so it reads on
/// both a hero card and a tiny thumbnail.
class _NameCover extends StatelessWidget {
  const _NameCover({required this.moment});

  final Moment moment;

  @override
  Widget build(BuildContext context) {
    final title = moment.title.trim();
    final initial = title.isEmpty ? '?' : title.substring(0, 1).toUpperCase();
    return DecoratedBox(
      decoration: BoxDecoration(gradient: momentCoverGradient(moment)),
      child: LayoutBuilder(
        builder: (_, constraints) {
          final size = (constraints.maxHeight.isFinite
                  ? constraints.maxHeight
                  : constraints.maxWidth) *
              0.5;
          return Center(
            child: Text(
              initial,
              style: AppText.display(
                fontSize: size.clamp(20.0, 160.0),
                color: Colors.white.withValues(alpha: 0.32),
              ),
            ),
          );
        },
      ),
    );
  }
}
