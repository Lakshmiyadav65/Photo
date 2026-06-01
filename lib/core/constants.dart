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

  // Splash duration per spec App Flow doc.
  static const Duration splashDuration = Duration(milliseconds: 800);
}
