// migrate_all_images_to_supabase.js
// Moves every image in users/ and owners/ (base64, ImgBB, Cloudinary, or any
// other external image URL) into Supabase Storage bucket "public-media" and
// writes the new public URL back in place of the old value.
//
// Usage (run from the functions folder):
//   node migrate_all_images_to_supabase.js --dry   report only, writes nothing
//   node migrate_all_images_to_supabase.js         migrate and write back
//
// Env vars: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, GOOGLE_APPLICATION_CREDENTIALS

const admin = require('firebase-admin');
const { createClient } = require('@supabase/supabase-js');
const crypto = require('crypto');

const DRY = process.argv.includes('--dry');
const BUCKET = 'public-media';
const COLLECTIONS = ['users', 'owners']; // owner_private is intentionally excluded
const EXTERNAL_HOSTS = ['ibb.co', 'imgbb.com', 'cloudinary.com'];
const IMAGE_PATH = /\.(jpe?g|png|webp|gif)$/i;
const MAX_BYTES = 15 * 1024 * 1024;
const EXT = { 'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp', 'image/gif': 'gif' };

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!SUPABASE_URL || !SUPABASE_KEY) {
  console.error('Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY first.');
  process.exit(1);
}
const supabaseHost = new URL(SUPABASE_URL).host;

admin.initializeApp({ credential: admin.credential.applicationDefault() });
const db = admin.firestore();
const supabase = createClient(SUPABASE_URL, SUPABASE_KEY, { auth: { persistSession: false } });

const cache = new Map(); // source value -> new public URL (reuses duplicates)
const stats = { found: 0, uploaded: 0, reused: 0, failed: 0, docsChanged: 0 };

function parseUrl(s) {
  try { return new URL(s); } catch { return null; }
}

function isPlainObject(v) {
  return v !== null && typeof v === 'object' && Object.getPrototypeOf(v) === Object.prototype;
}

function needsMigration(s) {
  if (typeof s !== 'string') return false;
  if (s.startsWith('data:image/')) return true;
  if (!/^https?:\/\//i.test(s)) return false;
  const u = parseUrl(s);
  if (!u || u.host === supabaseHost) return false;
  return EXTERNAL_HOSTS.some((h) => u.host.endsWith(h)) || IMAGE_PATH.test(u.pathname);
}

async function fetchBytes(src) {
  if (src.startsWith('data:image/')) {
    const m = src.match(/^data:(image\/[\w+.-]+);base64,(.*)$/s);
    if (!m) throw new Error('malformed data URI');
    return { buf: Buffer.from(m[2], 'base64'), type: m[1], ext: EXT[m[1]] || 'jpg' };
  }
  const res = await fetch(src, { redirect: 'follow' });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  const type = (res.headers.get('content-type') || '').split(';')[0].trim().toLowerCase();
  const buf = Buffer.from(await res.arrayBuffer());
  const urlExt = (parseUrl(src)?.pathname.match(/\.(jpe?g|png|webp|gif)$/i) || [])[1];
  const ext = EXT[type] || (urlExt ? urlExt.toLowerCase().replace('jpeg', 'jpg') : 'jpg');
  return { buf, type: EXT[type] ? type : 'image/jpeg', ext };
}

async function migrateSource(src, ownerId) {
  if (cache.has(src)) {
    stats.reused++;
    return cache.get(src);
  }
  if (DRY) {
    stats.uploaded++;
    const fake = `(dry run) ${src.slice(0, 60)}`;
    cache.set(src, fake);
    return fake;
  }
  const { buf, type, ext } = await fetchBytes(src);
  if (buf.length === 0) throw new Error('empty image');
  if (buf.length > MAX_BYTES) throw new Error('image over 15 MB');

  const path = `${ownerId}/migrated/${Date.now()}-${crypto.randomBytes(6).toString('hex')}.${ext}`;
  const { error } = await supabase.storage.from(BUCKET).upload(path, buf, {
    contentType: type,
    upsert: false,
  });
  if (error) throw new Error(`upload: ${error.message}`);

  const url = `${SUPABASE_URL}/storage/v1/object/public/${BUCKET}/${path}`;
  cache.set(src, url);
  stats.uploaded++;
  console.log(`    ok ${src.slice(0, 60)}`);
  return url;
}

// Walks any value (string, array, map) and replaces image sources it finds.
async function transform(value, ownerId) {
  if (typeof value === 'string') {
    if (!needsMigration(value)) return value;
    stats.found++;
    try {
      return await migrateSource(value, ownerId);
    } catch (e) {
      stats.failed++;
      console.warn(`    keep old value (${e.message}): ${value.slice(0, 80)}`);
      return value;
    }
  }
  if (Array.isArray(value)) {
    const out = [];
    for (const v of value) out.push(await transform(v, ownerId));
    return out;
  }
  if (isPlainObject(value)) {
    const out = {};
    for (const [k, v] of Object.entries(value)) out[k] = await transform(v, ownerId);
    return out;
  }
  return value; // Timestamps, GeoPoints, numbers, booleans pass through
}

async function main() {
  console.log(DRY ? 'DRY RUN: nothing will be written' : 'MIGRATING');
  for (const col of COLLECTIONS) {
    const snap = await db.collection(col).get();
    console.log(`${col}: ${snap.size} documents`);
    for (const doc of snap.docs) {
      const data = doc.data();
      const changedFields = {};
      for (const [field, value] of Object.entries(data)) {
        const next = await transform(value, doc.id);
        if (JSON.stringify(next) !== JSON.stringify(value)) changedFields[field] = next;
      }
      if (Object.keys(changedFields).length > 0) {
        stats.docsChanged++;
        console.log(`  ${col}/${doc.id}: ${Object.keys(changedFields).join(', ')}`);
        if (!DRY) await doc.ref.update(changedFields);
      }
    }
  }
  console.log('\nfound=' + stats.found + ' uploaded=' + stats.uploaded +
    ' reused=' + stats.reused + ' failed=' + stats.failed +
    ' documents_changed=' + stats.docsChanged);
}

main().catch((e) => {
  console.error('Fatal:', e);
  process.exit(1);
});