// Circular avatar with a warm coral→amber gradient and the member's initial.
// Used in the home header, member strips, and the profile screen. Falls back
// to a generated gradient when there's no photo (v1 frontend uses initials).

import 'package:flutter/material.dart';

import '../../app/theme.dart';

class GangAvatar extends StatelessWidget {
  const GangAvatar({
    super.key,
    required this.name,
    this.size = 38,
    this.gradient,
    this.borderColor,
    this.onTap,
  });

  final String name;
  final double size;
  final Gradient? gradient;
  final Color? borderColor;
  final VoidCallback? onTap;

  static const List<List<Color>> _palettes = [
    [AppTheme.coral, AppTheme.amber],
    [AppTheme.sage, Color(0xFF5A6F50)],
    [AppTheme.amber, Color(0xFFC87534)],
    [Color(0xFF2A4A5A), Color(0xFF1A3A4A)],
    [Color(0xFF7A3E2D), Color(0xFF5A2E1D)],
  ];

  String get _initial =>
      name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();

  Gradient get _gradient {
    if (gradient != null) return gradient!;
    final colors = _palettes[name.hashCode.abs() % _palettes.length];
    return LinearGradient(
      colors: colors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: _gradient,
        shape: BoxShape.circle,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 2)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        _initial,
        style: AppText.display(
          fontSize: size * 0.4,
          color: AppTheme.cream,
        ),
      ),
    );
    if (onTap == null) return avatar;
    return GestureDetector(onTap: onTap, child: avatar);
  }
}
