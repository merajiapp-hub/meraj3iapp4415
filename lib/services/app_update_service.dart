import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import '../models/app_update_info.dart';
import '../widgets/app_update_dialog.dart';

/// خدمة التحديث التلقائي الداخلي لتطبيق مراجعي
class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._internal();
  factory AppUpdateService() => _instance;
  AppUpdateService._internal();

  /// الرابط الأساسي لملف update.json المستضاف على Firebase Hosting
  static const String primaryUpdateUrl = 'https://meraj3iapp.web.app/update.json';

  /// الرابط الاحتياطي لملف update.json من GitHub في حال عدم توفر الرابط الأساسي
  static const String fallbackUpdateUrl =
      'https://raw.githubusercontent.com/merajiapp-hub/meraj3iapp4415/main/update.json';

  final ShorebirdUpdater _shorebird = ShorebirdUpdater();
  final Dio _dio = Dio();
  CancelToken? _cancelToken;

  /// فحص تلقائي ذكي عند بدء التشغيل: يجمع بين Shorebird وتحديث الـ APK الكامل
  Future<void> checkOnStartup(BuildContext context) async {
    if (kIsWeb) return;

    // 1) فحص تحديثات Shorebird السريعة في الخلفية إن وُجدت
    _handleShorebirdSilentPatch();

    // 2) فحص التحديث الجذري للـ APK وإظهار نافذة الميزات الجديدة للمستخدم
    await Future.delayed(const Duration(seconds: 2));
    if (!context.mounted) return;
    await checkForUpdate(context, isManualCheck: false);
  }

  /// تنزيل التحديثات الجزئية الصامتة عبر Shorebird
  void _handleShorebirdSilentPatch() async {
    try {
      final status = await _shorebird.checkForUpdate();
      if (status == UpdateStatus.outdated) {
        debugPrint('[Shorebird] Downloading silent patch in background...');
        await _shorebird.update();
        debugPrint('[Shorebird] Patch downloaded successfully.');
      }
    } catch (e) {
      debugPrint('[Shorebird] CodePush check error: $e');
    }
  }

  /// طلب فحص التحديثات
  Future<AppUpdateInfo?> checkForUpdate(
    BuildContext context, {
    bool isManualCheck = false,
  }) async {
    if (kIsWeb) {
      if (isManualCheck && context.mounted) {
        _showToast(context, 'أنت تستخدم أحدث إصدار على الويب (محدّث تلقائياً) ✅');
      }
      return null;
    }

    try {
      final updateInfo = await _fetchUpdateInfo();
      if (updateInfo == null) {
        if (isManualCheck && context.mounted) {
          _showToast(context, 'تعذر التحقق من التحديثات، تحقق من الاتصال بالإنترنت.');
        }
        return null;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

      final hasUpdate = updateInfo.isUpdateAvailable(
        currentVersion: currentVersion,
        currentBuildNumber: currentBuild,
      );

      if (hasUpdate) {
        if (context.mounted) {
          showDialog<void>(
            context: context,
            barrierDismissible: !updateInfo.forceUpdate,
            builder: (ctx) => AppUpdateDialog(
              updateInfo: updateInfo,
              currentVersion: currentVersion,
              service: this,
            ),
          );
        }
        return updateInfo;
      } else {
        if (isManualCheck && context.mounted) {
          _showToast(context, 'أنت تستخدم أحدث إصدار من التطبيق ($currentVersion) ✅');
        }
      }
    } catch (e) {
      debugPrint('[AppUpdateService] Check update error: $e');
      if (isManualCheck && context.mounted) {
        _showToast(context, 'حدث خطأ أثناء فحص التحديثات.');
      }
    }
    return null;
  }

  /// جلب ملف update.json من الرابط الأساسي أو الاحتياطي أو Firestore
  Future<AppUpdateInfo?> _fetchUpdateInfo() async {
    // 1) محاولة جلب الملف من Firebase Hosting
    try {
      final response = await http
          .get(
            Uri.parse('$primaryUpdateUrl?t=${DateTime.now().millisecondsSinceEpoch}'),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        return AppUpdateInfo.fromJson(decoded as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('[AppUpdateService] Primary update fetch failed: $e');
    }

    // 2) محاولة جلب أحدث إصدار منشور مباشرة من قاعدة بيانات Firestore (لوحة الإدارة)
    try {
      final snap = await FirebaseFirestore.instance
          .collection('app_releases')
          .orderBy('releaseDate', descending: true)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 6));

      if (snap.docs.isNotEmpty) {
        final data = snap.docs.first.data();
        final version = data['version']?.toString() ?? '1.0.0';
        final notes = data['notes']?.toString() ?? '';
        final isMandatory = data['isMandatory'] == true;
        final apkUrl = data['apkUrl']?.toString() ??
            'https://github.com/merajiapp-hub/meraj3iapp4415/releases/latest/download/app-release.apk';
        final buildNumber = (data['buildNumber'] as num?)?.toInt() ?? 25;

        final lines = notes.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

        return AppUpdateInfo(
          latestVersion: version,
          latestBuildNumber: buildNumber,
          apkUrl: apkUrl,
          apkSize: data['apkSize']?.toString() ?? '65 MB',
          releaseDate: DateTime.now().toString().split(' ').first,
          forceUpdate: isMandatory,
          releaseNotes: lines.isNotEmpty ? lines : ['تحسينات في الأداء وتحديثات هامة'],
          githubReleaseUrl: 'https://github.com/merajiapp-hub/meraj3iapp4415/releases',
        );
      }
    } catch (e) {
      debugPrint('[AppUpdateService] Firestore app_releases fetch failed: $e');
    }

    // 3) محاولة جلب الملف من الرابط الاحتياطي (GitHub)
    try {
      final response = await http
          .get(
            Uri.parse('$fallbackUpdateUrl?t=${DateTime.now().millisecondsSinceEpoch}'),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        return AppUpdateInfo.fromJson(decoded as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('[AppUpdateService] Fallback update fetch failed: $e');
    }

    return null;
  }

  /// فحص وإجراء التحديث مع أولوية لـ Shorebird Code Push والتراجع الذكي
  Future<void> performUpdate({
    required String apkUrl,
    required void Function(String stepMessage, double progress, int received, int total) onProgress,
    required void Function(String error, {bool canOpenBrowser}) onError,
    required void Function({bool requiresRestart}) onCompleted,
  }) async {
    if (kIsWeb) {
      onCompleted(requiresRestart: false);
      return;
    }

    // 1) الأولوية الأولى: فحص وتثبيت تحديثات Shorebird Code Push اللحظية
    try {
      if (_shorebird.isAvailable) {
        onProgress('جارٍ فحص التحديثات الفورية (Shorebird)...', 0.25, 0, 0);
        final status = await _shorebird.checkForUpdate();
        debugPrint('[AppUpdateService] Shorebird check status: $status');

        if (status == UpdateStatus.outdated) {
          onProgress('جارٍ تنزيل وتثبيت التحديث تلقائياً...', 0.65, 0, 0);
          await _shorebird.update();
          onProgress('تم التثبيت بنجاح!', 1.0, 0, 0);
          onCompleted(requiresRestart: true);
          return;
        } else if (status == UpdateStatus.restartRequired) {
          onProgress('التحديث مثبت مسبقاً وبانتظار إعادة التشغيل.', 1.0, 0, 0);
          onCompleted(requiresRestart: true);
          return;
        }
      }
    } catch (e) {
      debugPrint('[AppUpdateService] Shorebird check/update error: $e');
    }

    // 2) التراجع الثاني: محاولة تنزيل ملف APK إن وجد رابط صالح
    if (apkUrl.isEmpty || !apkUrl.toLowerCase().contains('.apk')) {
      onError(
        'التحديث متوفر الآن! يمكنك تنزيل ملف APK مباشرة عبر المتصفح.',
        canOpenBrowser: true,
      );
      return;
    }

    try {
      if (Platform.isAndroid) {
        final status = await Permission.requestInstallPackages.status;
        if (status.isDenied) {
          await Permission.requestInstallPackages.request();
        }
      }

      final dir = await getExternalStorageDirectory() ?? await getTemporaryDirectory();
      final savePath = '${dir.path}/meraj3i_update.apk';

      final file = File(savePath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }

      _cancelToken = CancelToken();

      onProgress('جارٍ تنزيل ملف التحديث...', 0.05, 0, 0);

      await _dio.download(
        apkUrl,
        savePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = (received / total).clamp(0.0, 1.0);
            onProgress('جارٍ تنزيل ملف التحديث...', progress, received, total);
          } else {
            onProgress('جارٍ التنزيل...', -1.0, received, total);
          }
        },
      );

      if (!await file.exists() || await file.length() < 1000) {
        onError(
          'تعذر اكتمال تنزيل الملف، يمكنك تنزيل التحديث مباشرة عبر المتصفح.',
          canOpenBrowser: true,
        );
        return;
      }

      // التحقق من صحة ملف الـ APK عبر ترويسة ملفات ZIP (PK)
      final headerBytes = await file.openRead(0, 4).first;
      if (headerBytes.length >= 2 && (headerBytes[0] != 0x50 || headerBytes[1] != 0x4B)) {
        debugPrint('[AppUpdateService] Downloaded file is not a valid APK archive.');
        onError(
          'رابط ملف التحديث قيد التحديث. يمكنك تنزيل النسخة الجديدة مباشرة من المتصفح.',
          canOpenBrowser: true,
        );
        return;
      }

      onCompleted(requiresRestart: false);

      final result = await OpenFilex.open(
        savePath,
        type: 'application/vnd.android.package-archive',
      );

      debugPrint('[AppUpdateService] OpenFilex result: ${result.message} (${result.type})');

      if (result.type != ResultType.done) {
        await OpenFilex.open(savePath);
      }
    } catch (e) {
      if (CancelToken.isCancel(e as dynamic)) {
        debugPrint('[AppUpdateService] Download canceled by user.');
        return;
      }
      debugPrint('[AppUpdateService] Download & install error: $e');

      String friendlyMessage = 'تعذر التنزيل التلقائي. يمكنك التنزيل مباشرة عبر المتصفح.';
      if (e is DioException) {
        if (e.response?.statusCode == 404) {
          friendlyMessage = 'ملف التحديث قيد التجهيز على الخادم. يرجى التنزيل مباشرة من صفحة الإصدارات في المتصفح.';
        } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
          friendlyMessage = 'انتهت مهلة الاتصال بالخادم. يرجى التحقق من اتصال الإنترنت ثم المحاولة مجدداً.';
        } else if (e.type == DioExceptionType.connectionError) {
          friendlyMessage = 'تعذر الاتصال بالخادم. يرجى التحقق من اتصالك بالإنترنت.';
        }
      }
      onError(friendlyMessage, canOpenBrowser: true);
    }
  }

  /// تنزيل ملف الـ APK وتثبيته مباشرة عبر Intent (متوافق مع الاستدعاءات السابقة)
  Future<void> downloadAndInstallApk({
    required String apkUrl,
    required void Function(double progress, int received, int total) onProgress,
    required void Function(String error) onError,
    required void Function() onCompleted,
  }) async {
    await performUpdate(
      apkUrl: apkUrl,
      onProgress: (_, progress, received, total) => onProgress(progress, received, total),
      onError: (err, {bool canOpenBrowser = false}) => onError(err),
      onCompleted: ({bool requiresRestart = false}) => onCompleted(),
    );
  }

  /// إلغاء التنزيل
  void cancelDownload() {
    _cancelToken?.cancel('Canceled by user');
    _cancelToken = null;
  }

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Cairo')),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
