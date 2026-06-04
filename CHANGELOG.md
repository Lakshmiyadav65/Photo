# Changelog

All notable changes to this project are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `docs/` — `ARCHITECTURE.md` (feature-first layout) and `SPEC.md` placeholder.
- `LICENSE` (proprietary) and this changelog.
- `assets/branding/` — home for the generated launcher/store icon.

### Changed
- Hardened `.gitignore` to exclude Android signing secrets and `.env` files.
- `tool/gen_icon.py` now writes the 512px icon to `assets/branding/`.

### Removed
- Dead widget `lib/features/moments/presentation/widgets/roll_badge.dart` (unused).

## [1.0.0] - 2026-05
- Initial frontend prototype: auth → home flow, moments, gangs, Quick Shoot
  camera shortcut with local upload queue. Mock data behind every store.
