// Placeholder — Phase 7: in-app camera bound to a moment.
//
// Reads `momentCode` from query (`/camera?moment=<code>`). Quick Shoot
// shortcut routes here directly with the bound moment code.

import 'package:flutter/material.dart';

import '../../../shared/widgets/placeholder_screen.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key, this.momentCode});
  final String? momentCode;

  @override
  Widget build(BuildContext context) => PlaceholderScreen(
        title: 'Camera',
        todo: 'Phase 7: full-screen camera viewfinder. Moment pill at top: '
            '"${momentCode ?? "no moment bound"}". Shutter → '
            'capture → compress (flutter_image_compress, 1920px / 85%) → '
            'upload to Storage + Firestore doc.',
      );
}
