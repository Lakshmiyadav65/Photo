// Gradient stand-in for a photo (keyed off the photo id) until real thumbnails
// land. Shared by the gallery grid and the fullscreen viewer for consistency.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../data/mock_photos.dart';
import '../../domain/moment.dart';

const List<List<Color>> _palettes = [
  [Color(0xFF2A6B8A), Color(0xFF7FB7C9)],
  [Color(0xFF6A4E9C), Color(0xFFD16BA5)],
  [Color(0xFF3A6B4A), Color(0xFF9FBA7E)],
  [Color(0xFF8A3E2D), Color(0xFFE8A547)],
  [Color(0xFF2A4A5A), Color(0xFF5A8A7A)],
  [Color(0xFFC84634), Color(0xFFE8A547)],
  [Color(0xFF454B6B), Color(0xFF8E7CC3)],
  [Color(0xFF1F3A4D), Color(0xFF4E7A8A)],
];

LinearGradient photoGradient(String id) {
  final colors = _palettes[id.hashCode.abs() % _palettes.length];
  return LinearGradient(
    colors: colors,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// A moment's cover gradient — auto-derived from its first uploaded photo,
/// falling back to a default placeholder keyed off the code when the roll has
/// no photos yet. Single source of truth for covers across the app.
LinearGradient momentCoverGradient(Moment m) =>
    photoGradient(momentCoverPhotoId(m) ?? m.code);

class PhotoThumb extends StatelessWidget {
  const PhotoThumb({
    super.key,
    required this.id,
    this.url,
    this.borderRadius,
  });

  final String id;

  /// Remote image URL (R2). When set, the real photo renders; otherwise the
  /// gradient placeholder (keyed off [id]) is shown.
  final String? url;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final gradient = DecoratedBox(
      decoration: BoxDecoration(
        gradient: photoGradient(id),
        borderRadius: borderRadius,
      ),
    );
    if (url == null || url!.isEmpty) return gradient;
    return CachedNetworkImage(
      imageUrl: url!,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (_, _) => gradient,
      errorWidget: (_, _, _) => gradient,
    );
  }
}
