// Overlapping circle avatars with an optional "+N" overflow chip — the social
// motif used in the gallery member row and the members sheet.

import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/gang_avatar.dart';

class AvatarStack extends StatelessWidget {
  const AvatarStack({
    super.key,
    required this.names,
    this.size = 30,
    this.max = 4,
    this.borderColor = AppTheme.cream,
  });

  final List<String> names;
  final double size;
  final int max;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final step = size * 0.64;
    final shown = names.take(max).toList();
    final extra = names.length - shown.length;
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
                borderColor: borderColor,
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
                  border: Border.all(color: borderColor, width: 2),
                ),
                alignment: Alignment.center,
                child: Text('+$extra',
                    style: AppText.mono(fontSize: size * 0.3, color: AppTheme.ink)),
              ),
            ),
        ],
      ),
    );
  }
}
