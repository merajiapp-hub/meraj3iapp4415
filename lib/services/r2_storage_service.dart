import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// خدمة التخزين السحابي Cloudflare R2 للصور والملفات
class R2StorageService {
  static final R2StorageService _instance = R2StorageService._internal();
  factory R2StorageService() => _instance;
  R2StorageService._internal();

  /// بيانات حساب Cloudflare الرسمي المعتمد: Merajiapp@gmail.com
  static const String cloudflareAccountId = 'f5d382cd0728f2a24d516cc12fcd3fe6';
  static const String directR2StorageEndpoint =
      'https://f5d382cd0728f2a24d516cc12fcd3fe6.r2.cloudflarestorage.com';
  static const String r2AccessKeyId = 'eefc3b83b30298fe04ecfc1faf5a416f';

  /// الرابط الأساسي لخدمة Cloudflare R2 Worker لتطبيق مراجعي
  /// مربوط بحساب merajiapp@gmail.com ومستودع meraj3i-media
  static const String defaultR2Endpoint = 'https://meraj3i-media-r2.merajiapp.workers.dev';

  String _endpoint = defaultR2Endpoint;

  void setCustomEndpoint(String url) {
    _endpoint = url.trim().replaceAll(RegExp(r'/+$'), '');
  }

  /// رفع صورة الملف الشخصي للمستخدم
  /// المسار في R2: users/{userId}/avatar_{timestamp}.jpg
  Future<String?> uploadUserAvatar({
    required String userId,
    required Uint8List bytes,
    String mimeType = 'image/jpeg',
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ext = mimeType.contains('png') ? 'png' : 'jpg';
    final targetPath = 'users/$userId/avatar_$timestamp.$ext';

    return _uploadToR2(
      path: targetPath,
      bytes: bytes,
      mimeType: mimeType,
    );
  }

  /// رفع إثبات / وصل الدفع
  /// المسار في R2: payments/{userId}/receipt_{timestamp}.jpg
  Future<String?> uploadPaymentProof({
    required String userId,
    required Uint8List bytes,
    String mimeType = 'image/jpeg',
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ext = mimeType.contains('png') ? 'png' : 'jpg';
    final targetPath = 'payments/$userId/receipt_$timestamp.$ext';

    return _uploadToR2(
      path: targetPath,
      bytes: bytes,
      mimeType: mimeType,
    );
  }

  /// تنفيذ عملية الرفع إلى Cloudflare R2
  Future<String?> _uploadToR2({
    required String path,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    try {
      final uri = Uri.parse('$_endpoint/upload');
      final request = http.Request('POST', uri);
      request.headers['Content-Type'] = mimeType;
      request.headers['X-File-Path'] = path;
      request.bodyBytes = bytes;

      final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final publicUrl = data['url']?.toString();
        debugPrint('[R2StorageService] Upload success: $publicUrl');
        return publicUrl;
      } else {
        debugPrint(
            '[R2StorageService] Upload failed with status: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('[R2StorageService] Upload exception: $e');
    }

    return null;
  }
}
