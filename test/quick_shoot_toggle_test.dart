// Bug #1 regression: the Quick Shoot shortcut toggle must be OFF on a fresh
// install. Also asserts a persisted ON value is honoured.
//
// The notifier's build() best-effort-syncs the OS shortcut via quick_actions,
// whose platform channel isn't available under the test binding — that call is
// wrapped in try/catch, so it no-ops here.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gang_roll/features/active_moment/data/camera_shortcut_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('toggle is OFF on a fresh install (no stored prefs)', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final enabled = await container.read(cameraShortcutProvider.future);
    expect(enabled, isFalse);
  });

  test('a previously-saved enabled=true is respected', () async {
    SharedPreferences.setMockInitialValues({'camera_shortcut_enabled': true});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final enabled = await container.read(cameraShortcutProvider.future);
    expect(enabled, isTrue);
  });

  test('no Quick Shoot moment is bound on a fresh install', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final binding = await container.read(quickShootBindingProvider.future);
    expect(binding, isNull);
  });
}
