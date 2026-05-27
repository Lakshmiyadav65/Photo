// Placeholder — Phase 4: 3-step create flow (cover → name → invite).
// Generates a 6-letter code (see [CodeGenerator]) and writes the moment doc
// + members subdoc + codes lookup atomically via a Firestore transaction.

import 'package:flutter/material.dart';

import '../../../shared/widgets/placeholder_screen.dart';

class CreateMomentScreen extends StatelessWidget {
  const CreateMomentScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Create a moment',
        todo: 'Phase 4: 3 steps — pick cover → name + dates → show 6-letter '
            'code + QR + share sheet. Atomic Firestore transaction.',
      );
}
