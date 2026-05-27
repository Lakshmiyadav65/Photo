// Reusable placeholder for screens that aren't built yet.
// Renders the screen title in the brand display style + a TODO note.

import 'package:flutter/material.dart';

import '../../app/theme.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.todo,
    this.showBack = true,
  });

  final String title;
  final String todo;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: showBack,
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.cream2,
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              ),
              child: Text(
                'PLACEHOLDER',
                style: AppText.label(color: AppTheme.coral),
              ),
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 12),
            Text(todo, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
