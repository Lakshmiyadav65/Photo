// Home — the hero screen. Greeting + avatar, Create/Join action cards, and the
// list of the user's rolls. Mock data for now (Phase 4 swaps in a Firestore
// stream via momentsProvider). The 5-tab shell provides the bottom bar.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/brand.dart';
import '../../../shared/widgets/gang_avatar.dart';
import '../data/mock_moments.dart';
import 'widgets/moment_card.dart';

// Current user — hardcoded until auth lands. Phase 3 sources this from the
// signed-in user doc.
const _userName = 'Aarav';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moments = ref.watch(momentsProvider);

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const HeroTitle(before: 'Hey, ', emphasis: _userName, fontSize: 26),
                  GangAvatar(
                    name: _userName,
                    onTap: () => context.go('/profile'),
                  ),
                ],
              ),
            ),

            // Action cards
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      coral: true,
                      icon: Icons.add_rounded,
                      title: 'New roll',
                      subtitle: 'Start fresh',
                      onTap: () => context.push('/create'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.qr_code_scanner_rounded,
                      title: 'Join roll',
                      subtitle: 'Enter a code',
                      onTap: () => context.push('/join'),
                    ),
                  ),
                ],
              ),
            ),

            // Section header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('Your rolls', style: AppText.display(fontSize: 20)),
                  Text('${moments.length} ROLLS', style: AppText.label()),
                ],
              ),
            ),

            if (moments.isEmpty)
              const _EmptyRolls()
            else
              for (final m in moments)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: MomentCard(
                    moment: m,
                    onTap: () => context.push('/moment/${m.code}'),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.coral = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool coral;

  @override
  Widget build(BuildContext context) {
    final fg = coral ? Colors.white : AppTheme.ink;
    return Material(
      color: coral ? AppTheme.coral : AppTheme.paper,
      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: coral ? null : Border.all(color: AppTheme.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: coral
                      ? Colors.white.withValues(alpha: 0.18)
                      : AppTheme.cream2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: fg),
              ),
              const SizedBox(height: 14),
              Text(title, style: AppText.display(fontSize: 18, color: fg)),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: coral
                          ? Colors.white.withValues(alpha: 0.85)
                          : AppTheme.muted,
                    ),
              ),
            ],
          ),
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
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppTheme.cream2,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.photo_library_outlined,
                size: 36, color: AppTheme.muted),
          ),
          const SizedBox(height: 20),
          Text('Your first roll is empty.',
              style: AppText.display(fontSize: 22), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'Create a roll or join one with a code to begin.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
