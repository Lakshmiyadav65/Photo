// Calm, minimal search field — paper surface, hairline border, soft chip radius,
// muted icon + placeholder. No Material outline, no heavy shadow. Reused styling
// from the search field already in the app so it reads as native.

import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

class GangSearchBar extends StatelessWidget {
  const GangSearchBar({
    super.key,
    required this.controller,
    this.hintText = 'search gangs…',
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: AppTheme.paper,
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        border: Border.all(color: AppTheme.line),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 19, color: AppTheme.muted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              cursorColor: AppTheme.coral,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: hintText,
                hintStyle: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: AppTheme.muted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
