// Screen 1 · Gangs — the Search-tab home for the social side of the app. A warm
// editorial "your / Gangs" header, a calm search field, and the frequent-gangs
// list as soft pressable cards. Reads as part of the memory-sharing ecosystem,
// not a separate section. Shown as the /search tab (no back) and pushable from
// the profile (with back).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme.dart';
import '../data/mock_gangs.dart';
import '../domain/gang.dart';
import 'widgets/gang_card.dart';
import 'widgets/gang_search_bar.dart';
import 'widgets/section_label.dart';

class GangsScreen extends ConsumerStatefulWidget {
  const GangsScreen({super.key, this.showBack = false});

  final bool showBack;

  @override
  ConsumerState<GangsScreen> createState() => _GangsScreenState();
}

class _GangsScreenState extends ConsumerState<GangsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Gang> _filter(List<Gang> gangs) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return gangs;
    return gangs.where((g) => g.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final gangs = _filter(ref.watch(gangsProvider));
    final hasQuery = _query.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            _Header(
              showBack: widget.showBack,
              onBack: () => context.pop(),
              onCreate: () => context.push('/create-gang'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
              child: GangSearchBar(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
              child: SectionLabel(
                label: hasQuery ? 'RESULTS' : 'FREQUENT GANGS',
                trailing: Text(
                  '${gangs.length}',
                  style: AppText.mono(fontSize: 11, color: AppTheme.muted),
                ),
              ),
            ),
            if (gangs.isEmpty)
              _EmptyState(query: _query)
            else
              for (final g in gangs)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: GangCard(
                    gang: g,
                    onTap: () => context.push('/gang/${g.id}'),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.showBack,
    required this.onBack,
    required this.onCreate,
  });

  final bool showBack;
  final VoidCallback onBack;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, showBack ? 6 : 18, 24, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBack)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GestureDetector(
                onTap: onBack,
                behavior: HitTestBehavior.opaque,
                child: const Icon(Icons.arrow_back_rounded, color: AppTheme.ink),
              ),
            ),
          Text(
            'Your',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: AppTheme.muted,
            ),
          ),
          const SizedBox(height: 2),
          // Title row — heading on the left, paper-pill "+" on the right that
          // opens the Create Gang flow. Uses the same hairline-border + cream
          // surface language as the moment_detail "ADD" pill so it reads as
          // native, not a Material FAB.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text('Gangs', style: AppText.display(fontSize: 34)),
              ),
              const SizedBox(width: 12),
              _NewGangButton(onTap: onCreate),
            ],
          ),
        ],
      ),
    );
  }
}

class _NewGangButton extends StatelessWidget {
  const _NewGangButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.paper,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: AppTheme.coral.withValues(alpha: 0.1),
        child: Ink(
          decoration: const ShapeDecoration(
            shape: CircleBorder(
              side: BorderSide(color: AppTheme.line),
            ),
          ),
          child: const SizedBox(
            width: 40,
            height: 40,
            child: Icon(Icons.add_rounded, size: 22, color: AppTheme.ink),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.cream2,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.groups_rounded,
                size: 28, color: AppTheme.coral),
          ),
          const SizedBox(height: 18),
          Text(
            query.trim().isEmpty ? 'No gangs yet' : 'No gangs match',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            query.trim().isEmpty
                ? 'Your gangs form from the friends\nyou share moments with.'
                : 'Try a different name.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
