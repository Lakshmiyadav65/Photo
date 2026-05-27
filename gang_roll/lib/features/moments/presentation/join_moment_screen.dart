// Placeholder — Phase 4 + Phase 6: 6-letter code entry + QR scanner.
//
// Accepts a `prefilledCode` query param so deep links (`/join?code=ABCDEF`)
// land here with the code already entered.

import 'package:flutter/material.dart';

import '../../../shared/widgets/placeholder_screen.dart';

class JoinMomentScreen extends StatelessWidget {
  const JoinMomentScreen({super.key, this.prefilledCode});
  final String? prefilledCode;

  @override
  Widget build(BuildContext context) => PlaceholderScreen(
        title: 'Join a moment',
        todo: 'Phase 4: 6-letter code input '
            '${prefilledCode != null ? "(prefilled: $prefilledCode) " : ""}'
            '+ QR scanner via mobile_scanner. On valid code, add user to '
            '/events/<id>/members and navigate to /moment/<code>.',
      );
}
