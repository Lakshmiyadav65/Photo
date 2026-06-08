// "the moment, in numbers" — moment insights: four stat cards plus a "most
// prolific" contributor ranking. Used both as a bottom sheet (from the gallery)
// and full-screen (the /insights route). Theme-driven, warm, social.

import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/brand.dart';
import '../../../../shared/widgets/gang_avatar.dart';
import '../../domain/moment.dart';
import '../../domain/photo.dart';
import 'sheet_scaffold.dart';

Future<void> showInsightsSheet(
  BuildContext context,
  Moment moment,
  List<Photo> photos,
) {
  return showAppSheet(context, InsightsView(moment: moment, photos: photos));
}

/// Real elapsed span of the roll: earliest → latest shot. '—' until there are
/// at least two timestamped photos to measure between.
String _durationLabel(List<Photo> photos) {
  final times = [
    for (final p in photos)
      if (p.uploadedAt.millisecondsSinceEpoch > 0) p.uploadedAt,
  ]..sort();
  if (times.length < 2) return '—';
  final span = times.last.difference(times.first);
  if (span.inDays >= 1) return '${span.inDays} ${span.inDays == 1 ? 'day' : 'days'}';
  if (span.inHours >= 1) return '${span.inHours} ${span.inHours == 1 ? 'hr' : 'hrs'}';
  if (span.inMinutes >= 1) return '${span.inMinutes} min';
  return '< 1 min';
}

class InsightsView extends StatelessWidget {
  const InsightsView({super.key, required this.moment, required this.photos});

  final Moment moment;
  final List<Photo> photos;

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final p in photos) {
      counts[p.uploader] = (counts[p.uploader] ?? 0) + 1;
    }
    final ranking = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxCount = ranking.isEmpty ? 1 : ranking.first.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: HeroTitle(
                before: 'The moment, in ',
                emphasis: 'numbers',
                fontSize: 24,
              ),
            ),
            _CloseButton(),
          ],
        ),
        const SizedBox(height: 2),
        Text(moment.code, style: AppText.label(fontSize: 11)),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _StatCard(label: 'TOTAL SHOTS', value: '${moment.photoCount}')),
            const SizedBox(width: 12),
            // Real view count (members opening the gallery). The contributor
            // count still reads off the "most prolific" ranking below.
            Expanded(child: _StatCard(label: 'VIEWS', value: '${moment.viewCount}')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StatCard(label: 'MEMBERS', value: '${moment.memberCount}')),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(label: 'DURATION', value: _durationLabel(photos))),
          ],
        ),
        const SizedBox(height: 26),
        Text('MOST PROLIFIC', style: AppText.label(fontSize: 11)),
        const SizedBox(height: 14),
        for (final entry in ranking.take(3))
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _ContributorBar(
              name: entry.key,
              count: entry.value,
              fraction: entry.value / maxCount,
            ),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.paper,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppText.display(fontSize: 26)),
          const SizedBox(height: 4),
          Text(label, style: AppText.label(fontSize: 10)),
        ],
      ),
    );
  }
}

class _ContributorBar extends StatelessWidget {
  const _ContributorBar({
    required this.name,
    required this.count,
    required this.fraction,
  });

  final String name;
  final int count;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GangAvatar(name: name, size: 30),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(name,
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  Text('$count', style: AppText.mono(fontSize: 12)),
                ],
              ),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Stack(
                  children: [
                    Container(height: 6, color: AppTheme.cream2),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: fraction.clamp(0.06, 1.0)),
                      duration: const Duration(milliseconds: 650),
                      curve: Curves.easeOutCubic,
                      builder: (_, value, _) => FractionallySizedBox(
                        widthFactor: value,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppTheme.coral,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CloseButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => Navigator.of(context).maybePop(),
      icon: const Icon(Icons.close_rounded),
      color: AppTheme.muted,
      visualDensity: VisualDensity.compact,
    );
  }
}
