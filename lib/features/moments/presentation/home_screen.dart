// Home — the hero screen. Time-based greeting, a coral "new roll" button, and
// the list of the user's rolls as large photo cards. Mock data for now
// (Phase 4 swaps in a Firestore stream via momentsProvider).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/brand.dart';
import '../../auth/data/user_profile_repository.dart';
import '../data/mock_moments.dart';
import 'widgets/moment_card.dart';
import 'widgets/quick_actions.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moments = ref.watch(visibleMomentsProvider);
    // The greeting uses the user's chosen nickname (falls back to the first
    // name, then a friendly default while the profile loads).
    final greetingName =
        ref.watch(currentUserProfileProvider).value?.greetingName ?? 'there';

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            // Greeting — extra top breathing room so it doesn't crowd the
            // status bar. The upload-destination selector lives in the
            // Camera/Upload flows, not here.
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 22),
              child: HeroTitle(
                before: 'Hi, ',
                emphasis: greetingName,
                fontSize: 28,
              ),
            ),

            if (moments.isEmpty)
              const _EmptyRolls()
            else ...[
              QuickActionsSection(
                onNewRoll: () => context.push('/create'),
                onJoinRoll: () => context.push('/join'),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('YOUR MOMENTS', style: AppText.label(fontSize: 11)),
                    Text(
                      '${moments.length}',
                      style: AppText.mono(fontSize: 11, color: AppTheme.muted),
                    ),
                  ],
                ),
              ),
              for (final m in moments)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: MomentCard(
                    moment: m,
                    onTap: () => context.push('/moment/${m.code}'),
                    onInsights: () =>
                        context.push('/moment/${m.code}/insights'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyRolls extends StatelessWidget {
  const _EmptyRolls();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.cream2,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.collections_rounded,
                size: 32, color: AppTheme.coral),
          ),
          const SizedBox(height: 20),
          Text(
            'No moments yet',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first moment or join one\nyour gang has started.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          FilledButton(
            style: AppTheme.coralButton,
            onPressed: () => context.push('/create'),
            child: const Text('Create moment  →'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => context.push('/join'),
            child: const Text('Join with a code'),
          ),
        ],
      ),
    );
  }
}
