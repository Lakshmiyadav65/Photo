// Settings > Updates — the manual surface for the same update state the toast
// uses. Always reflects the truth (even if the toast was dismissed): shows the
// installed version, a manual "Check for updates" action, and a per-phase
// status line. This is the *only* place an error is ever shown to the user, and
// only after they manually check.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../application/update_controller.dart';
import '../domain/update_models.dart';

class UpdatesSettingsSection extends ConsumerWidget {
  const UpdatesSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateControllerProvider);
    final controller = ref.read(updateControllerProvider.notifier);
    final text = Theme.of(context).textTheme;
    final checking = state.phase == UpdatePhase.checking;
    final version = state.currentVersion.isEmpty ? '—' : state.currentVersion;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppTheme.paper,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.cream2,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.system_update_rounded,
                    size: 19, color: AppTheme.ink),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('App updates', style: text.titleMedium),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text('Installed', style: text.bodySmall),
                        const SizedBox(width: 6),
                        Text('v$version',
                            style: AppText.mono(
                                fontSize: 12, color: AppTheme.muted)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _StatusLine(state: state),
          const SizedBox(height: 14),

          // Primary action depends on the phase: an available update offers
          // "Update now"; otherwise it's a manual re-check.
          if (state.phase == UpdatePhase.available && state.info != null)
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: controller.openDownload,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.coral,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusButton),
                      ),
                    ),
                    child: const Text('Update now'),
                  ),
                ),
                const SizedBox(width: 10),
                _CheckButton(
                  checking: checking,
                  label: 'Recheck',
                  onPressed: checking ? null : controller.checkManually,
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: _CheckButton(
                checking: checking,
                label: checking ? 'Checking…' : 'Check for updates',
                onPressed: checking ? null : controller.checkManually,
                fullWidth: true,
              ),
            ),
        ],
      ),
    );
  }
}

/// The per-phase status line: a small icon + message. Deliberately quiet — it
/// never shouts, and an error only appears here, after a manual check.
class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.state});
  final UpdateState state;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    final (IconData icon, Color color, String message) = switch (state.phase) {
      UpdatePhase.checking => (
          Icons.sync_rounded,
          AppTheme.muted,
          'Checking for updates…',
        ),
      UpdatePhase.upToDate => (
          Icons.check_circle_rounded,
          AppTheme.sage,
          "You're on the latest version.",
        ),
      UpdatePhase.available => (
          Icons.new_releases_rounded,
          AppTheme.coral,
          'Version ${state.info?.version ?? ''} is available.',
        ),
      UpdatePhase.error => (
          Icons.error_outline_rounded,
          AppTheme.amber,
          state.errorMessage ??
              "Couldn't check for updates. Please try again later.",
        ),
      UpdatePhase.idle => (
          Icons.schedule_rounded,
          AppTheme.muted,
          'Tap below to check for a newer version.',
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cream2.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: text.bodySmall?.copyWith(color: AppTheme.ink2),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckButton extends StatelessWidget {
  const _CheckButton({
    required this.checking,
    required this.label,
    required this.onPressed,
    this.fullWidth = false,
  });

  final bool checking;
  final String label;
  final VoidCallback? onPressed;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: AppTheme.paper,
        foregroundColor: AppTheme.ink,
        side: const BorderSide(color: AppTheme.line),
        minimumSize: Size(fullWidth ? double.infinity : 0, 46),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
        ),
      ),
      child: checking
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.muted),
                  ),
                ),
                const SizedBox(width: 10),
                Text(label),
              ],
            )
          : Text(label),
    );
  }
}
