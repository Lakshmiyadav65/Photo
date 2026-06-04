# Architecture

gang.roll is a Flutter app (mobile + web + Windows) built **feature-first**: code is
grouped by product capability, not by technical layer. A change to one capability
touches one folder.

## Stack

| Concern | Choice |
| --- | --- |
| UI | Flutter 3.x, Material 3 |
| State | `flutter_riverpod` 3.x (Notifiers, Providers, AsyncNotifiers) |
| Navigation | `go_router` |
| Backend | Firebase — Auth · Firestore (· Storage, deferred) |
| Local persistence | `shared_preferences`, `sqflite` (Quick Shoot upload queue) |
| Fonts | `google_fonts` (downloaded at runtime — no bundled font files) |

## Source layout (`lib/`)

```
lib/
├── main.dart            Entry — wraps ProviderScope around the app
├── app/                 App shell: app widget, router, theme, scroll behavior
├── core/                Cross-cutting constants, extensions, utils
├── features/            Feature-first modules (see below)
└── shared/              Cross-feature widgets, services, database
```

`lib/` is Flutter's mandated source root — it is the equivalent of `src/` in other
stacks. The package name is `gang_roll`, so imports resolve as
`package:gang_roll/<path-under-lib>`.

## Anatomy of a feature

Each module under `lib/features/<feature>/` owns its full vertical slice:

```
features/<feature>/
├── domain/          Plain Dart types (Moment, Gang, UploadItem, …)
├── data/            Stores, providers, repositories, mocks, derivations
└── presentation/    Screens + screen-local widgets
```

A widget used by only one feature stays inside that feature. Primitives shared
across features live in `lib/shared/`; app- and language-level primitives live in
`lib/app/` and `lib/core/`.

Current features: `active_moment`, `auth`, `gangs`, `insights`, `moments`,
`onboarding`, `photos`, `profile`, `quick_shoot`, `splash`, `upload`.

## Data flow & the mock → Firestore swap

Every store currently sits behind **mock data** shaped like the production
Firestore schema, so wiring the backend is a data-layer change, not a UI rewrite.
Note the deliberate naming split: the concept is `Moment` in the UI/domain, while
the Firestore collection is `events`.

## Conventions

- File names: `snake_case.dart`. Identifiers: `lowerCamelCase` / `UpperCamelCase`.
- Tests live in `test/` (Flutter-mandated). Dev scripts live in `tool/` (Dart standard).
- Lints are enforced via `analysis_options.yaml`; keep `flutter analyze` green.
