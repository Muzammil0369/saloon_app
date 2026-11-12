// One-time migration: moves base64 images that are stored inside Firestore
// documents into Supabase Storage (public-media), then replaces each value with
// the public link. Safe to re-run: converted values are no longer base64, so
// they are skipped. ImgBB / Cloudinary links are left untouched.
//
// Private documents (CNIC / licence) are NOT touched here. They need the admin
// screen to switch to signed links first.
//
// Run from the functions folder:
//   $env:GOOGLE_APPLICATION_CREDENTIALS="...\serviceAccountKey.json"
//   $env:SUPABASE_URL="https://rzypfwjhngpwlxfbxtcg.supabase.co"
//   $env:SUPABASE_SERVICE_ROLE_KEY="<from Supabase > Settings > API>"
//   node migrate_images_to_supabase.js --dry     (counts only)
//   node migrate_images_to_supabase.js           (does the work)

const admin = require('firebase-admin');
const { createClient } = require('@supabase/supabase-js');

admin.initializeApp();
const db = admin.firestore();
const DRY = process.argv.includes('--dry');
const BUCKET = 'public-media';
const MAX_BYTES = 3 * 1024 * 1024;
const EXT = { 'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp' };

const sb = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY, {
  auth: { persistSession: false },
});

const stats = { uploaded: 0, failed: 0, docsChanged: 0 };
const cache = new Map(); // same image stored twice (e.g. thumbnail + gallery) uploads once

function isBase64Image(v) {
  return typeof v === 'string' && v.startsWith('data:image/');
}

async function convert(value, uid, kind) {
  if (!isBase64Image(value)) return value;
  if (cache.has(value)) return cache.get(value);

  const m = /^data:(image\/[a-z+]+);base64,(.*)$/s.exec(value);
  if (!m || !EXT[m[1]]) { stats.failed++; return value; }

  const bytes = Buffer.from(m[2], 'base64');
  if (bytes.length === 0 || bytes.length > MAX_BYTES) { stats.failed++; return value; }

  if (DRY) { stats.uploaded++; return value; }

  const path = `${uid}/${kind}/${Date.now()}-${Math.random().toString(36).slice(2)}.${EXT[m[1]]}`;
  const { error } = await sb.storage.from(BUCKET).upload(path, bytes, {
    contentType: m[1],
    cacheControl: '86400',
    upsert: false,
  });
  if (error) {
    console.error(`upload failed for ${uid} (${kind}): ${error.message}`);
    stats.failed++;
    return value; // keep the old value, so nothing is lost
  }
  const url = sb.storage.from(BUCKET).getPublicUrl(path).data.publicUrl;
  stats.uploaded++;
  cache.set(value, url);
  return url;
}

async function migrateUsers() {
  const snap = await db.collection('users').get();
  for (const doc of snap.docs) {
    const d = doc.data();
    if (!isBase64Image(d.profileImage)) continue;
    const url = await convert(d.profileImage, doc.id, 'avatar');
    if (url !== d.profileImage) {
      stats.docsChanged++;
      if (!DRY) await doc.ref.update({ profileImage: url });
    }
  }
}

async function migrateOwners() {
  const snap = await db.collection('owners').get();
  for (const doc of snap.docs) {
    const id = doc.id;
    const d = doc.data();
    const upd = {};

    for (const field of ['ownerProfileImage', 'thumbnail', 'shopOutsidePhoto', 'logo']) {
      if (!isBase64Image(d[field])) continue;
      const kind = field === 'ownerProfileImage' ? 'avatar' : 'salon';
      const url = await convert(d[field], id, kind);
      if (url !== d[field]) upd[field] = url;
    }

    if (Array.isArray(d.salonPhotos) && d.salonPhotos.some(isBase64Image)) {
      const list = [];
      for (const p of d.salonPhotos) list.push(await convert(p, id, 'salon'));
      upd.salonPhotos = list;
    }

    if (Array.isArray(d.workers) && d.workers.some(w => w && isBase64Image(w.profileImage))) {
      const list = [];
      for (const w of d.workers) {
        if (w && isBase64Image(w.profileImage)) {
          list.push({ ...w, profileImage: await convert(w.profileImage, id, 'worker') });
        } else {
          list.push(w);
        }
      }
      upd.workers = list;
    }

    if (Object.keys(upd).length > 0) {
      stats.docsChanged++;
      if (!DRY) await doc.ref.update(upd);
    }
  }
}

(async () => {
  console.log(DRY ? '[dry run] counting only, nothing changes' : 'running migration');
  await migrateUsers();
  await migrateOwners();
  const prefix = DRY ? '[dry] ' : '';
  console.log(`${prefix}uploaded=${stats.uploaded} failed=${stats.failed} documents_changed=${stats.docsChanged}`);
  console.log('Note: CNIC and licence images in owner_private are not migrated by this script.');
})().catch(e => {
  console.error('migration stopped:', e);
  process.exit(1);
});