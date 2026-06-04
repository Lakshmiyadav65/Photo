// Semantic version parse + compare for update checks.
//
// We never compare version strings raw ("1.0.10" < "1.0.9" lexically would be
// wrong). Instead we parse into numeric major/minor/patch (+ optional
// pre-release identifiers) and compare per the semver spec ordering.
//
// Tolerant on the way in (GitHub tags are user-authored): a leading `v`/`V` is
// stripped, build metadata after `+` is ignored, and missing minor/patch
// default to 0 — so `v1.2`, `1.2.0`, and `1.2.0+7` all parse to 1.2.0.

class SemanticVersion implements Comparable<SemanticVersion> {
  const SemanticVersion(
    this.major,
    this.minor,
    this.patch, [
    this.preRelease = const [],
  ]);

  final int major;
  final int minor;
  final int patch;

  /// Dot-separated pre-release identifiers (empty for a stable release). e.g.
  /// `1.2.0-beta.1` → `['beta', '1']`. A version *with* a pre-release ranks
  /// below the same version without one (`1.2.0-beta` < `1.2.0`).
  final List<String> preRelease;

  static const SemanticVersion zero = SemanticVersion(0, 0, 0);

  /// Parse a tag/version string, or null if it has no numeric core at all.
  static SemanticVersion? tryParse(String? raw) {
    if (raw == null) return null;
    var s = raw.trim();
    if (s.isEmpty) return null;

    // Strip a leading `v`/`V` (e.g. `v1.0.3`).
    if (s.startsWith('v') || s.startsWith('V')) s = s.substring(1);

    // Drop build metadata (`+...`) — it has no bearing on precedence.
    final plus = s.indexOf('+');
    if (plus != -1) s = s.substring(0, plus);

    // Split off a pre-release suffix (`-rc.1`).
    List<String> pre = const [];
    final dash = s.indexOf('-');
    if (dash != -1) {
      final preStr = s.substring(dash + 1);
      pre = preStr.isEmpty ? const [] : preStr.split('.');
      s = s.substring(0, dash);
    }

    final parts = s.split('.');
    final major = int.tryParse(parts[0]);
    if (major == null) return null; // no numeric core → not a version
    final minor = parts.length > 1 ? int.tryParse(parts[1]) : 0;
    final patch = parts.length > 2 ? int.tryParse(parts[2]) : 0;
    if (minor == null || patch == null) return null;

    return SemanticVersion(major, minor, patch, pre);
  }

  @override
  int compareTo(SemanticVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    if (patch != other.patch) return patch.compareTo(other.patch);

    // Equal core. Pre-release precedence (semver §11.3/§11.4):
    final aPre = preRelease, bPre = other.preRelease;
    if (aPre.isEmpty && bPre.isEmpty) return 0;
    if (aPre.isEmpty) return 1; // stable > pre-release
    if (bPre.isEmpty) return -1;

    final shorter = aPre.length < bPre.length ? aPre.length : bPre.length;
    for (var i = 0; i < shorter; i++) {
      final a = aPre[i], b = bPre[i];
      final ai = int.tryParse(a), bi = int.tryParse(b);
      int c;
      if (ai != null && bi != null) {
        c = ai.compareTo(bi); // both numeric → compare numerically
      } else if (ai != null) {
        c = -1; // numeric identifiers rank below alphanumeric
      } else if (bi != null) {
        c = 1;
      } else {
        c = a.compareTo(b); // both alphanumeric → ASCII order
      }
      if (c != 0) return c;
    }
    // All shared identifiers equal → the longer set has higher precedence.
    return aPre.length.compareTo(bPre.length);
  }

  bool operator >(SemanticVersion other) => compareTo(other) > 0;
  bool operator <(SemanticVersion other) => compareTo(other) < 0;
  bool operator >=(SemanticVersion other) => compareTo(other) >= 0;
  bool operator <=(SemanticVersion other) => compareTo(other) <= 0;

  /// Canonical `major.minor.patch[-pre]` form (no `v`, no build metadata). Used
  /// as the stable key for "which version did the user dismiss?".
  String get normalized =>
      '$major.$minor.$patch${preRelease.isEmpty ? '' : '-${preRelease.join('.')}'}';

  @override
  bool operator ==(Object other) =>
      other is SemanticVersion &&
      other.major == major &&
      other.minor == minor &&
      other.patch == patch &&
      _listEquals(other.preRelease, preRelease);

  @override
  int get hashCode => Object.hash(major, minor, patch, Object.hashAll(preRelease));

  @override
  String toString() => normalized;

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
