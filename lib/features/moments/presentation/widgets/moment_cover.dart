// The auto-generated cover image for a moment. Pulls a vibe-mapped photo from
// the cover catalog and renders it through CachedNetworkImage (so it's cheap
// after first load, even offline). The existing gradient stand-in acts as
// placeholder and error fallback, so the card always looks intentional — never
// a blank white box — while images stream in or if the network is down.
//
// Intentionally just the image fill: the dark legibility wash, title, avatars
// and date pill stay with the calling card so this widget stays reusable for
// any size (full-bleed hero card or 56×56 thumbnail).

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../data/vibe_covers.dart';
import '../../domain/moment.dart';
import 'photo_thumb.dart';

class MomentCover extends StatelessWidget {
  const MomentCover({
    super.key,
    required this.moment,
    this.memCacheWidth,
  });

  final Moment moment;

  /// Decode size for thumbnails — pass roughly the rendered pixel width to
  /// keep memory in check on small tiles (e.g. 96–128 for a 56pt thumbnail
  /// at 2x).
  final int? memCacheWidth;

  @override
  Widget build(BuildContext context) {
    final fallback = DecoratedBox(
      decoration: BoxDecoration(gradient: momentCoverGradient(moment)),
    );
    return CachedNetworkImage(
      imageUrl: coverUrlForMoment(moment),
      fit: BoxFit.cover,
      memCacheWidth: memCacheWidth,
      fadeInDuration: const Duration(milliseconds: 220),
      fadeOutDuration: Duration.zero,
      placeholder: (_, _) => fallback,
      errorWidget: (_, _, _) => fallback,
    );
  }
}
