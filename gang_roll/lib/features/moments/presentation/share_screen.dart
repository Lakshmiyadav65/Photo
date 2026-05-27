// Placeholder — Phase 6: QR + 6-letter code + share buttons.

import 'package:flutter/material.dart';

import '../../../shared/widgets/placeholder_screen.dart';

class ShareScreen extends StatelessWidget {
  const ShareScreen({super.key, required this.code});
  final String code;

  @override
  Widget build(BuildContext context) => PlaceholderScreen(
        title: 'Share · $code',
        todo: 'Phase 6: QR code (qr_flutter) for $code + native share sheet '
            '(share_plus) for the gangroll://join/$code deep link.',
      );
}
