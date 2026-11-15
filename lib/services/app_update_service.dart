import 'dart:async';
import 'dart:convert';
import 'dart:io';
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

  /// جلب ملف update.json من الرابط الأساسي أو الاحتياطي
  Future<AppUpdateInfo?> _fetchUpdateInfo() async {
    // محاولة جلب الملف من Firebase Hosting
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

    // محاولة جلب الملف من الرابط الاحتياطي (GitHub)
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

  /// تنزيل ملف الـ APK وتثبيته مباشرة عبر Intent
  Future<void> downloadAndInstallApk({
    required String apkUrl,
    required void Function(double progress, int received, int total) onProgress,
    required void Function(String error) onError,
    required void Function() onCompleted,
  }) async {
    if (kIsWeb) return;

    try {
      // 1) التحقق من الصلاحيات وتجهيز المجلد
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

      // 2) بدء التنزيل مع تتبع نسبة التقدم لحظياً
      await _dio.download(
        apkUrl,
        savePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = (received / total).clamp(0.0, 1.0);
            onProgress(progress, received, total);
          } else {
            onProgress(-1.0, received, total);
          }
        },
      );

      // 3) التحقق من الملف بعد التنزيل
      if (!await file.exists() || await file.length() == 0) {
        onError('الملف الذي تم تنزيله غير مكتمل أو تالف.');
        return;
      }

      onCompleted();

      // 4) إطلاق أمر التثبيت التلقائي (Install APK Intent)
      final result = await OpenFilex.open(
        savePath,
        type: 'application/vnd.android.package-archive',
      );

      debugPrint('[AppUpdateService] OpenFilex result: ${result.message} (${result.type})');

      if (result.type != ResultType.done) {
        // محاولة ثانية بدون تحديد النوع إذا لزم الأمر
        await OpenFilex.open(savePath);
      }
    } catch (e) {
      if (CancelToken.isCancel(e as dynamic)) {
        debugPrint('[AppUpdateService] Download canceled by user.');
        return;
      }
      debugPrint('[AppUpdateService] Download & install error: $e');
      onError('فشل تنزيل ملف التحديث: $e');
    }
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
