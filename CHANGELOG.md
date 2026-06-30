# Changelog

All notable changes to this project are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.4] - 2026-06-30

### Added
- RunBuds-style onboarding redesign with refreshed layout and motion polish.
- Avatar picker on the profile editor, backed by a new local avatar store.
- Google "G" logo widget and platform-info helper for cross-platform builds.

### Changed
- Standalone camera shortcut now opens a photo-only camera directly.
- Moments: develop-lock + thumbnails, R2 cleanup, view tracking, activity feed.
- `docs/` — `ARCHITECTURE.md` (feature-first layout) and `SPEC.md` placeholder.
- Hardened `.gitignore` to exclude Android signing secrets and `.env` files.
- `tool/gen_icon.py` now writes the 512px icon to `assets/branding/`.

### Fixed
- Google Sign-In enabled and unblocked cross-drive Android builds.

### Removed
- Dead widget `lib/features/moments/presentation/widgets/roll_badge.dart` (unused).

## [1.0.0] - 2026-05
- Initial frontend prototype: auth → home flow, moments, gangs, Quick Shoot
  camera shortcut with local upload queue. Mock data behind every store.
