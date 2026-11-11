// lib/core/services/media_upload_service.dart
// Uploads images through the Supabase `upload-media` Edge Function.
// Uses only dart:io and firebase_auth (no new packages).

import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

class MediaUploadException implements Exception {
  final String code; // e.g. 'unauthenticated', 'too_large', 'network'
  MediaUploadException(this.code);
  @override
  String toString() => 'MediaUploadException($code)';
}

class MediaUploadResult {
  final String bucket;
  final String path;
  final String? url; // only for public kinds
  const MediaUploadResult({required this.bucket, required this.path, this.url});
}

class MediaUploadService {
  MediaUploadService._();

  static const _endpoint =
      'https://rzypfwjhngpwlxfbxtcg.supabase.co/functions/v1/upload-media';

  /// Shown to everyone (salon photos, avatars, ads, QR, gallery, worker photos).
  static const publicKinds = {'avatar', 'salon', 'gallery', 'ad', 'qr', 'worker'};

  /// Visible only to admins (CNIC, licence, owner verification photo).
  static const privateKinds = {'cnic_front', 'cnic_back', 'shop_license', 'owner_photo'};

  static const _maxBytes = 3 * 1024 * 1024;

  /// Uploads an image. Returns a public URL for public kinds, or a path only
  /// for private kinds. Store the result in Firestore, never the image itself.
  static Future<MediaUploadResult> uploadFile(File file, {required String kind}) async {
    if (!publicKinds.contains(kind) && !privateKinds.contains(kind)) {
      throw MediaUploadException('bad_kind');
    }
    final mime = _mimeFor(file.path);
    final size = await file.length();
    if (size > _maxBytes) throw MediaUploadException('too_large');

    final b64 = base64Encode(await file.readAsBytes());
    final res = await _call({
      'action': 'upload',
      'kind': kind,
      'contentType': mime,
      'data': b64,
    });
    return MediaUploadResult(
      bucket: res['bucket'] as String,
      path: res['path'] as String,
      url: res['url'] as String?,
    );
  }

  /// Admin only: a link that works for 5 minutes, for viewing a private document.
  static Future<String> signedUrlFor(String path) async {
    final res = await _call({'action': 'signed-url', 'path': path});
    return res['url'] as String;
  }

  // ---------------------------------------------------------------- internals

  static String _mimeFor(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.jpg') || p.endsWith('.jpeg')) return 'image/jpeg';
    if (p.endsWith('.png')) return 'image/png';
    if (p.endsWith('.webp')) return 'image/webp';
    throw MediaUploadException('bad_type');
  }

  static Future<Map<String, dynamic>> _call(Map<String, dynamic> body) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw MediaUploadException('unauthenticated');
    final token = await user.getIdToken();

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 30);
    try {
      final req = await client.postUrl(Uri.parse(_endpoint));
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      req.write(jsonEncode(body));

      final res = await req.close();
      final text = await res.transform(utf8.decoder).join();
      final map = text.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(text) as Map<String, dynamic>;

      if (res.statusCode >= 300) {
        throw MediaUploadException(map['error']?.toString() ?? 'http_${res.statusCode}');
      }
      return map;
    } on SocketException {
      throw MediaUploadException('network');
    } finally {
      client.close();
    }
  }
}