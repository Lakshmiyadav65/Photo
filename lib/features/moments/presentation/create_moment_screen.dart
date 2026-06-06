// The "New Moment" creation flow — a 2-step modal: name & dates → invite.
//
// On finish the moment is inserted into MomentsNotifier so the dashboard shows
// it instantly (no refresh, no restart). Covers are auto-derived from the first
// uploaded photo (see momentCoverGradient) rather than picked here. Everything
// is built from the app's design tokens (AppTheme / AppText) so it reads as
// native: serif headings with a coral-italic emphasis, warm surfaces, hairline
// borders, soft press feedback.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme.dart';
import '../../../core/utils/code_generator.dart';
import '../../../shared/widgets/brand.dart';
import '../../auth/data/auth_repository.dart';
import '../data/repositories/events_repository.dart';
import 'widgets/press_card.dart';

// Two steps now: name the moment, then invite. Covers are auto-generated from
// the first uploaded photo (see momentCoverGradient), so there's no cover step.
const int _kStepCount = 2;

const List<(String, String)> _vibes = [
  ('🔥', 'chaotic'),
  ('📼', 'nostalgic'),
  ('🤍', 'wholesome'),
  ('🎬', 'cinematic'),
  ('🌶️', 'wild'),
  ('🌙', 'soft memories'),
];

class CreateMomentScreen extends StatelessWidget {
  const CreateMomentScreen({super.key, this.prefilledMembers = const []});

  /// Names to pre-invite — set when launched from a Gang so its members are
  /// auto-added in step 2.
  final List<String> prefilledMembers;

  @override
  Widget build(BuildContext context) =>
      CreateRollFlow(prefilledMembers: prefilledMembers);
}

class CreateRollFlow extends ConsumerStatefulWidget {
  const CreateRollFlow({super.key, this.prefilledMembers = const []});

  final List<String> prefilledMembers;

  @override
  ConsumerState<CreateRollFlow> createState() => _CreateRollFlowState();
}

class _CreateRollFlowState extends ConsumerState<CreateRollFlow> {
  final _page = PageController();
  final _titleCtrl = TextEditingController();

  int _step = 0;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _vibe;
  late final String _code = CodeGenerator.generate();

  @override
  void initState() {
    super.initState();
    // Rebuild on every keystroke so the bottom Continue toggles enabled/disabled
    // as the title field fills.
    _titleCtrl.addListener(_onTitleChanged);
  }

  void _onTitleChanged() {
    if (mounted) setState(() {});
  }

  bool get _hasTitle => _titleCtrl.text.trim().isNotEmpty;

  @override
  void dispose() {
    _titleCtrl.removeListener(_onTitleChanged);
    _page.dispose();
    _titleCtrl.dispose();
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

  Future<void> _pickDate({required bool isStart}) async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? now)
          : (_endDate ?? _startDate ?? now),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _pickVibe() async {
    FocusScope.of(context).unfocus();
    final chosen = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => _VibeSheet(selected: _vibe),
    );
    if (chosen != null && mounted) setState(() => _vibe = chosen);
  }

  Future<void> _finish() async {
    HapticFeedback.mediumImpact();
    final user = ref.read(authStateProvider).value;
    if (user == null) {
      _toast('Please sign in again.');
      return;
    }
    // Note: invitees join via the code (the create rule seeds only the host),
    // so prefilledMembers from a Gang launch aren't seeded here.
    try {
      await ref.read(eventsRepositoryProvider).createEvent(
            host: user,
            title: _titleCtrl.text.trim(),
            vibe: _vibe,
            code: _code,
          );
      if (mounted) context.pop();
    } catch (_) {
      _toast("Couldn't create the moment. Please try again.");
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _step == _kStepCount - 1;
    // Continue is gated until the user types a name (spec: "Moment Name
    // becomes mandatory"). On the last step it's always tappable.
    final canAdvance = isLast || _hasTitle;
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
                    _StepDetails(
                      titleController: _titleCtrl,
                      startDate: _startDate,
                      endDate: _endDate,
                      vibe: _vibe,
                      onPickStart: () => _pickDate(isStart: true),
                      onPickEnd: () => _pickDate(isStart: false),
                      onPickVibe: _pickVibe,
                    ),
                    _StepInvite(code: _code),
                  ],
                ),
              ),
              _BottomBar(
                label: isLast ? 'Done' : 'Continue',
                enabled: canAdvance,
                onPressed: isLast ? _finish : () => _goTo(_step + 1),
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
                    icon: Icon(
                      isFirst ? Icons.close_rounded : Icons.arrow_back_rounded,
                    ),
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

// ── Step 1 · Name & details ───────────────────────────────────────────────────

class _StepDetails extends StatelessWidget {
  const _StepDetails({
    required this.titleController,
    required this.startDate,
    required this.endDate,
    required this.vibe,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onPickVibe,
  });

  final TextEditingController titleController;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? vibe;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final VoidCallback onPickVibe;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        const HeroTitle(before: 'Name your ', emphasis: 'moment', fontSize: 28),
        const SizedBox(height: 28),
        Text('TITLE', style: AppText.label()),
        const SizedBox(height: 8),
        TextField(
          controller: titleController,
          cursorColor: AppTheme.coral,
          textCapitalization: TextCapitalization.words,
          style: AppText.display(fontSize: 22),
          decoration: const InputDecoration(hintText: 'Goa Trip 2026'),
        ),
        const SizedBox(height: 28),
        Text('DATES', style: AppText.label()),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _DateCard(
                label: 'START',
                value: startDate == null
                    ? 'Add date'
                    : DateFormat('MMM d').format(startDate!),
                placeholder: startDate == null,
                onTap: onPickStart,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DateCard(
                label: 'END',
                value: endDate == null
                    ? 'Optional'
                    : DateFormat('MMM d').format(endDate!),
                placeholder: endDate == null,
                onTap: onPickEnd,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text('VIBE', style: AppText.label()),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: _VibeCapsule(vibe: vibe, onTap: onPickVibe),
        ),
      ],
    );
  }
}

class _DateCard extends StatelessWidget {
  const _DateCard({
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.label(fontSize: 10)),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppText.display(
              fontSize: 16,
              color: placeholder ? AppTheme.muted : AppTheme.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _VibeCapsule extends StatelessWidget {
  const _VibeCapsule({required this.vibe, required this.onTap});

  final String? vibe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final emoji = vibe == null
        ? '✨'
        : _vibes.firstWhere((v) => v.$2 == vibe).$1;
    return PressCard(
      onTap: onTap,
      radius: AppTheme.radiusPill,
      color: AppTheme.cream2,
      border: Border.all(color: AppTheme.line),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 8),
          Text(
            vibe ?? 'Pick a vibe',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _VibeSheet extends StatelessWidget {
  const _VibeSheet({this.selected});

  final String? selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.cream2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const HeroTitle(before: 'Pick a ', emphasis: 'vibe', fontSize: 22),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final (emoji, label) in _vibes)
                  _VibeChip(
                    emoji: emoji,
                    label: label,
                    selected: label == selected,
                    onTap: () => Navigator.of(context).pop(label),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VibeChip extends StatelessWidget {
  const _VibeChip({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressCard(
      onTap: onTap,
      radius: AppTheme.radiusPill,
      color: selected ? AppTheme.coral.withValues(alpha: 0.12) : AppTheme.paper,
      border: Border.all(
        color: selected ? AppTheme.coral : AppTheme.line,
        width: selected ? 1.5 : 1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: selected ? AppTheme.coralDeep : AppTheme.ink,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 2 · Invite ───────────────────────────────────────────────────────────

class _StepInvite extends StatelessWidget {
  const _StepInvite({required this.code});

  final String code;

  String get _link => 'https://gang.roll/join/$code';

  Future<void> _copyCode(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: code));
    HapticFeedback.selectionClick();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Moment code copied')));
    }
  }

  Future<void> _shareLink(BuildContext context) async {
    HapticFeedback.selectionClick();
    final box = context.findRenderObject() as RenderBox?;
    // Native OS share sheet — exposes WhatsApp, Telegram, Instagram, Gmail,
    // Messages and every other installed target. No dedicated app buttons.
    await SharePlus.instance.share(
      ShareParams(
        text: 'Join my gang.roll 📸 $_link',
        subject: 'You\'re invited to a moment on gang.roll',
        sharePositionOrigin:
            box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        const HeroTitle(before: 'Invite your ', emphasis: 'gang', fontSize: 28),
        const SizedBox(height: 24),
        _InviteCodeCard(code: code, onCopy: () => _copyCode(context)),
        const SizedBox(height: 16),
        _QrPanel(data: _link),
        const SizedBox(height: 18),
        _ShareButton(
          icon: Icons.ios_share_rounded,
          label: 'Share link',
          onTap: () => _shareLink(context),
        ),
      ],
    );
  }
}

class _InviteCodeCard extends StatelessWidget {
  const _InviteCodeCard({required this.code, required this.onCopy});

  final String code;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return PressCard(
      onTap: onCopy,
      padding: const EdgeInsets.all(20),
      gradient: const LinearGradient(
        colors: [AppTheme.coral, AppTheme.coralDeep],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      splashColor: Colors.white.withValues(alpha: 0.12),
      boxShadow: const [
        BoxShadow(
          color: AppTheme.softShadow,
          blurRadius: 24,
          offset: Offset(0, 12),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'MOMENT CODE · TAP TO COPY',
                  style: AppText.label(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
              const Icon(Icons.copy_rounded, size: 18, color: Colors.white),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            code,
            style: AppText.mono(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              letterSpacing: 8,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _QrPanel extends StatelessWidget {
  const _QrPanel({required this.data});

  final String data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.paper,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.line),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.softShadow,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: QrImageView(
          data: data,
          version: QrVersions.auto,
          size: 168,
          gapless: true,
          eyeStyle: const QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: AppTheme.ink,
          ),
          dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: AppTheme.ink,
          ),
        ),
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressCard(
      onTap: onTap,
      radius: AppTheme.radiusButton,
      color: AppTheme.paper,
      border: Border.all(color: AppTheme.line),
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppTheme.ink),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
