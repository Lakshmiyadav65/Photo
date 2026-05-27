// Placeholder — Phase 4: members list with roles (host vs member).

import 'package:flutter/material.dart';

import '../../../shared/widgets/placeholder_screen.dart';

class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key, required this.code});
  final String code;

  @override
  Widget build(BuildContext context) => PlaceholderScreen(
        title: 'Members · $code',
        todo: 'Phase 4: list from /events/$code/members with avatar + name + '
            'role pill. Host can remove members.',
      );
}
