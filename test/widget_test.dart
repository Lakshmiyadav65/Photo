// Smoke test: the app boots and renders its first screen (the brand wordmark)
// without throwing. Routing past first-run onboarding needs real
// permission/auth state, so this stays a boot check rather than asserting
// deeper screen copy.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gang_roll/app/app.dart';
import 'package:gang_roll/shared/services/firebase_bootstrap.dart';

void main() {
  testWidgets('App boots and renders the brand wordmark', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseStatusProvider.overrideWithValue(FirebaseStatus.ready),
        ],
        child: const GangRollApp(),
      ),
    );

    // Splash → first real screen; the brand wordmark is present throughout.
    await tester.pump();
    expect(find.text('gang.roll'), findsWidgets);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('gang.roll'), findsWidgets);
  });
}
