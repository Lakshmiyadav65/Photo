// Update controller behavior: the dismissal/suppression rules that the review
// flagged. A dismissed version must stay hidden (this session AND persisted),
// but a genuinely newer release must still surface — and "no releases" must
// never show a toast.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gang_roll/features/updates/application/update_controller.dart';
import 'package:gang_roll/features/updates/data/github_release_service.dart';
import 'package:gang_roll/features/updates/domain/update_models.dart';

/// A stand-in for the real service whose returned release the test controls.
class _FakeService implements GithubReleaseService {
  GithubRelease? release;

  @override
  String get owner => 'o';
  @override
  String get repo => 'r';
  @override
  Future<GithubRelease?> fetchLatest() async => release;
}

GithubRelease _rel(String tag) => GithubRelease(
      tagName: tag,
      htmlUrl: 'https://github.com/o/r/releases/tag/$tag',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'gang.roll',
      packageName: 'com.gangroll.gang_roll',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    SharedPreferences.setMockInitialValues({});
  });

  // Let the launch-check microtask + its awaits settle.
  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  ProviderContainer containerWith(_FakeService fake) {
    final c = ProviderContainer(
      overrides: [githubReleaseServiceProvider.overrideWithValue(fake)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('a newer release makes the toast visible on launch', () async {
    final fake = _FakeService()..release = _rel('v1.0.3');
    final c = containerWith(fake);

    c.read(updateControllerProvider); // first read triggers the launch check
    await settle();

    final s = c.read(updateControllerProvider);
    expect(s.phase, UpdatePhase.available);
    expect(s.info?.version, '1.0.3');
    expect(c.read(updateToastVisibleProvider), isTrue);
  });

  test('no releases (null) → up to date, no toast', () async {
    final fake = _FakeService()..release = null;
    final c = containerWith(fake);

    c.read(updateControllerProvider);
    await settle();

    expect(c.read(updateControllerProvider).phase, UpdatePhase.upToDate);
    expect(c.read(updateToastVisibleProvider), isFalse);
  });

  test('same version is not treated as an update', () async {
    final fake = _FakeService()..release = _rel('v1.0.0'); // == installed
    final c = containerWith(fake);

    c.read(updateControllerProvider);
    await settle();

    expect(c.read(updateControllerProvider).phase, UpdatePhase.upToDate);
    expect(c.read(updateToastVisibleProvider), isFalse);
  });

  test('dismiss hides the toast, but a NEWER release re-shows it in-session',
      () async {
    final fake = _FakeService()..release = _rel('v1.0.3');
    final c = containerWith(fake);
    final notifier = c.read(updateControllerProvider.notifier);

    c.read(updateControllerProvider);
    await settle();
    expect(c.read(updateToastVisibleProvider), isTrue);

    // Dismiss 1.0.3 → hidden.
    await notifier.dismissToast();
    expect(c.read(updateToastVisibleProvider), isFalse);

    // Re-check, still 1.0.3 → stays hidden (session + persisted suppression).
    await notifier.checkManually();
    expect(c.read(updateToastVisibleProvider), isFalse);

    // A genuinely newer release appears → the toast comes back.
    fake.release = _rel('v1.0.4');
    await notifier.checkManually();
    expect(c.read(updateControllerProvider).info?.version, '1.0.4');
    expect(c.read(updateToastVisibleProvider), isTrue);
  });

  test('a persisted dismissed version suppresses the toast on next launch, '
      'but Settings still reflects the available update', () async {
    SharedPreferences.setMockInitialValues(
      {'dismissed_update_version': '1.0.3'},
    );
    final fake = _FakeService()..release = _rel('v1.0.3');
    final c = containerWith(fake);

    c.read(updateControllerProvider);
    await settle();

    final s = c.read(updateControllerProvider);
    expect(s.phase, UpdatePhase.available); // truth is still shown in Settings
    expect(c.read(updateToastVisibleProvider), isFalse); // toast stays hidden
  });
}
