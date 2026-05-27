// Placeholder — Phase 3+: edit display name + avatar (upload to Storage).

import 'package:flutter/material.dart';

import '../../../shared/widgets/placeholder_screen.dart';

class ProfileEditScreen extends StatelessWidget {
  const ProfileEditScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Edit profile',
        todo: 'Phase 3+: name input + avatar picker → update Storage + '
            'denormalized fields across events/<id>/members/<uid> docs.',
      );
}
