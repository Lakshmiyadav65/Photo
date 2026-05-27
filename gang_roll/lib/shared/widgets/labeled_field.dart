// A mono uppercase label above an underline text field with Fraunces input
// text — the prototype's .field pattern (auth, create, profile setup).

import 'package:flutter/material.dart';

import '../../app/theme.dart';

class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.onSubmitted,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppText.label()),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          onSubmitted: onSubmitted,
          cursorColor: AppTheme.coral,
          style: AppText.display(fontSize: 17),
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}
