// Placeholder — Gangs tab (nice-to-have per PRD): frequent friend groups
// derived from overlap in moment memberships.

import 'package:flutter/material.dart';

import '../../../shared/widgets/placeholder_screen.dart';

class GangsScreen extends StatelessWidget {
  const GangsScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Gangs',
        todo: 'v1.x: frequent friend groups derived from membership overlap '
            'across moments. Not in MVP must-have list.',
        showBack: false,
      );
}
