// Screen 2 · Gang detail — centered gang name, a large layered avatar stack
// (the Hero target from the list), editorial stats, and minimal Moments /
// Members tabs with a thin animated underline. The Moments tab lists shared
// moments and closes with a quiet "start a new moment" CTA. Pushed above the
// shell so the tab bar steps aside, with the app's standard slide transition.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../moments/data/mock_moments.dart';
import '../../moments/domain/moment.dart';
import '../../moments/presentation/widgets/avatar_stack.dart';
import '../data/mock_gangs.dart';
import '../domain/gang.dart';
import 'widgets/gang_card.dart';
import 'widgets/gang_members_list.dart';
import 'widgets/gang_moments_list.dart';

class GangDetailScreen extends ConsumerStatefulWidget {
  const GangDetailScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<GangDetailScreen> createState() => _GangDetailScreenState();
}

class _GangDetailScreenState extends ConsumerState<GangDetailScreen> {
  int _tab = 0;

  void _openMore() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cream,
      builder: (_) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            for (final (icon, label) in const [
              (Icons.person_add_alt_rounded, 'Invite to gang'),
              (Icons.notifications_off_rounded, 'Mute gang'),
              (Icons.logout_rounded, 'Leave gang'),
            ])
              ListTile(
                leading: Icon(icon, color: AppTheme.ink),
                title:
                    Text(label, style: Theme.of(context).textTheme.titleMedium),
                onTap: () => Navigator.of(context).pop(),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gang = ref.watch(gangByIdProvider(widget.id));
    if (gang == null) {
      return Scaffold(
        backgroundColor: AppTheme.cream,
        appBar: AppBar(),
        body: Center(
          child: Text('We couldn’t find that gang.',
              style: Theme.of(context).textTheme.bodyMedium),
        ),
      );
    }

    final moments = [
      for (final code in gang.momentCodes)
        if (mockMomentByCode(code) case final Moment m) m,
    ];

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _DetailHeader(
              name: gang.name,
              onBack: () => context.pop(),
              onMore: _openMore,
            ),
            const SizedBox(height: 6),
            Hero(
              tag: gangAvatarHeroTag(gang.id),
              child: AvatarStack(
                names: gang.members,
                size: 60,
                max: 5,
                borderColor: AppTheme.cream,
              ),
            ),
            const SizedBox(height: 18),
            Text(_statsLine(gang), style: AppText.label(fontSize: 10)),
            const SizedBox(height: 18),
            _GangTabs(
              index: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.012),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: _tab == 0
                    ? GangMomentsList(
                        key: const ValueKey('moments'),
                        moments: moments,
                        onOpenMoment: (m) => context.push('/moment/${m.code}'),
                        // Spec: launching from a Gang auto-adds its members to
                        // the invite step — the primary value of Gangs.
                        onStartMoment: () =>
                            context.push('/create', extra: gang.members),
                      )
                    : GangMembersList(
                        key: const ValueKey('members'),
                        gang: gang,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statsLine(Gang gang) {
    final since = DateFormat('MMM yyyy').format(gang.createdAt).toUpperCase();
    return '${gang.momentCount} MOMENTS · ${gang.peopleCount} MEMBERS · SINCE $since';
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.name,
    required this.onBack,
    required this.onMore,
  });

  final String name;
  final VoidCallback onBack;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppTheme.ink,
          ),
          Expanded(
            child: Center(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.ink,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onMore,
            icon: const Icon(Icons.more_horiz_rounded),
            color: AppTheme.ink,
          ),
        ],
      ),
    );
  }
}

class _GangTabs extends StatelessWidget {
  const _GangTabs({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  static const _labels = ['Moments', 'Members'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < _labels.length; i++) ...[
          if (i > 0) const SizedBox(width: 28),
          _Tab(
            label: _labels[i],
            active: i == index,
            onTap: () => onChanged(i),
          ),
        ],
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: active ? AppTheme.ink : AppTheme.muted,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                ),
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            height: 2,
            width: active ? 20 : 0,
            decoration: BoxDecoration(
              color: AppTheme.coral,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
