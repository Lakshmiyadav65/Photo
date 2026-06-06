// Create Gang flow — 2 steps that match the Create Moment language exactly so
// the modal reads as part of the same family: progress bar + close/back/skip
// header, PageView body, full-width bottom CTA. Members are picked from the
// pool of people the user already shares moments with (spec rule).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/brand.dart';
import '../../../shared/widgets/gang_avatar.dart';
import '../../auth/data/auth_repository.dart';
import '../data/mock_gangs.dart';
import '../data/repositories/gangs_repository.dart';
import 'widgets/section_label.dart';

const int _kStepCount = 2;

class CreateGangScreen extends ConsumerStatefulWidget {
  const CreateGangScreen({super.key});

  @override
  ConsumerState<CreateGangScreen> createState() => _CreateGangScreenState();
}

class _CreateGangScreenState extends ConsumerState<CreateGangScreen> {
  final _page = PageController();
  final _nameCtrl = TextEditingController();
  final _selected = <String>{};
  int _step = 0;

  @override
  void dispose() {
    _page.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _goTo(int step) {
    if (step < 0 || step >= _kStepCount) return;
    FocusScope.of(context).unfocus();
    setState(() => _step = step);
    _page.animateToPage(
      step,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeInOutCubic,
    );
  }

  bool get _canContinue => _nameCtrl.text.trim().isNotEmpty;

  void _toggle(String name) {
    HapticFeedback.selectionClick();
    setState(() {
      _selected.contains(name) ? _selected.remove(name) : _selected.add(name);
    });
  }

  Future<void> _save() async {
    HapticFeedback.mediumImpact();
    final me = ref.read(authStateProvider).value;
    if (me == null) return;
    try {
      await ref.read(gangsRepositoryProvider).createGang(
            ownerId: me.uid,
            name: _nameCtrl.text.trim(),
            memberNames: [_displayNameOf(me), ..._selected],
          );
      if (mounted) context.pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text("Couldn't create the gang.")),
        );
    }
  }

  String _displayNameOf(AuthUser u) =>
      (u.displayName != null && u.displayName!.trim().isNotEmpty)
          ? u.displayName!.trim()
          : u.email.split('@').first;

  @override
  Widget build(BuildContext context) {
    final isLast = _step == _kStepCount - 1;
    final me = ref.watch(authStateProvider).value;
    final currentUser = me == null ? '' : _displayNameOf(me);
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goTo(_step - 1);
      },
      child: Scaffold(
        backgroundColor: AppTheme.cream,
        body: SafeArea(
          child: Column(
            children: [
              _FlowHeader(
                step: _step,
                onClose: () => context.pop(),
                onBack: () => _goTo(_step - 1),
              ),
              Expanded(
                child: PageView(
                  controller: _page,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _StepName(
                      controller: _nameCtrl,
                      onChanged: (_) => setState(() {}),
                    ),
                    _StepMembers(
                      currentUser: currentUser,
                      selected: _selected,
                      onToggle: _toggle,
                    ),
                  ],
                ),
              ),
              _BottomBar(
                label: isLast
                    ? 'Save gang'
                    : 'Continue',
                enabled: isLast ? true : _canContinue,
                onPressed: isLast ? _save : () => _goTo(_step + 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Flow chrome ────────────────────────────────────────────────────────────

class _FlowHeader extends StatelessWidget {
  const _FlowHeader({
    required this.step,
    required this.onClose,
    required this.onBack,
  });

  final int step;
  final VoidCallback onClose;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final isFirst = step == 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Column(
        children: [
          Row(
            children: [
              for (var i = 0; i < _kStepCount; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    height: 3,
                    decoration: BoxDecoration(
                      color: i <= step ? AppTheme.coral : AppTheme.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 56,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: isFirst ? onClose : onBack,
                    icon: Icon(isFirst
                        ? Icons.close_rounded
                        : Icons.arrow_back_rounded),
                    color: AppTheme.ink,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'STEP ${step + 1} OF $_kStepCount',
                    style: AppText.label(fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(width: 56),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
      child: FilledButton(
        onPressed: enabled ? onPressed : null,
        child: Text(label),
      ),
    );
  }
}

// ── Step 1 · Name ──────────────────────────────────────────────────────────

class _StepName extends StatelessWidget {
  const _StepName({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        const HeroTitle(
          before: 'Name your ',
          emphasis: 'gang',
          fontSize: 28,
        ),
        const SizedBox(height: 6),
        Text(
          'A reusable group you can spin into new moments later.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 28),
        Text('NAME', style: AppText.label()),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          cursorColor: AppTheme.coral,
          textCapitalization: TextCapitalization.words,
          style: AppText.display(fontSize: 22),
          decoration: const InputDecoration(hintText: 'College crew'),
        ),
      ],
    );
  }
}

// ── Step 2 · Members ───────────────────────────────────────────────────────

class _StepMembers extends ConsumerWidget {
  const _StepMembers({
    required this.currentUser,
    required this.selected,
    required this.onToggle,
  });

  final String currentUser;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = ref.watch(availableMembersProvider(currentUser));
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        const HeroTitle(
          before: 'Who\'s in this ',
          emphasis: 'gang?',
          fontSize: 28,
        ),
        const SizedBox(height: 6),
        Text(
          'Pick from people you already share moments with.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        SectionLabel(
          label: 'FROM YOUR MOMENTS',
          trailing: Text(
            selected.isEmpty ? '${available.length}' : '${selected.length} picked',
            style: AppText.mono(fontSize: 11, color: AppTheme.muted),
          ),
        ),
        const SizedBox(height: 10),
        if (available.isEmpty)
          _Empty()
        else
          for (final name in available)
            _MemberRow(
              name: name,
              selected: selected.contains(name),
              onTap: () => onToggle(name),
            ),
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            GangAvatar(name: name, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Text(name,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selected ? AppTheme.coral : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppTheme.coral : AppTheme.line,
                  width: 1.5,
                ),
              ),
              child: AnimatedOpacity(
                opacity: selected ? 1 : 0,
                duration: const Duration(milliseconds: 150),
                child:
                    const Icon(Icons.check_rounded, size: 14, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.cream2,
              borderRadius: BorderRadius.circular(16),
            ),
            child:
                const Icon(Icons.groups_rounded, size: 24, color: AppTheme.coral),
          ),
          const SizedBox(height: 14),
          Text('No shared people yet',
              style: AppText.display(fontSize: 17)),
          const SizedBox(height: 4),
          Text(
            'Join or create a moment with friends, then\nspin them into a gang from here.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
