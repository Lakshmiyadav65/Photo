// Bottom sheet that asks the user to pick (or switch) the Active Moment — the
// destination for the camera shutter and quick uploads. Reuses the shared
// SheetScaffold + PressCard language so it reads as native.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/brand.dart';
import '../../moments/data/mock_moments.dart';
import '../../moments/domain/moment.dart';
import '../../moments/presentation/widgets/moment_cover.dart';
import '../../moments/presentation/widgets/press_card.dart';
import '../../moments/presentation/widgets/sheet_scaffold.dart';
import '../data/active_moment_store.dart';

/// Opens the picker. Resolves to the chosen code (already saved) or null if
/// the user dismissed without picking.
Future<String?> showActiveMomentPicker(BuildContext context) {
  return showAppSheet<String>(context, const _ActiveMomentPickerView());
}

class _ActiveMomentPickerView extends ConsumerWidget {
  const _ActiveMomentPickerView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moments = ref.watch(visibleMomentsProvider);
    final activeCode = ref.watch(activeMomentCodeProvider).value;

    if (moments.isEmpty) {
      return _Empty();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const HeroTitle(
          before: 'where to ',
          emphasis: 'upload?',
          fontSize: 24,
        ),
        const SizedBox(height: 4),
        Text(
          "we'll remember your pick — switch anytime from the home chip.",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        for (final m in moments)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _MomentRow(
              moment: m,
              selected: m.code == activeCode,
              onTap: () async {
                await ref
                    .read(activeMomentCodeProvider.notifier)
                    .setActive(m.code);
                if (context.mounted) Navigator.of(context).pop(m.code);
              },
            ),
          ),
      ],
    );
  }
}

class _MomentRow extends StatelessWidget {
  const _MomentRow({
    required this.moment,
    required this.selected,
    required this.onTap,
  });

  final Moment moment;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      border: Border.all(
        color: selected ? AppTheme.coral : AppTheme.line,
        width: selected ? 1.6 : 1,
      ),
      boxShadow: selected
          ? const [
              BoxShadow(
                color: AppTheme.softShadow,
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ]
          : null,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusChip),
            child: SizedBox(
              width: 48,
              height: 48,
              child: MomentCover(moment: moment, memCacheWidth: 140),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  moment.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.display(fontSize: 16),
                ),
                const SizedBox(height: 3),
                Text(
                  '${moment.memberCount} MEMBERS · ${moment.photoCount} SHOTS',
                  style: AppText.label(fontSize: 10),
                ),
              ],
            ),
          ),
          if (selected)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.check_circle_rounded,
                  color: AppTheme.coral, size: 22),
            ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const HeroTitle(
          before: 'no moments ',
          emphasis: 'yet',
          fontSize: 22,
        ),
        const SizedBox(height: 6),
        Text(
          'create or join a moment first, then come back here.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
