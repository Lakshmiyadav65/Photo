// Quick Actions — the dual "New Roll" / "Join Roll" cards under the greeting.
// New Roll is the primary (coral) action; Join Roll is the neutral secondary.
// Built entirely from AppTheme tokens so it matches the rest of the app, with
// a subtle mount fade-in and a tactile press (scale + shadow) micro-interaction.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({
    super.key,
    required this.onNewRoll,
    required this.onJoinRoll,
  });

  final VoidCallback onNewRoll;
  final VoidCallback onJoinRoll;

  @override
  Widget build(BuildContext context) {
    return _MountFade(
      // Aligns with the feed cards' horizontal margin; balanced vertical rhythm.
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ActionCard(
                  primary: true,
                  icon: Icons.add_rounded,
                  title: 'New Moment',
                  subtitle: 'Start fresh',
                  onTap: onNewRoll,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ActionCard(
                  icon: Icons.qr_code_scanner_rounded,
                  title: 'Join Moment',
                  subtitle: 'Enter a code',
                  onTap: onJoinRoll,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tappable action card. [primary] = coral, elevated; otherwise = neutral
/// paper card with a hairline border. Presses scale down and soften the glow.
class ActionCard extends StatefulWidget {
  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool primary;

  @override
  State<ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<ActionCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.primary;
    final fg = primary ? Colors.white : AppTheme.ink;

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          boxShadow: primary
              ? [
                  BoxShadow(
                    color: AppTheme.softShadow, // ambient coral glow token
                    blurRadius: _pressed ? 10 : 22,
                    offset: Offset(0, _pressed ? 4 : 12),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: primary ? AppTheme.coral : AppTheme.paper,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: (_) {
              HapticFeedback.selectionClick();
              _setPressed(true);
            },
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            splashColor: primary
                ? Colors.white.withValues(alpha: 0.12)
                : AppTheme.coral.withValues(alpha: 0.06),
            highlightColor: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                gradient: primary
                    ? const LinearGradient(
                        colors: [AppTheme.coral, AppTheme.coralDeep],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                border: primary ? null : Border.all(color: AppTheme.line),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: primary
                            ? Colors.white.withValues(alpha: 0.18)
                            : AppTheme.cream2,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(widget.icon, size: 18, color: fg),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.display(fontSize: 18, color: fg),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: primary
                                ? Colors.white.withValues(alpha: 0.85)
                                : AppTheme.muted,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One-shot fade + gentle slide-up when the section first mounts.
class _MountFade extends StatefulWidget {
  const _MountFade({required this.child});

  final Widget child;

  @override
  State<_MountFade> createState() => _MountFadeState();
}

class _MountFadeState extends State<_MountFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  )..forward();

  late final Animation<double> _fade =
      CurvedAnimation(parent: _c, curve: Curves.easeOut);

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
