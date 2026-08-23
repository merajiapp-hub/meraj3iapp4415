/// خدمة ذكية لمعالجة روابط Google Drive
/// تدعم جميع صيغ الروابط الشائعة والنادرة
/// لا تحذف أي كتاب مهما كانت حالة الرابط
class DriveUrlService {
  // ── أنواع حالات الرابط ────────────────────────────────────────
  static const String statusValid = 'valid';
  static const String statusPrivate = 'private';
  static const String statusNeedsLogin = 'needs_login';
  static const String statusUnknownFormat = 'unknown_format';
  static const String statusInvalid = 'invalid';
  static const String statusEmpty = 'empty';
  static const String statusChecking = 'checking';
  static const String statusNeedsReview = 'needs_review';

  // ── استخراج FILE_ID من أي صيغة رابط Google Drive ───────────────
  static String? extractFileId(String? url) {
    if (url == null || url.trim().isEmpty) return null;

    final cleanUrl = url.trim();

    // الصيغة 1: /file/d/FILE_ID/
    final match1 = RegExp(r'/file/d/([a-zA-Z0-9_-]+)').firstMatch(cleanUrl);
    if (match1 != null) return match1.group(1);

    // الصيغة 2: ?id=FILE_ID أو &id=FILE_ID
    final match2 = RegExp(r'[?&]id=([a-zA-Z0-9_-]+)').firstMatch(cleanUrl);
    if (match2 != null) return match2.group(1);

    // الصيغة 3: /folders/FILE_ID
    final match3 = RegExp(r'/folders/([a-zA-Z0-9_-]+)').firstMatch(cleanUrl);
    if (match3 != null) return match3.group(1);

    // الصيغة 4: drive.google.com/d/FILE_ID
    final match4 = RegExp(r'drive\.google\.com/d/([a-zA-Z0-9_-]+)').firstMatch(cleanUrl);
    if (match4 != null) return match4.group(1);

    // الصيغة 5: docs.google.com/document/d/FILE_ID
    final match5 = RegExp(r'docs\.google\.com/\w+/d/([a-zA-Z0-9_-]+)').firstMatch(cleanUrl);
    if (match5 != null) return match5.group(1);

    // الصيغة 6: رابط مختصر goo.gl/...
    // لا يمكن استخراجه مباشرة دون اتصال — يُعامل كـ needs_review

    return null;
  }

  /// هل الرابط رابط Google Drive؟
  static bool isDriveUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    return url.contains('drive.google.com') || url.contains('docs.google.com');
  }

  /// توليد رابط الصورة المصغرة من FILE_ID
  static String? getThumbnailUrl(String? fileId) {
    if (fileId == null || fileId.isEmpty) return null;
    return 'https://drive.google.com/thumbnail?id=$fileId&sz=w500';
  }

  /// توليد رابط تحميل/تضمين PDF من FILE_ID
  static String getNormalizedUrl(String? fileId) {
    if (fileId == null || fileId.isEmpty) return '';
    return 'https://drive.google.com/file/d/$fileId/view';
  }

  /// تحديد حالة الرابط بدون اتصال بالإنترنت (تحليل الرابط فقط)
  static String getUrlStatus(String? url) {
    if (url == null || url.trim().isEmpty) return statusEmpty;
    if (!isDriveUrl(url)) return statusUnknownFormat;
    final fileId = extractFileId(url);
    if (fileId == null) return statusUnknownFormat;
    return statusValid; // يُعتبر صالحاً من حيث الصيغة
  }

  /// ترجمة حالة الرابط إلى نص عربي
  static String statusToArabic(String status) {
    switch (status) {
      case statusValid:
        return 'صالح';
      case statusPrivate:
        return 'ملف خاص';
      case statusNeedsLogin:
        return 'يحتاج تسجيل دخول';
      case statusUnknownFormat:
        return 'صيغة غير معروفة';
      case statusInvalid:
        return 'رابط غير صالح';
      case statusEmpty:
        return 'رابط فارغ';
      case statusChecking:
        return 'جارٍ التحقق';
      case statusNeedsReview:
        return 'يحتاج مراجعة';
      default:
        return 'غير محدد';
    }
  }
}
