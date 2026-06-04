// Talks to the public GitHub Releases API to find the latest *published*
// release. `releases/latest` already excludes drafts and pre-releases, so this
// only ever surfaces a real, shipped version — never a raw commit/push.
//
// No auth token: the repo is public, and tokens must never ship in client code.
// All failures are wrapped in [UpdateCheckException] with a user-safe message so
// the UI never has to render a raw HTTP/GitHub error. URLs taken from the
// response are validated to be https github.com links before we keep them.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants.dart';

/// A parsed GitHub Release (only the fields we use).
class GithubRelease {
  const GithubRelease({
    required this.tagName,
    required this.htmlUrl,
    this.name,
    this.publishedAt,
    this.assets = const [],
  });

  final String tagName;
  final String htmlUrl;
  final String? name;
  final DateTime? publishedAt;
  final List<GithubAsset> assets;

  /// Direct download URL for the installer matching the *current* platform, or
  /// null when there's no appropriate asset (the caller then falls back to the
  /// release page). We never hand a foreign binary — e.g. an Android `.apk` — to
  /// a desktop or web user.
  String? installerDownloadUrlFor({
    required bool isWeb,
    required TargetPlatform platform,
  }) {
    if (isWeb) return null; // nothing to "install" on web → use the release page
    final List<String> extensions;
    switch (platform) {
      case TargetPlatform.android:
        extensions = const ['.apk'];
      case TargetPlatform.windows:
        extensions = const ['.msix', '.exe', '.msi'];
      default:
        // iOS / macOS / Linux: no GitHub-installable asset convention here.
        return null;
    }
    for (final ext in extensions) {
      for (final a in assets) {
        if (a.name.toLowerCase().endsWith(ext)) return a.downloadUrl;
      }
    }
    return null;
  }
}

class GithubAsset {
  const GithubAsset({required this.name, required this.downloadUrl});
  final String name;
  final String downloadUrl;
}

/// Thrown for any non-success outcome (network down, rate-limited, malformed
/// payload). [message] is safe to show; raw details are intentionally dropped.
class UpdateCheckException implements Exception {
  const UpdateCheckException(this.message);
  final String message;
  @override
  String toString() => 'UpdateCheckException: $message';
}

class GithubReleaseService {
  GithubReleaseService({
    required this.owner,
    required this.repo,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String owner;
  final String repo;
  final http.Client _client;

  /// Fetch the latest published release.
  ///
  /// Returns `null` when the repo has **no releases yet** (HTTP 404) — that's a
  /// normal "nothing to update to" state, not an error. Throws
  /// [UpdateCheckException] for genuine failures.
  Future<GithubRelease?> fetchLatest() async {
    final uri = Uri.parse(
      'https://api.github.com/repos/$owner/$repo/releases/latest',
    );

    final http.Response response;
    try {
      response = await _client.get(
        uri,
        headers: const {
          'Accept': 'application/vnd.github+json',
          // GitHub requires a User-Agent on API requests.
          'User-Agent': 'gang.roll-app',
          'X-GitHub-Api-Version': '2022-11-28',
        },
      ).timeout(AppConstants.updateCheckTimeout);
    } catch (_) {
      // Timeout, DNS failure, offline, TLS error, …
      throw const UpdateCheckException(
        "Couldn't reach the update server. Check your connection and try again.",
      );
    }

    // No releases published for this repo yet.
    if (response.statusCode == 404) return null;

    if (response.statusCode != 200) {
      throw const UpdateCheckException(
        "Couldn't check for updates right now. Please try again later.",
      );
    }

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final tag = json['tag_name'] as String?;
      final htmlUrl = json['html_url'] as String?;
      if (tag == null || tag.isEmpty) {
        // A 200 with no tag is unusable — treat as "nothing to update to".
        return null;
      }

      // Keep only https github.com URLs from the payload, so a tampered or
      // unexpected response can't smuggle a non-GitHub link into the launcher.
      final assets = <GithubAsset>[];
      final rawAssets = json['assets'];
      if (rawAssets is List) {
        for (final a in rawAssets) {
          if (a is Map<String, dynamic>) {
            final name = a['name'] as String?;
            final url = a['browser_download_url'] as String?;
            if (name != null && _isTrustedGithubUrl(url)) {
              assets.add(GithubAsset(name: name, downloadUrl: url!));
            }
          }
        }
      }

      return GithubRelease(
        tagName: tag,
        htmlUrl: _isTrustedGithubUrl(htmlUrl)
            ? htmlUrl!
            : AppConstants.githubReleasesPage,
        name: json['name'] as String?,
        publishedAt: DateTime.tryParse(json['published_at'] as String? ?? ''),
        assets: assets,
      );
    } catch (e) {
      if (e is UpdateCheckException) rethrow;
      throw const UpdateCheckException(
        "Couldn't read the update information. Please try again later.",
      );
    }
  }
}

/// Whether [raw] is a safe https URL on a GitHub-owned host.
bool _isTrustedGithubUrl(String? raw) {
  final uri = Uri.tryParse(raw ?? '');
  if (uri == null || !uri.isAbsolute || uri.scheme != 'https') return false;
  final host = uri.host.toLowerCase();
  return host == 'github.com' ||
      host.endsWith('.github.com') ||
      host.endsWith('.githubusercontent.com');
}
