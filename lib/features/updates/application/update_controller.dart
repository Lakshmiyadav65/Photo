// Orchestrates update checks and owns the [UpdateState] the UI renders from.
//
// Lifecycle (all driven from this one Notifier):
//   • On first read (app launch) → one check, then a periodic re-check every
//     [AppConstants.updateCheckInterval] while the app stays open.
//   • Settings "Check for updates" → checkManually() (surfaces errors).
//   • Toast "Later"/close → dismissToast() (hides + persists the version).
//   • Toast/Settings "Update now" → openDownload() (launches the release URL).
//
// Auto-checks are silent: they never show a "Checking…" state, never surface an
// error, and never disturb the last good result. Only a manual check moves to
// [UpdatePhase.checking] / [UpdatePhase.error].

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants.dart';
import '../data/dismissed_update_store.dart';
import '../data/github_release_service.dart';
import '../domain/semantic_version.dart';
import '../domain/update_models.dart';

final githubReleaseServiceProvider = Provider<GithubReleaseService>(
  (ref) => GithubReleaseService(
    owner: AppConstants.githubReleasesOwner,
    repo: AppConstants.githubReleasesRepo,
  ),
);

final dismissedUpdateStoreProvider = Provider<DismissedUpdateStore>(
  (ref) => const DismissedUpdateStore(),
);

final updateControllerProvider =
    NotifierProvider<UpdateController, UpdateState>(UpdateController.new);

/// True only when the floating toast should be on screen — what the overlay
/// watches, so it rebuilds on exactly this transition.
final updateToastVisibleProvider = Provider<bool>((ref) {
  final s = ref.watch(updateControllerProvider);
  return s.phase == UpdatePhase.available && s.toastVisible && s.info != null;
});

class UpdateController extends Notifier<UpdateState> {
  Timer? _timer;
  SemanticVersion? _current; // installed version, resolved once and cached.

  // The version the user dismissed *this session* (until app restart). Scoped
  // by version so a dismissed toast stays gone across periodic re-checks, yet a
  // genuinely newer release published mid-session still surfaces.
  String? _dismissedThisSessionVersion;

  // Guards against overlapping checks (e.g. the periodic timer firing while a
  // manual check is still running).
  bool _checkInFlight = false;

  @override
  UpdateState build() {
    ref.onDispose(() => _timer?.cancel());

    // Launch check, then a low-frequency re-check while the app is open.
    Future.microtask(() => _runCheck(manual: false));
    _timer = Timer.periodic(
      AppConstants.updateCheckInterval,
      (_) => _runCheck(manual: false),
    );

    return const UpdateState(phase: UpdatePhase.idle);
  }

  /// Triggered by the Settings "Check for updates" button. Surfaces errors and
  /// the "up to date" result; otherwise identical to the auto-check.
  Future<void> checkManually() => _runCheck(manual: true);

  Future<void> _runCheck({required bool manual}) async {
    if (_checkInFlight) return;
    _checkInFlight = true;

    // The last resolved result — restored verbatim if a *silent* auto-check
    // fails, so a background failure never disturbs what Settings shows.
    final prior = state;
    final current = await _currentVersion();

    // Only a manual check surfaces "Checking…"; an auto-check updates state
    // invisibly so an open Settings screen doesn't flicker.
    state = manual
        ? state.copyWith(
            phase: UpdatePhase.checking,
            currentVersion: current.normalized,
          )
        : state.copyWith(currentVersion: current.normalized);

    try {
      final release =
          await ref.read(githubReleaseServiceProvider).fetchLatest();

      // No releases yet, or no newer version → up to date. Never show a toast.
      final latest = release == null
          ? null
          : SemanticVersion.tryParse(release.tagName);
      if (release == null || latest == null || latest <= current) {
        state = UpdateState(
          phase: UpdatePhase.upToDate,
          currentVersion: current.normalized,
        );
        return;
      }

      final info = UpdateInfo(
        version: latest.normalized,
        tagName: release.tagName,
        releaseUrl: release.htmlUrl,
        name: release.name,
        // Direct installer only when it matches THIS platform; otherwise null,
        // so "Update now" falls back to the release page (never a foreign file).
        downloadUrl: release.installerDownloadUrlFor(
          isWeb: kIsWeb,
          platform: defaultTargetPlatform,
        ),
        publishedAt: release.publishedAt,
      );

      // Auto-show unless the user already dismissed this exact version — this
      // session, or persisted from a previous one. A strictly newer release has
      // a different version string, so it surfaces normally.
      final dismissed =
          await ref.read(dismissedUpdateStoreProvider).dismissedVersion();
      final suppressed = _dismissedThisSessionVersion == info.version ||
          dismissed == info.version;

      state = UpdateState(
        phase: UpdatePhase.available,
        info: info,
        currentVersion: current.normalized,
        toastVisible: !suppressed,
      );
    } catch (_) {
      // Never leak raw errors. Manual → error state in Settings; auto → stay
      // silent and keep the last good result intact (no flicker, no downgrade).
      if (manual) {
        state = state.copyWith(
          phase: UpdatePhase.error,
          currentVersion: current.normalized,
          errorMessage:
              "Couldn't check for updates. Please try again later.",
        );
      } else {
        state = prior.copyWith(currentVersion: current.normalized);
      }
    } finally {
      _checkInFlight = false;
    }
  }

  /// "Later" / close on the toast: hide it for the rest of the session and
  /// remember the version so it won't auto-appear again until a newer release.
  Future<void> dismissToast() async {
    final version = state.info?.version;
    _dismissedThisSessionVersion = version;
    state = state.copyWith(toastVisible: false);
    if (version != null) {
      await ref.read(dismissedUpdateStoreProvider).setDismissedVersion(version);
    }
  }

  /// "Update now": open the release/installer page. Also hides the toast for
  /// this session (without persisting) since the user has acted on it.
  Future<bool> openDownload() async {
    final info = state.info;
    if (info == null) return false;

    _dismissedThisSessionVersion = info.version;
    state = state.copyWith(toastVisible: false);

    // Defense-in-depth: only ever hand the external launcher an https URL. A
    // non-https value (only possible from a tampered API response) falls back
    // to the known-safe releases page.
    final parsed = Uri.tryParse(info.launchUrl);
    final target = (parsed != null && parsed.scheme == 'https')
        ? parsed
        : Uri.parse(AppConstants.githubReleasesPage);
    try {
      return await launchUrl(target, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  Future<SemanticVersion> _currentVersion() async {
    final cached = _current;
    if (cached != null) return cached;
    try {
      final info = await PackageInfo.fromPlatform();
      final parsed = SemanticVersion.tryParse(info.version);
      return _current = parsed ?? SemanticVersion.zero;
    } catch (_) {
      return _current = SemanticVersion.zero;
    }
  }
}
