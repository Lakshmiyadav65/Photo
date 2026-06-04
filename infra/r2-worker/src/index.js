// gang.roll — Cloudflare Worker: mints presigned R2 upload URLs.
//
// Flow: the Flutter app sends its Firebase ID token + the target eventId; the
// Worker verifies the token, then returns short-lived presigned PUT URLs for a
// full-size object and its thumbnail. The app PUTs the bytes straight to R2 —
// they never pass through the Worker (good for large video). The app then
// writes the photo doc to Firestore (which is where membership is enforced).
//
// Secrets (set via `wrangler secret put …`):
//   R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY
// Vars (wrangler.toml [vars]):
//   R2_BUCKET, FIREBASE_PROJECT_ID, MEDIA_BASE_URL, ALLOWED_ORIGIN

import { AwsClient } from 'aws4fetch';
import { importX509, jwtVerify, decodeProtectedHeader } from 'jose';

const FIREBASE_CERT_URL =
  'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com';

const ALLOWED_IMAGE = ['jpg', 'jpeg', 'png', 'webp', 'heic'];
const ALLOWED_VIDEO = ['mp4', 'mov', 'webm'];
const PRESIGN_TTL = 600; // seconds

// --- Firebase ID token verification ----------------------------------------
let certCache = { exp: 0, certs: null };

async function getCerts() {
  const now = Date.now();
  if (certCache.certs && now < certCache.exp) return certCache.certs;
  const res = await fetch(FIREBASE_CERT_URL);
  if (!res.ok) throw new Error('cert fetch failed');
  const certs = await res.json();
  const m = /max-age=(\d+)/.exec(res.headers.get('cache-control') || '');
  certCache = { exp: now + (m ? +m[1] * 1000 : 3600_000), certs };
  return certs;
}

async function verifyFirebaseToken(token, projectId) {
  const { kid } = decodeProtectedHeader(token);
  const certs = await getCerts();
  const pem = certs[kid];
  if (!pem) throw new Error('unknown key id');
  const key = await importX509(pem, 'RS256');
  const { payload } = await jwtVerify(token, key, {
    issuer: `https://securetoken.google.com/${projectId}`,
    audience: projectId,
  });
  if (!payload.sub) throw new Error('missing sub');
  return payload; // payload.sub === Firebase uid
}

// --- helpers ----------------------------------------------------------------
function cors(env) {
  return {
    'Access-Control-Allow-Origin': env.ALLOWED_ORIGIN || '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'authorization, content-type',
  };
}

function json(body, status, env) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json', ...cors(env) },
  });
}

function extFor(contentType, fallback) {
  const map = {
    'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp',
    'image/heic': 'heic', 'video/mp4': 'mp4', 'video/quicktime': 'mov',
    'video/webm': 'webm',
  };
  return map[contentType] || fallback;
}

// --- Worker -----------------------------------------------------------------
export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: cors(env) });
    }
    const url = new URL(request.url);
    if (request.method !== 'POST' || url.pathname !== '/uploads') {
      return json({ error: 'not found' }, 404, env);
    }

    // 1. Authenticate.
    const auth = request.headers.get('authorization') || '';
    const token = auth.startsWith('Bearer ') ? auth.slice(7) : null;
    if (!token) return json({ error: 'missing bearer token' }, 401, env);

    let claims;
    try {
      claims = await verifyFirebaseToken(token, env.FIREBASE_PROJECT_ID);
    } catch (e) {
      return json({ error: 'invalid token', detail: String(e) }, 401, env);
    }

    // 2. Validate request.
    let payload;
    try {
      payload = await request.json();
    } catch {
      return json({ error: 'bad json' }, 400, env);
    }
    const { eventId, contentType } = payload;
    if (!eventId || !/^[A-Za-z0-9_-]{1,64}$/.test(eventId)) {
      return json({ error: 'bad eventId' }, 400, env);
    }
    const ext = extFor(contentType, '');
    if (!ALLOWED_IMAGE.includes(ext) && !ALLOWED_VIDEO.includes(ext)) {
      return json({ error: 'unsupported contentType' }, 415, env);
    }
    const isVideo = ALLOWED_VIDEO.includes(ext);

    // 3. Build object keys (unguessable id; uploader recorded for audit).
    const photoId = crypto.randomUUID();
    const base = `events/${eventId}/${photoId}`;
    const key = `${base}.${ext}`;
    const thumbKey = `${base}_thumb.jpg`; // thumbs are always jpeg

    // 4. Presign PUT URLs (bytes go straight to R2, not through this Worker).
    const r2 = new AwsClient({
      accessKeyId: env.R2_ACCESS_KEY_ID,
      secretAccessKey: env.R2_SECRET_ACCESS_KEY,
      service: 's3',
      region: 'auto',
    });
    const origin = `https://${env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com/${env.R2_BUCKET}`;

    async function presign(objectKey) {
      const signed = await r2.sign(
        new Request(`${origin}/${objectKey}?X-Amz-Expires=${PRESIGN_TTL}`, {
          method: 'PUT',
        }),
        { aws: { signQuery: true } },
      );
      return signed.url;
    }

    const uploadUrl = await presign(key);
    const thumbUploadUrl = isVideo ? null : await presign(thumbKey);

    return json(
      {
        photoId,
        uploaderId: claims.sub,
        key,
        thumbKey: isVideo ? null : thumbKey,
        uploadUrl,
        thumbUploadUrl,
        publicUrl: `${env.MEDIA_BASE_URL}/${key}`,
        thumbUrl: isVideo ? null : `${env.MEDIA_BASE_URL}/${thumbKey}`,
        expiresIn: PRESIGN_TTL,
      },
      200,
      env,
    );
  },
};
