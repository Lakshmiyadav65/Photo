// Placeholder — Phase 5: fullscreen pinch-zoom viewer + download to gallery.

import 'package:flutter/material.dart';

import '../../../shared/widgets/placeholder_screen.dart';

class PhotoViewerScreen extends StatelessWidget {
  const PhotoViewerScreen({super.key, required this.code, required this.photoId});
  final String code;
  final String photoId;

  @override
  Widget build(BuildContext context) => PlaceholderScreen(
        title: 'Photo · $photoId',
        todo: 'Phase 5: fullscreen photo_view with pinch zoom; download to '
            'device gallery via image_gallery_saver_plus; show uploader name '
            '+ avatar; favorites toggle.',
      );
}
