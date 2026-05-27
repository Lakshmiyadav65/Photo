// Placeholder — Phase 4/8: host-only moment settings (rename, archive,
// delete moment, manage members).

import 'package:flutter/material.dart';

import '../../../shared/widgets/placeholder_screen.dart';

class MomentSettingsScreen extends StatelessWidget {
  const MomentSettingsScreen({super.key, required this.code});
  final String code;

  @override
  Widget build(BuildContext context) => PlaceholderScreen(
        title: 'Moment settings · $code',
        todo: 'Phase 4/8: host-only edit (rename, dates, cover) + archive + '
            'remove members. Member view: leave moment.',
      );
}
