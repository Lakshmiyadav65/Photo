// App settings. Phase 8 will flesh this out (notification toggles, appearance,
// storage, privacy); for now it hosts the Updates section — the manual surface
// for checking GitHub Releases and the home of any "no updates" / error state.

import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../updates/presentation/updates_settings_section.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4),
            child: Text('UPDATES', style: AppText.label(fontSize: 11)),
          ),
          const UpdatesSettingsSection(),
          const SizedBox(height: 28),

          // Remaining settings groups land in Phase 8.
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'Notifications, appearance, storage and privacy controls are '
              'coming soon.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
