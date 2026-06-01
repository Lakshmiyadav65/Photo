// Smoke test: app boots and lands on the splash, then home renders the brand
// wordmark and the Create / Join entry points.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gang_roll/app/app.dart';
import 'package:gang_roll/shared/services/firebase_bootstrap.dart';

void main() {
  testWidgets('App boots, splash gives way to home with brand wordmark + CTAs', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseStatusProvider.overrideWithValue(FirebaseStatus.ready),
        ],
        child: const GangRollApp(),
      ),
    );

    // Splash is shown first.
    await tester.pump();
    expect(find.text('gang.roll'), findsWidgets);

    // Wait past the splash delay (800ms) + a buffer for the route transition.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Your first roll is empty.'), findsOneWidget);
    expect(find.text('New moment'), findsOneWidget);
    expect(find.text('Join with a code'), findsOneWidget);
  });
}
