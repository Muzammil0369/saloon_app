// supabase/functions/upload-media/index.ts
// Uploads salon images to Supabase Storage after checking the caller's Firebase login.
// Deploy with --no-verify-jwt (this function checks Firebase tokens itself).
//
// POST { action: "upload", kind, contentType, data }      -> { bucket, path, url? }
// POST { action: "signed-url", path }   (admin only)       -> { url }   valid 5 minutes

import admin from "npm:firebase-admin@12.6.0";
import { createClient } from "npm:@supabase/supabase-js@2.45.4";

const PUBLIC_BUCKET = "public-media";
const PRIVATE_BUCKET = "private-docs";
const MAX_BYTES = 3 * 1024 * 1024; // 3 MB per image

const ALLOWED_TYPES: Record<string, string> = {
  "image/jpeg": "jpg",
  "image/png": "png",
  "image/webp": "webp",
};

// Public: anyone can view these (shown in salon lists and profiles)
const PUBLIC_KINDS = new Set(["avatar", "salon", "gallery", "ad", "qr", "worker"]);
// Private: only admins can view these (identity and licence documents)
const PRIVATE_KINDS = new Set(["cnic_front", "cnic_back", "shop_license", "owner_photo"]);

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT") ?? "{}")),
  });
}
const db = admin.firestore();
db.settings({ preferRest: true }); // required on Supabase Edge Functions

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  { auth: { persistSession: false } },
);

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}

async function roleOf(uid: string): Promise<string> {
  const doc = await db.collection("users").doc(uid).get();
  return (doc.data()?.role as string) ?? "";
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  // 1. Who is calling? Verify the Firebase ID token.
  const token = (req.headers.get("authorization") ?? "").replace(/^Bearer\s+/i, "");
  if (!token) return json({ error: "unauthenticated" }, 401);

  let uid: string;
  try {
    uid = (await admin.auth().verifyIdToken(token)).uid;
  } catch {
    return json({ error: "unauthenticated" }, 401);
  }

  try {
    const body = await req.json();

    // ---- signed URL for private documents (admins only) ----
    if (body.action === "signed-url") {
      if ((await roleOf(uid)) !== "admin") return json({ error: "forbidden" }, 403);
      const path = String(body.path ?? "");
      if (!path || path.includes("..")) return json({ error: "bad_path" }, 400);
      const { data, error } = await supabase.storage
        .from(PRIVATE_BUCKET)
        .createSignedUrl(path, 300);
      if (error || !data) return json({ error: "not_found" }, 404);
      return json({ url: data.signedUrl });
    }

    // ---- upload ----
    if (body.action !== "upload") return json({ error: "bad_action" }, 400);

    const kind = String(body.kind ?? "");
    const isPrivate = PRIVATE_KINDS.has(kind);
    if (!isPrivate && !PUBLIC_KINDS.has(kind)) return json({ error: "bad_kind" }, 400);

    // Private documents may only be uploaded by a salon owner (or admin)
    if (isPrivate) {
      const role = await roleOf(uid);
      if (role !== "owner" && role !== "admin") return json({ error: "forbidden" }, 403);
    }

    // Accept either a data URI or raw base64
    const raw = String(body.data ?? "");
    const match = /^data:([^;]+);base64,(.*)$/s.exec(raw);
    const mime = match ? match[1] : String(body.contentType ?? "");
    const b64 = match ? match[2] : raw;

    const ext = ALLOWED_TYPES[mime];
    if (!ext) return json({ error: "bad_type" }, 415);

    const bytes = Uint8Array.from(atob(b64), (c) => c.charCodeAt(0));
    if (bytes.length === 0) return json({ error: "empty" }, 400);
    if (bytes.length > MAX_BYTES) return json({ error: "too_large" }, 413);

    // The server decides the path, so users can't write into someone else's folder
    const bucket = isPrivate ? PRIVATE_BUCKET : PUBLIC_BUCKET;
    const path = `${uid}/${kind}/${Date.now()}-${crypto.randomUUID()}.${ext}`;

    const { error: upErr } = await supabase.storage
      .from(bucket)
      .upload(path, bytes, {
        contentType: mime,
        cacheControl: isPrivate ? "no-store" : "86400",
        upsert: false,
      });
    if (upErr) {
      console.error("upload failed:", upErr.message);
      return json({ error: "upload_failed" }, 500);
    }

    if (isPrivate) {
      // Private files are returned as a path only; admins request a link later
      return json({ bucket, path });
    }
    const { data: pub } = supabase.storage.from(bucket).getPublicUrl(path);
    return json({ bucket, path, url: pub.publicUrl });
  } catch (e) {
    console.error("upload-media error:", e);
    return json({ error: "server_error" }, 500);
  }
});
