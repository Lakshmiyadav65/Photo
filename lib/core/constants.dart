// App-wide constants. Keep this tiny; feature-specific constants belong with
// the feature.

class AppConstants {
  AppConstants._();

  static const String appName = 'gang.roll';
  static const String tagline = 'Shared moments, live developed.';

  // Deep-link scheme (registered in AndroidManifest.xml during Phase 6).
  static const String deepLinkScheme = 'gangroll';

  // 6-letter join codes per spec backend doc. A-Z only (excluding ambiguous
  // characters is handled in [CodeGenerator]).
  static const int joinCodeLength = 6;

  // Photo upload constraints per spec TRD.
  static const int maxPhotoDimensionPx = 1920;
  static const int photoJpegQuality = 85;
  static const int maxPhotosPerMomentV1 = 500;
  static const int maxPhotoSizeBytes = 10 * 1024 * 1024; // 10 MB
  static const int maxAvatarSizeBytes = 5 * 1024 * 1024; // 5 MB

  // Cloudflare R2 upload Worker base URL (deployed via infra/r2-worker).
  // Set this to the `wrangler deploy` URL; empty means uploads fall back to the
  // simulated uploader.
  static const String r2WorkerBaseUrl = '';

  // Splash duration per spec App Flow doc.
  static const Duration splashDuration = Duration(milliseconds: 800);

  // ── In-app updates (GitHub Releases) ───────────────────────────────────────
  // The source of truth for "is a new version out?" is the latest *published*
  // GitHub Release (not commits/pushes). The public `releases/latest` endpoint
  // already excludes drafts and pre-releases, so a push only triggers a
  // notification once it's cut into a Release. Public repo → no token needed.
  static const String githubReleasesOwner = 'Lakshmiyadav65';
  static const String githubReleasesRepo = 'Photo';

  static String get githubLatestReleaseApi =>
      'https://api.github.com/repos/$githubReleasesOwner/$githubReleasesRepo/releases/latest';

  // Fallback "Update now" target when a release carries no html_url (rare).
  static String get githubReleasesPage =>
      'https://github.com/$githubReleasesOwner/$githubReleasesRepo/releases/latest';

  // Re-check cadence while the app stays open (the launch check runs once on
  // start, independent of this). Kept deliberately infrequent so we never spam
  // GitHub or the user.
  static const Duration updateCheckInterval = Duration(hours: 6);

  // Network timeout for a single update check — keeps a slow/offline network
  // from leaving the check hanging.
  static const Duration updateCheckTimeout = Duration(seconds: 15);
}
