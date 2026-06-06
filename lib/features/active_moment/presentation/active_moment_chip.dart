// "Uploading to: <moment> ▼" chip — surfaces the Active Moment on the home
// screen and lets the user switch with a tap. When nothing is set, prompts to
// pick a destination (same picker as the shutter would open).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../data/active_moment_store.dart';
import 'active_moment_picker.dart';

class ActiveMomentChip extends ConsumerWidget {
  const ActiveMomentChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeMomentProvider);
    final hasActive = active != null;

    return Material(
      color: hasActive ? AppTheme.coral.withValues(alpha: 0.08) : AppTheme.paper,
      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showActiveMomentPicker(context),
        splashColor: AppTheme.coral.withValues(alpha: 0.1),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            border: Border.all(
              color: hasActive
                  ? AppTheme.coral.withValues(alpha: 0.35)
                  : AppTheme.line,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.camera_alt_rounded,
                  size: 14,
                  color: hasActive ? AppTheme.coral : AppTheme.muted,
                ),
                const SizedBox(width: 8),
                Text(
                  'UPLOADING TO',
                  style: AppText.label(
                    fontSize: 9.5,
                    color: hasActive ? AppTheme.coralDeep : AppTheme.muted,
                  ),
                ),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    hasActive ? active.title : 'Pick a moment',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.ink,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: hasActive ? AppTheme.ink : AppTheme.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
