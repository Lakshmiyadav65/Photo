// The locked state of a roll's gallery — shown while it's Live (develop-locked).
// No photos are visible (that's the whole point); instead a live countdown to
// the develop time, the shot count, and — for the host — a "Develop now" action.
// Watches [tickerProvider] so the countdown updates every second and the screen
// flips to the revealed grid the instant it develops.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme.dart';
import '../../data/mock_moments.dart';
import '../../domain/moment.dart';

class LockedRollView extends ConsumerWidget {
  const LockedRollView({
    super.key,
    required this.moment,
    this.onDevelopNow,
  });

  final Moment moment;

  /// Non-null only for the host — wires the "Develop now" button.
  final VoidCallback? onDevelopNow;

  static String _countdown(Duration d) {
    if (d.inDays >= 1) {
      final h = d.inHours % 24;
      return '${d.inDays}d ${h}h';
    }
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Rebuild every second so the countdown stays live.
    ref.watch(tickerProvider);
    final left = moment.timeLeft ?? Duration.zero;
    final reveals = moment.endsAt;

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppTheme.amber.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_clock_rounded,
                  size: 34, color: AppTheme.amber),
            ),
            const SizedBox(height: 20),
            Text('DEVELOPING', style: AppText.label(fontSize: 11, color: AppTheme.amber)),
            const SizedBox(height: 12),
            Text(
              _countdown(left),
              style: AppText.mono(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              moment.photoCount == 1
                  ? '1 shot in the roll'
                  : '${moment.photoCount} shots in the roll',
              style: AppText.display(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              reveals == null
                  ? 'The whole gallery reveals at once.'
                  : 'Reveals ${DateFormat('MMM d').format(reveals)} — all at once, like real film.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.muted,
                  ),
            ),
            const SizedBox(height: 28),
            Text(
              'Keep shooting while it’s live — your shots reveal with everyone else’s.',
              textAlign: TextAlign.center,
              style: AppText.label(fontSize: 10.5, color: AppTheme.muted),
            ),
            if (onDevelopNow != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onDevelopNow,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.coral,
                  side: const BorderSide(color: AppTheme.coral),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                ),
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: const Text('Develop now'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
