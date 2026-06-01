// A rounded, tappable surface with ripple + a soft press-scale and haptic — the
// shared source of tactile feedback for cards across the create/join flows so
// every surface feels consistent. Theme-driven; pass color/gradient/border.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme.dart';

class PressCard extends StatefulWidget {
  const PressCard({
    super.key,
    required this.onTap,
    required this.child,
    this.color,
    this.gradient,
    this.border,
    this.boxShadow,
    this.radius = AppTheme.radiusCard,
    this.padding = const EdgeInsets.all(16),
    this.splashColor,
  });

  final VoidCallback onTap;
  final Widget child;
  final Color? color;
  final Gradient? gradient;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color? splashColor;

  @override
  State<PressCard> createState() => _PressCardState();
}

class _PressCardState extends State<PressCard> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(widget.radius);
    return AnimatedScale(
      scale: _down ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: DecoratedBox(
        decoration: BoxDecoration(borderRadius: br, boxShadow: widget.boxShadow),
        child: Material(
          color: Colors.transparent,
          borderRadius: br,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onTap();
            },
            onHighlightChanged: _set,
            splashColor:
                widget.splashColor ?? AppTheme.coral.withValues(alpha: 0.06),
            highlightColor: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                color: widget.gradient == null
                    ? (widget.color ?? AppTheme.paper)
                    : null,
                gradient: widget.gradient,
                borderRadius: br,
                border: widget.border,
              ),
              child: Padding(padding: widget.padding, child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}
