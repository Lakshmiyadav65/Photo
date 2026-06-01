// A small uppercase mono section label with an optional trailing widget —
// matches the "YOUR MOMENTS" / field-label microcopy used across the app.

import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

class SectionLabel extends StatelessWidget {
  const SectionLabel({super.key, required this.label, this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppText.label(fontSize: 11)),
        ?trailing,
      ],
    );
  }
}
