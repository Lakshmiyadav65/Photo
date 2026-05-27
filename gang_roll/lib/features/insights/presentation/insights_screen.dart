// Placeholder — Phase 8: per-moment analytics (top shooters, total shots,
// peak day). Computed on-device from /events/<code>/photos.

import 'package:flutter/material.dart';

import '../../../shared/widgets/placeholder_screen.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key, required this.code});
  final String code;

  @override
  Widget build(BuildContext context) => PlaceholderScreen(
        title: 'Insights · $code',
        todo: 'Phase 8: on-device stats — top shooters, total shots, '
            'day-by-day chart, peak day. All from photos subcollection.',
      );
}
