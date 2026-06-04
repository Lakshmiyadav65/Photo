// The floating "New update available" toast — a premium, dismissible card that
// matches gang.roll's light surfaces and coral accent. It sits near the bottom,
// clear of the tab bar, and never blocks the user: it can be closed, deferred
// with "Later", or actioned with "Update now".
//
// [UpdateToastLayer] is a Positioned and is meant to live inside the tab shell's
// body Stack. It renders nothing until an (un-dismissed) update is available,
// then slides up.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme.dart';
import '../application/update_controller.dart';
import '../domain/update_models.dart';

/// Drop this directly into the tab shell's body [Stack]. It positions itself
/// just above the bottom nav bar and animates the toast in/out.
class UpdateToastLayer extends ConsumerWidget {
  const UpdateToastLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(updateToastVisibleProvider);
    final info = ref.watch(updateControllerProvider).info;
    // Under the shell's `extendBody: true`, the body's MediaQuery bottom padding
    // already includes the full tab-bar area (nav height + device inset), so we
    // add only a small gap to float just above the bar.
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Positioned(
      left: 16,
      right: 16,
      bottom: bottomInset + 12,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.25),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: (visible && info != null)
            ? Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  // Cap width so it stays a card (not a full-bleed bar) on web /
                  // desktop; on phones the left/right:16 gutters govern instead.
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: _UpdateToastCard(
                    key: ValueKey('update-toast-${info.version}'),
                    info: info,
                    onUpdate: () => ref
                        .read(updateControllerProvider.notifier)
                        .openDownload(),
                    onDismiss: () => ref
                        .read(updateControllerProvider.notifier)
                        .dismissToast(),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _UpdateToastCard extends StatelessWidget {
  const _UpdateToastCard({
    super.key,
    required this.info,
    required this.onUpdate,
    required this.onDismiss,
  });

  final UpdateInfo info;
  final VoidCallback onUpdate;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        decoration: BoxDecoration(
          color: AppTheme.paper,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(color: AppTheme.line),
          boxShadow: const [
            // A touch deeper than the ambient card glow so it reads as floating.
            BoxShadow(
              color: Color.fromRGBO(23, 23, 23, 0.10),
              blurRadius: 28,
              offset: Offset(0, 10),
            ),
            BoxShadow(
              color: AppTheme.softShadow,
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Coral-tinted leading glyph.
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.coral.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.rocket_launch_rounded,
                    size: 19,
                    color: AppTheme.coral,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('New update available', style: text.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        'A newer version of $_appName is ready to install.',
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
                // Close (dismiss) — same effect as "Later".
                _CloseButton(onTap: onDismiss),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                // "Update now" — coral, compact (the theme's primary is a full
                // 56px CTA, too tall for a toast).
                Expanded(
                  child: FilledButton(
                    onPressed: onUpdate,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.coral,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(44),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusButton),
                      ),
                      textStyle: GoogleFonts.geist(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Update now'),
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: onDismiss,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(64, 44),
                    foregroundColor: AppTheme.muted,
                    textStyle: GoogleFonts.geist(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  child: const Text('Later'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // gang.roll — kept inline so copy stays consistent with the app name.
  static const String _appName = 'gang.roll';
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 22,
      highlightColor: Colors.transparent,
      splashColor: AppTheme.coral.withValues(alpha: 0.08),
      child: const Padding(
        padding: EdgeInsets.all(4),
        child: Icon(Icons.close_rounded, size: 18, color: AppTheme.muted),
      ),
    );
  }
}
