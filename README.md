# gang.roll

Shared photo rolls for friend groups. People create a **Moment** (a roll of film
for one event), invite their gang, capture and upload photos, and the moment
becomes a shared memory space.

Built with Flutter (mobile + web).

## Stack

| Layer | Choice |
| --- | --- |
| UI | Flutter 3.x, Material 3 |
| State | `flutter_riverpod` 3.x (Notifiers, Providers, AsyncNotifiers) |
| Navigation | `go_router` |
| Backend | Firebase (Auth · Firestore · Storage) — Phase 4+ |
| Storage (local) | `shared_preferences` (e.g. Active Moment selection) |
| Sharing | Native OS share sheet via `share_plus` |
| Images | `cached_network_image` for moment covers |
| Fonts | Bricolage Grotesque · Geist · Geist Mono (via `google_fonts`) |

## Getting started

```bash
# 1. Install Flutter (3.12+) — see https://docs.flutter.dev/get-started/install

# 2. Fetch dependencies
flutter pub get

# 3. Run on a connected device or emulator
flutter devices                                  # list available targets
flutter run                                      # default target
flutter run -d chrome                            # web
flutter run -d emulator-5554                     # named Android emulator
flutter run -d 192.168.x.x:port                  # wireless ADB
```

Hot reload: `r` in the run terminal. Hot restart: `R`.

## Project layout

```
.
├── lib/
│   ├── main.dart                    Entry — wraps ProviderScope around GangRollApp
│   ├── app/                         App shell: router, theme, scroll behavior
│   ├── core/                        Cross-cutting constants, extensions, utils
│   ├── features/                    Feature-first modules — each owns its slice
│   │   ├── active_moment/           Selected upload destination, persisted
│   │   ├── auth/                    Sign-in & profile setup screens
│   │   ├── gangs/                   Recurring friend groups (Search tab)
│   │   ├── insights/                Per-moment stats sheet
│   │   ├── moments/                 Rolls — domain, data, screens, widgets
│   │   ├── onboarding/              First-run flow
│   │   ├── photos/                  Single shared fullscreen viewer
│   │   ├── profile/                 Profile / Grid / Settings tabs
│   │   ├── quick_shoot/             Camera capture
│   │   ├── splash/                  Cold-start splash
│   │   └── upload/                  Photo picker → upload progress flow
│   └── shared/                      Cross-feature widgets & services
├── test/                            Widget tests
├── android/  ios/  web/  windows/   Platform shells
├── pubspec.yaml                     Dependencies & assets manifest
└── analysis_options.yaml            Lints
```

Inside each feature module:

```
features/<feature>/
├── domain/         Plain Dart types (Moment, Gang, UploadItem, …)
├── data/           Stores, providers, mocks, derivations
└── presentation/   Screens + screen-local widgets
```

Cross-feature primitives live in `lib/shared/`; cross-app primitives in
`lib/app/` and `lib/core/`. A widget that's only used by one feature stays
inside that feature.

## Behavior reference

The full product behavior (entities, roles, flows, permissions, Active Moment
rules, share/leave/delete semantics, dashboard sorting, etc.) is the source of
truth for backend integration. Held in conversation; will graduate to
`docs/SPEC.md` when the backend work begins.

## Status

Frontend prototype. Mock data behind every store; Firestore wiring lands in a
later phase. The mock layout is deliberately shaped like the production schema
so the swap is a data-layer change, not a UI rewrite.
