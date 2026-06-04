// Domain models for the in-app update flow.

/// A newer release the user can install. Built only when the latest GitHub
/// Release is strictly greater than the installed version.
class UpdateInfo {
  const UpdateInfo({
    required this.version,
    required this.tagName,
    required this.releaseUrl,
    this.name,
    this.downloadUrl,
    this.publishedAt,
  });

  /// Normalized version, e.g. `1.0.3` (no `v`, no build metadata). This is the
  /// key persisted when the user dismisses the toast.
  final String version;

  /// The raw release tag as authored on GitHub, e.g. `v1.0.3`.
  final String tagName;

  /// The release's GitHub page — where "Update now" sends the user when there
  /// is no direct installer asset.
  final String releaseUrl;

  /// Release title (may differ from the tag), shown when present.
  final String? name;

  /// First installable asset (e.g. an `.apk`) if the release ships one — opened
  /// directly so the download starts without an extra hop.
  final String? downloadUrl;

  final DateTime? publishedAt;

  /// What "Update now" should open: the direct installer if available, else the
  /// release page.
  String get launchUrl => downloadUrl ?? releaseUrl;
}

/// Where the update check currently is. Drives both the floating toast and the
/// Settings > Updates section.
enum UpdatePhase {
  /// Nothing has run yet (initial), or an auto-check failed silently.
  idle,

  /// A check is in flight.
  checking,

  /// Checked successfully; the installed version is current (or the repo has no
  /// releases yet).
  upToDate,

  /// A newer release exists. [UpdateState.info] is non-null.
  available,

  /// A *manual* check failed. Never set by an automatic check — auto failures
  /// stay silent so the user is never shown an error popup.
  error,
}

/// Immutable snapshot the UI renders from.
class UpdateState {
  const UpdateState({
    required this.phase,
    this.info,
    this.currentVersion = '',
    this.toastVisible = false,
    this.errorMessage,
  });

  final UpdatePhase phase;

  /// Non-null exactly when [phase] is [UpdatePhase.available].
  final UpdateInfo? info;

  /// Installed version, normalized, for display in Settings.
  final String currentVersion;

  /// Whether the floating toast should currently be on screen. Independent of
  /// [phase]: an update can be `available` while the toast is hidden because the
  /// user dismissed it this session or for this version.
  final bool toastVisible;

  /// User-safe message for the Settings error state — never a raw GitHub/HTTP
  /// error.
  final String? errorMessage;

  UpdateState copyWith({
    UpdatePhase? phase,
    UpdateInfo? info,
    String? currentVersion,
    bool? toastVisible,
    String? errorMessage,
  }) =>
      UpdateState(
        phase: phase ?? this.phase,
        info: info ?? this.info,
        currentVersion: currentVersion ?? this.currentVersion,
        toastVisible: toastVisible ?? this.toastVisible,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}
