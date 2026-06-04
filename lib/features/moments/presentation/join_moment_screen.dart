// The "Join Roll" flow — two steps: enter the invite code, tap Next, then
// confirm & join. Advancing is always an explicit Next tap (never automatic on
// the 6th character), so joins stay intentional.
//
// Frontend-only: codes are matched against mock moments (mockMomentByCode);
// joining isn't persisted yet (Phase 4). A `prefilledCode` (from a deep link)
// pre-fills the field; the user still taps Next. Built from the app's design
// tokens so it reads as a native extension.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/brand.dart';
import '../../../shared/widgets/gang_avatar.dart';
import '../../auth/data/auth_repository.dart';
import '../data/repositories/events_repository.dart';
import '../domain/moment.dart';
import 'widgets/moment_cover.dart';
import 'widgets/press_card.dart';

const int _kCodeLength = 6;

String _sanitize(String raw) {
  final cleaned = raw.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
  return cleaned.length > _kCodeLength
      ? cleaned.substring(0, _kCodeLength)
      : cleaned;
}

class JoinMomentScreen extends StatelessWidget {
  const JoinMomentScreen({super.key, this.prefilledCode});

  final String? prefilledCode;

  @override
  Widget build(BuildContext context) =>
      JoinRollFlow(prefilledCode: prefilledCode);
}

class JoinRollFlow extends ConsumerStatefulWidget {
  const JoinRollFlow({super.key, this.prefilledCode});

  final String? prefilledCode;

  @override
  ConsumerState<JoinRollFlow> createState() => _JoinRollFlowState();
}

class _JoinRollFlowState extends ConsumerState<JoinRollFlow> {
  final _codeCtrl = TextEditingController();
  final _codeFocus = FocusNode();
  late final PageController _page;

  int _step = 0;
  Moment? _moment;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    // A deep-link code just pre-fills the field — the user still taps Next to
    // advance, so a join is always an intentional action.
    _codeCtrl.text = _sanitize(widget.prefilledCode ?? '');
    _page = PageController();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _codeFocus.dispose();
    _page.dispose();
    super.dispose();
  }

  void _onCodeChanged(String value) {
    // Never auto-advance — only clear a stale error as the user edits.
    if (_error) setState(() => _error = false);
  }

  Future<void> _trySubmit(String code) async {
    final match = await ref.read(eventsRepositoryProvider).lookupByCode(code);
    if (!mounted) return;
    if (match != null) {
      _codeFocus.unfocus();
      setState(() {
        _moment = match;
        _step = 1;
      });
      _page.animateToPage(
        1,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeInOutCubic,
      );
    } else {
      HapticFeedback.heavyImpact();
      setState(() => _error = true);
    }
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final code = _sanitize(data?.text ?? '');
    if (code.isEmpty) return;
    _codeCtrl.value = TextEditingValue(
      text: code,
      selection: TextSelection.collapsed(offset: code.length),
    );
    HapticFeedback.selectionClick();
    _onCodeChanged(code);
  }

  void _scanQr() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('QR scanning uses the camera — coming soon'),
        ),
      );
  }

  void _back() {
    if (_step == 1) {
      setState(() => _step = 0);
      _page.animateToPage(
        0,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
      _codeFocus.requestFocus();
    } else {
      context.pop();
    }
  }

  Future<void> _join() async {
    HapticFeedback.mediumImpact();
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    try {
      await ref
          .read(eventsRepositoryProvider)
          .joinByCode(code: _codeCtrl.text, user: user);
      if (mounted) context.pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text("Couldn't join that moment.")),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: AppTheme.cream,
        body: SafeArea(
          child: Column(
            children: [
              _BackHeader(onBack: _back),
              Expanded(
                child: PageView(
                  controller: _page,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _StepCode(
                      controller: _codeCtrl,
                      focusNode: _codeFocus,
                      error: _error,
                      onChanged: _onCodeChanged,
                      onScan: _scanQr,
                      onPaste: _paste,
                      onNext: _trySubmit,
                    ),
                    if (_moment != null)
                      _StepConfirm(moment: _moment!, onJoin: _join)
                    else
                      const SizedBox.shrink(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackHeader extends StatelessWidget {
  const _BackHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 24, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppTheme.ink,
        ),
      ),
    );
  }
}

// ── Step 1 · Code entry ───────────────────────────────────────────────────────

class _StepCode extends StatelessWidget {
  const _StepCode({
    required this.controller,
    required this.focusNode,
    required this.error,
    required this.onChanged,
    required this.onScan,
    required this.onPaste,
    required this.onNext,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool error;
  final ValueChanged<String> onChanged;
  final VoidCallback onScan;
  final VoidCallback onPaste;
  final ValueChanged<String> onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              const HeroTitle(
                before: 'got an ',
                emphasis: 'invite?',
                fontSize: 28,
              ),
              const SizedBox(height: 6),
              Text(
                'enter the 6-letter code.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              _CodeInput(
                controller: controller,
                focusNode: focusNode,
                error: error,
                onChanged: onChanged,
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                child: error
                    ? Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Text(
                          "we couldn't find a moment with that code.",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.coralDeep),
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
              const SizedBox(height: 28),
              const _OrDivider(),
              const SizedBox(height: 22),
              PressCard(
                onTap: onScan,
                radius: AppTheme.radiusButton,
                border: Border.all(color: AppTheme.line),
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 18,
                      color: AppTheme.ink,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Scan QR code',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: onPaste,
                  child: const Text('Paste from clipboard'),
                ),
              ),
            ],
          ),
        ),
        // Intentional advance: the user must tap Next; the button fades and
        // scales in once all six characters are entered.
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, _) => _NextCta(
              enabled: value.text.length == _kCodeLength,
              onTap: () => onNext(controller.text),
            ),
          ),
        ),
      ],
    );
  }
}

class _NextCta extends StatelessWidget {
  const _NextCta({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !enabled,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.4,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        child: AnimatedScale(
          scale: enabled ? 1 : 0.98,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: FilledButton(
            style: AppTheme.coralButton,
            onPressed: enabled ? onTap : null,
            child: const Text('Next'),
          ),
        ),
      ),
    );
  }
}

class _CodeInput extends StatelessWidget {
  const _CodeInput({
    required this.controller,
    required this.focusNode,
    required this.error,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool error;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (_, value, _) {
            final text = value.text;
            return FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < _kCodeLength; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    _Slot(
                      char: i < text.length ? text[i] : '',
                      active: i == text.length,
                      error: error,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        Positioned.fill(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: true,
            showCursor: false,
            enableInteractiveSelection: false,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            cursorColor: Colors.transparent,
            style: const TextStyle(color: Colors.transparent, height: 0.01),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
              const _UpperCaseFormatter(),
              LengthLimitingTextInputFormatter(_kCodeLength),
            ],
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              counterText: '',
              isCollapsed: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({required this.char, required this.active, required this.error});

  final String char;
  final bool active;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final borderColor = error
        ? AppTheme.coralDeep
        : (active ? AppTheme.coral : AppTheme.line);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      width: 48,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.paper,
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        border: Border.all(color: borderColor, width: active ? 2 : 1.5),
        boxShadow: active
            ? const [
                BoxShadow(
                  color: AppTheme.softShadow,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Text(
        char,
        style: AppText.display(fontSize: 24, color: AppTheme.coral),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppTheme.line, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text('OR', style: AppText.label(fontSize: 10)),
        ),
        const Expanded(child: Divider(color: AppTheme.line, thickness: 1)),
      ],
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  const _UpperCaseFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => TextEditingValue(
    text: newValue.text.toUpperCase(),
    selection: newValue.selection,
  );
}

// ── Step 2 · Confirm & join ───────────────────────────────────────────────────

class _StepConfirm extends StatelessWidget {
  const _StepConfirm({required this.moment, required this.onJoin});

  final Moment moment;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
            children: [
              _CoverCard(moment: moment),
              const SizedBox(height: 22),
              Text('HOSTED BY', style: AppText.label(fontSize: 11)),
              const SizedBox(height: 14),
              _HostRow(moment: moment),
              const SizedBox(height: 22),
              _StatsCard(moment: moment),
            ],
          ),
        ),
        // CTA sits comfortably below the content and above the safe-area inset.
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: _JoinCta(onTap: onJoin),
        ),
      ],
    );
  }
}

class _CoverCard extends StatelessWidget {
  const _CoverCard({required this.moment});

  final Moment moment;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 16 / 11,
        child: Stack(
          fit: StackFit.expand,
          children: [
            MomentCover(moment: moment),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Color(0xCC0A0A0A)],
                  begin: Alignment(0, 0.1),
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'INVITED TO',
                    style: AppText.label(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    moment.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HostRow extends StatelessWidget {
  const _HostRow({required this.moment});

  final Moment moment;

  @override
  Widget build(BuildContext context) {
    final host = moment.members.isNotEmpty ? moment.members.first : 'Host';
    final others = moment.memberCount - 1;
    return Row(
      children: [
        GangAvatar(name: host, size: 44),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                host,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                others > 0
                    ? '+ $others others in the moment'
                    : 'just the host so far',
                style: AppText.mono(fontSize: 11, color: AppTheme.muted),
              ),
            ],
          ),
        ),
        if (moment.members.length > 1)
          _ParticipantStrip(members: moment.members.sublist(1)),
      ],
    );
  }
}

class _ParticipantStrip extends StatelessWidget {
  const _ParticipantStrip({required this.members});

  final List<String> members;

  @override
  Widget build(BuildContext context) {
    const size = 30.0;
    const step = 19.0;
    final shown = members.take(3).toList();
    final extra = members.length - shown.length;
    final slots = shown.length + (extra > 0 ? 1 : 0);
    final width = slots == 0 ? 0.0 : size + (slots - 1) * step;

    return SizedBox(
      width: width,
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * step,
              child: GangAvatar(
                name: shown[i],
                size: size,
                borderColor: AppTheme.cream,
              ),
            ),
          if (extra > 0)
            Positioned(
              left: shown.length * step,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: AppTheme.cream2,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.cream, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$extra',
                  style: AppText.mono(fontSize: 10, color: AppTheme.ink),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.moment});

  final Moment moment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.paper,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.line),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.cream2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.photo_library_rounded,
              size: 20,
              color: AppTheme.coral,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${moment.photoCount}',
                    style: AppText.display(fontSize: 20),
                  ),
                  const SizedBox(width: 6),
                  Text('photos', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              Text('so far', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _JoinCta extends StatelessWidget {
  const _JoinCta({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressCard(
      onTap: onTap,
      radius: AppTheme.radiusButton,
      gradient: const LinearGradient(
        colors: [AppTheme.coral, AppTheme.coralDeep],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      splashColor: Colors.white.withValues(alpha: 0.12),
      boxShadow: const [
        BoxShadow(
          color: AppTheme.softShadow,
          blurRadius: 22,
          offset: Offset(0, 10),
        ),
      ],
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: Text(
          'Join the Moment',
          style: GoogleFonts.geist(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
