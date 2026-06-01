// Brand typography widgets: the gang.roll wordmark and the hero title with a
// coral-italic emphasis word — both recurring motifs in the prototype.

import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// "gang.roll" — "gang" in ink, ".roll" in coral italic. The signature mark.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.fontSize = 28, this.color});

  final double fontSize;

  /// Override for dark surfaces; defaults to ink for "gang".
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'gang', style: AppText.display(fontSize: fontSize, color: color ?? AppTheme.ink)),
          TextSpan(text: '.roll', style: AppText.emphasis(fontSize: fontSize)),
        ],
      ),
    );
  }
}

/// A Fraunces hero title where one word is emphasized in coral italic, e.g.
/// "Welcome **back**" → HeroTitle(before: 'Welcome ', emphasis: 'back').
class HeroTitle extends StatelessWidget {
  const HeroTitle({
    super.key,
    this.before = '',
    required this.emphasis,
    this.after = '',
    this.fontSize = 36,
    this.textAlign = TextAlign.start,
    this.color,
  });

  final String before;
  final String emphasis;
  final String after;
  final double fontSize;
  final TextAlign textAlign;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          if (before.isNotEmpty)
            TextSpan(text: before, style: AppText.display(fontSize: fontSize, color: color)),
          TextSpan(text: emphasis, style: AppText.emphasis(fontSize: fontSize)),
          if (after.isNotEmpty)
            TextSpan(text: after, style: AppText.display(fontSize: fontSize, color: color)),
        ],
      ),
      textAlign: textAlign,
    );
  }
}
