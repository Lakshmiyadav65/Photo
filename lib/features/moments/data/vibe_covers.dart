// Vibe → curated cover image. Each vibe maps to a small pool of seeds; a
// moment picks one deterministically from its code, so the same roll always
// reads as the same cover and two rolls in the same vibe still look distinct.
//
// Source: picsum.photos with stable seeds. Real, high-quality photos that load
// reliably without any auth — good enough for a frontend demo. For a final
// product, swap the pools below for a curated set of mood-matched Unsplash
// photo IDs (or bundled assets) and the rest of the app needs no change.
//
// Smart-cover priority — implemented partially today, ready for the rest:
//   1. user-selected cover    (future)
//   2. most-liked photo       (future)
//   3. first uploaded photo   (future — wired when real uploads land)
//   4. vibe-based stock cover (this file)

import '../domain/moment.dart';

const Map<String, List<String>> _vibeSeeds = {
  'chaotic': [
    'gangroll-chaotic-festival',
    'gangroll-chaotic-nightlife',
    'gangroll-chaotic-party',
    'gangroll-chaotic-citylights',
  ],
  'nostalgic': [
    'gangroll-nostalgic-sunset',
    'gangroll-nostalgic-roadtrip',
    'gangroll-nostalgic-vintage',
    'gangroll-nostalgic-goldenhour',
  ],
  'wholesome': [
    'gangroll-wholesome-picnic',
    'gangroll-wholesome-dinner',
    'gangroll-wholesome-gathering',
    'gangroll-wholesome-cozy',
  ],
  'cinematic': [
    'gangroll-cinematic-mountain',
    'gangroll-cinematic-roadtrip',
    'gangroll-cinematic-aerial',
    'gangroll-cinematic-nightcity',
  ],
  'wild': [
    'gangroll-wild-hike',
    'gangroll-wild-surf',
    'gangroll-wild-camp',
    'gangroll-wild-adventure',
  ],
  'soft memories': [
    'gangroll-soft-pastel',
    'gangroll-soft-flowers',
    'gangroll-soft-cafe',
    'gangroll-soft-morning',
  ],
};

const List<String> _defaultSeeds = [
  'gangroll-default-1',
  'gangroll-default-2',
  'gangroll-default-3',
  'gangroll-default-4',
];

/// Returns the cover image URL for [m]. Cover priority (spec):
///   1. Manually-selected cover (Moment.coverUrlOverride)
///   2. Most-liked photo                ← future, real photos required
///   3. First uploaded photo            ← future, real photos required
///   4. Vibe-based stock cover (this file)
String coverUrlForMoment(Moment m, {int width = 1200, int height = 800}) {
  // 1 — host-chosen cover wins.
  final override = m.coverUrlOverride;
  if (override != null && override.isNotEmpty) return override;

  // 4 — vibe (or default) stock.
  final pool = _vibeSeeds[m.vibe] ?? _defaultSeeds;
  final seed = pool[m.code.hashCode.abs() % pool.length];
  return 'https://picsum.photos/seed/$seed/$width/$height';
}
