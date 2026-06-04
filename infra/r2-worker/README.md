# gang.roll backend infrastructure

Two providers, clean split of concerns:

- **Firebase** — Auth (Email/Password + Google) and Firestore (all app data:
  users, events/rolls, members, photo *metadata*, gangs).
- **Cloudflare R2** — the actual image/video **bytes** ($0 egress), served over a
  CDN custom domain. This Worker mints presigned upload URLs.

Everything here is infrastructure-as-code. The Flutter integration (AuthRepository,
EventsRepository, PhotosRepository) is built separately in `lib/`.

---

## 1. Firebase (do this first — Auth + data layer depend on it)

1. [console.firebase.google.com](https://console.firebase.google.com) → **Create project** `gang-roll`.
2. **Add Android app** → package `com.gangroll.gang_roll` → download `google-services.json` → place in `android/app/`.
3. **Authentication** → Sign-in method → enable **Email/Password** and **Google**.
4. **Firestore Database** → Create (production mode).
5. **Storage** → *not needed* (media lives in R2).
6. Install CLIs and wire the app:
   ```bash
   npm i -g firebase-tools
   dart pub global activate flutterfire_cli   # ensure ~/.pub-cache/bin is on PATH
   firebase login
   flutterfire configure                      # generates lib/firebase_options.dart
   ```
7. Deploy rules + indexes (run from the repo root, where `firebase.json` lives):
   ```bash
   firebase deploy --only firestore:rules,firestore:indexes
   ```

## 2. Cloudflare R2 + this Worker (needed for the upload phase)

1. [dash.cloudflare.com](https://dash.cloudflare.com) → **R2** → **Create bucket** `gangroll-media`.
2. Bucket → **Settings** → **Public access** → connect a **custom domain**
   (e.g. `media.yourdomain.com`). This is your `MEDIA_BASE_URL` (free CDN, cached).
3. **R2 → Manage API Tokens** → create an **S3 Access Key** (Object Read & Write).
   Note the **Account ID**, **Access Key ID**, **Secret Access Key**.
4. Configure and deploy the Worker:
   ```bash
   cd infra/r2-worker
   npm install
   # edit wrangler.toml [vars]: R2_BUCKET, FIREBASE_PROJECT_ID, MEDIA_BASE_URL
   wrangler secret put R2_ACCOUNT_ID
   wrangler secret put R2_ACCESS_KEY_ID
   wrangler secret put R2_SECRET_ACCESS_KEY
   wrangler deploy
   ```
5. **CORS on the bucket** (so direct PUT from the app works) — R2 → bucket →
   Settings → CORS policy:
   ```json
   [{ "AllowedOrigins": ["*"], "AllowedMethods": ["PUT"],
      "AllowedHeaders": ["content-type"], "MaxAgeSeconds": 3600 }]
   ```
6. Copy the deployed Worker URL → it becomes the app's upload endpoint
   (`POST {workerUrl}/uploads`).

---

## Upload contract (app ↔ Worker)

`POST /uploads`  ·  `Authorization: Bearer <Firebase ID token>`
```jsonc
// request
{ "eventId": "abc123", "contentType": "image/jpeg" }
// response
{
  "photoId": "uuid", "uploaderId": "uid",
  "key": "events/abc123/uuid.jpg", "thumbKey": "events/abc123/uuid_thumb.jpg",
  "uploadUrl": "https://…r2…?X-Amz-…",      // PUT full-size bytes here
  "thumbUploadUrl": "https://…r2…?X-Amz-…", // PUT thumbnail here (null for video)
  "publicUrl": "https://media.…/events/abc123/uuid.jpg",
  "thumbUrl":  "https://media.…/events/abc123/uuid_thumb.jpg",
  "expiresIn": 600
}
```
The app then writes the Firestore photo doc with `publicUrl` / `thumbUrl` / `key`.
Membership is enforced at that Firestore write (rules), so a leaked presigned URL
can only place bytes at an unguessable key, never attach them to a roll.

## Security notes (MVP, revisit at scale)
- Worker authorizes by **valid Firebase token**, not yet by event membership
  (that needs a Firestore read from the Worker). Firestore rules are the real gate.
- Bucket is public-but-unguessable (UUID keys). Move to signed reads if rolls
  ever need to be truly private.
