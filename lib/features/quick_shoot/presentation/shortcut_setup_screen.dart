// Placeholder — Phase 7: bind one moment to the home-screen Quick Shoot
// shortcut (Android dynamic shortcut via quick_actions; persisted to
// users/{uid}.quickShootBinding).

import 'package:flutter/material.dart';

import '../../../shared/widgets/placeholder_screen.dart';

class ShortcutSetupScreen extends StatelessWidget {
  const ShortcutSetupScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Quick Shoot setup',
        todo: 'Phase 7: pick a moment to bind to the home-screen shortcut. '
            'Register dynamic shortcut via quick_actions; persist binding.',
      );
}
