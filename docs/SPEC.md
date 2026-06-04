# Product Specification

> **Status: placeholder.** This is the home the README points to for the full
> product behavior. The authoritative behavior currently lives in the 6-document
> gang.roll brief (held outside the repo). Paste / graduate it here as backend
> integration begins.

## What belongs in this document

The source of truth for backend integration — copy these in verbatim from the brief:

- **Entities & schema** — Moment (Firestore collection `events`), Gang, Photo,
  Member, UploadItem; field-by-field shapes.
- **Roles & permissions** — who can capture, view, share, leave, delete.
- **Active Moment rules** — selection, persistence, the one-tap Quick Shoot binding.
- **Lifecycle / develop-lock** — Live → Developing → Developed; when photos reveal.
- **Flows** — create / join (6-letter code · QR · link), capture → upload, insights.
- **Dashboard sorting** and share / leave / delete semantics.
- **Firestore + Storage security rules** (brief doc 5) — copy verbatim when wiring Firebase.

See [ARCHITECTURE.md](ARCHITECTURE.md) for how the code is organized.
