// services/results_service.dart
// نظام ذكي لجلب وتخزين نتائج المسابقات مع Cache بالملفات (أداء أعلى)
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';

enum ExamType { concours, brevet, bac, complementary, excellence }

class StudentResult {
  final String id;
  final String name;
  final String school;
  final String center;
  final String wilaya;

  /// score: مجموع Concours (0–200) أو معدل (0–20)
  final double? score;

  /// averageScore: المعدل الحقيقي (0–20)
  final double? averageScore;

  final String status;
  final String rank;

  /// nationalRank: الترتيب الوطني العام — للبكالوريا
  final String nationalRank;

  final String branch;
  final Map<String, String> rawData;

  const StudentResult({
    required this.id,
    required this.name,
    required this.school,
    required this.center,
    required this.wilaya,
    this.score,
    this.averageScore,
    required this.status,
    this.rank = '',
    this.nationalRank = '',
    this.branch = '',
    required this.rawData,
  });

  // ─── Flexible column mapping ───────────────────────────────────────────────

  /// ابحث عن أول قيمة غير فارغة تطابق أحد المفاتيح (case‑insensitive partial match)
  static String _findField(Map<String, String> row, List<String> keys) {
    for (final k in keys) {
      for (final entry in row.entries) {
        final entryKeyLower = entry.key
            .toLowerCase()
            .trim()
            .replaceAll('"', '')
            .replaceAll('\u00a0', '');
        if (entryKeyLower.contains(k.toLowerCase()) &&
            entry.value.trim().isNotEmpty &&
            entry.value.trim() != 'null' &&
            entry.value.trim() != 'NULL') {
          return entry.value.trim();
        }
      }
    }
    return '';
  }

  /// ابحث عن أول قيمة عددية صالحة
  static double? _findNumericField(Map<String, String> row, List<String> keys) {
    final str = _findField(row, keys);
    if (str.isEmpty) return null;
    try {
      final cleaned = str
          .replaceAll(',', '.')
          .replaceAll('٫', '.')
          .replaceAll('\u00a0', '')
          .replaceAll(' ', '');
      return double.parse(cleaned);
    } catch (_) {
      return null;
    }
  }

  factory StudentResult.fromCsv(Map<String, String> row, ExamType type) {
    // ─── الاسم والرقم ─────────────────────────────────────────────────────
    String name = _findField(row, ['nom_prenom', 'prenom_nom', 'name', 'الاسم']);
    if (name.isEmpty) {
      final prenom = _findField(row, ['prenom', 'prénom', 'الاسم الاول']);
      final nom = _findField(row, ['nom', 'الاسم العائلي', 'لقب']);
      if (prenom.isNotEmpty && nom.isNotEmpty) {
        name = '$prenom $nom';
      } else if (prenom.isNotEmpty) {
        name = prenom;
      } else if (nom.isNotEmpty) {
        name = nom;
      }
    }
    final id = _findField(
        row, ['num', 'matricule', 'numéro', 'numero', 'code', 'noreg', 'رقم']);

    // ─── المدرسة والمركز والولاية ─────────────────────────────────────────
    final school = _findField(
        row, ['école', 'ecole', 'etablissement', 'établissement', 'مدرسة', 'school']);
    final center = _findField(row, ['centre', 'مركز', 'center']);
    final wilaya = _findField(row, ['wilaya', 'ولاية']);
    final branch = _findField(
        row, ['filière', 'filiere', 'série', 'serie', 'specialite', 'شعبة', 'type']);

    // ─── المجموع / المعدل ─────────────────────────────────────────────────
    double? score;
    double? averageScore;

    if (type == ExamType.excellence) {
      // الامتياز: المعدل موجود في Mgex
      score = _findNumericField(row, ['mgex']);
      averageScore = score;
    } else if (type == ExamType.concours) {
      // Concours: المجموع موجود في TOTAL
      score = _findNumericField(row, ['total']);
      // إذا لم يتم العثور على المجموع، ابحث كاحتياط
      score ??= _findNumericField(
          row, ['somme', 'sum', 'note', 'score', 'مجموع', 'مجموع_النقاط']);
          
      if (score == null) {
        for (final entry in row.entries) {
          final v = _parseDouble(entry.value);
          if (v != null && v > 20) {
            score = v;
            break;
          }
        }
      }
      averageScore = score != null ? (score / 200.0 * 20.0) : null;
    } else if (type == ExamType.brevet) {
      // Brevet: المعدل موجود في Moyg
      score = _findNumericField(row, ['moyg']);
      score ??= _findNumericField(row, ['moyenne', 'moy', 'average', 'avg', 'معدل']);
      averageScore = score;
    } else if (type == ExamType.bac) {
      // Bac: المعدل موجود في Moy_Bac
      score = _findNumericField(row, ['moy_bac']);
      score ??= _findNumericField(row, ['moyenne', 'moy', 'average', 'avg', 'معدل']);
      averageScore = score;
    } else if (type == ExamType.complementary) {
      // Bac Complementary: المعدل موجود في MOY_BAC_SESSION
      score = _findNumericField(row, ['moy_bac_session']);
      score ??= _findNumericField(row, ['moyenne', 'moy', 'average', 'avg', 'معدل']);
      averageScore = score;
    }

    // ─── الحالة ─────────────────────────────────────────────────────────
    final rawStatus = _findField(
        row, ['status', 'statut', 'resultat', 'résultat', 'decision', 'décision', 'حالة']);

    String status = _normalizeStatus(rawStatus, type);

    if (type == ExamType.concours) {
      if (status.isEmpty) {
        if (score != null) {
          status = score >= 85.0 ? 'ناجح' : 'راسب';
        } else {
          status = 'راسب';
        }
      }
    } else if (type == ExamType.excellence) {
      if (status.isEmpty) {
        status = (score != null && score >= 10.0) ? 'ناجح' : 'راسب';
      }
    } else if (type == ExamType.bac) {
      if (status.isEmpty) {
        if (score != null) {
          status = score >= 10.0 ? 'ناجح' : 'راسب';
        } else {
          status = 'راسب';
        }
      }
    } else if (type == ExamType.complementary) {
      if (status.isEmpty || status == 'الدورة التكميلية') {
        if (score != null) {
          status = score >= 10.0 ? 'ناجح' : 'راسب';
        } else {
          status = 'راسب';
        }
      }
    } else if (type == ExamType.brevet) {
      if (status.isEmpty) {
        if (score != null) {
          status = score >= 10.0 ? 'ناجح' : 'راسب';
        } else {
          status = 'راسب';
        }
      }
    } else {
      if (status.isEmpty) {
        status = (score != null && score >= 10.0) ? 'ناجح' : 'راسب';
      }
    }

    // الترتيب من CSV (إن وُجد)
    final csvRank = _findField(row, ['rang', 'classement', 'rang_wilaya', 'ترتيب']);

    return StudentResult(
      id: id,
      name: name,
      school: school,
      center: center,
      wilaya: wilaya,
      score: score,
      averageScore: averageScore,
      status: status,
      rank: csvRank,
      nationalRank: '',
      branch: branch,
      rawData: row,
    );
  }

  static double? _parseDouble(String s) {
    try {
      final cleaned = s
          .trim()
          .replaceAll(',', '.')
          .replaceAll('٫', '.')
          .replaceAll('\u00a0', '')
          .replaceAll(' ', '');
      if (cleaned.isEmpty) return null;
      return double.parse(cleaned);
    } catch (_) {
      return null;
    }
  }

  static String _normalizeStatus(String status, ExamType type) {
    final lower = status.toLowerCase().trim();
    if (lower.isEmpty) return '';

    // الناجحون
    if (lower.contains('admis') ||
        lower.contains('recu') ||
        lower.contains('reçu') ||
        lower.contains('ناجح') ||
        lower.contains('admissible') && type != ExamType.bac ||
        lower.contains('naajeh')) {
      return 'ناجح';
    }

    // الغائبون
    if (lower.contains('absent') || lower.contains('غائب') || lower == 'abs') {
      return 'غائب';
    }

    // المطرودون
    if (lower.contains('exclu') || lower.contains('مطرود') || lower.contains('expuls')) {
      return 'مطرود';
    }

    // الدورة التكميلية — حصرياً للبكالوريا الدورة العادية فقط!
    if (type == ExamType.bac) {
      if (lower.contains('complémentaire') ||
          lower.contains('complementaire') ||
          lower.contains('تكميلي') ||
          lower.contains('sessionnaire') ||
          lower.contains('rattrapage') ||
          lower.contains('session') ||
          lower.contains('ajourne') ||
          lower.contains('ajourné')) {
        return 'الدورة التكميلية';
      }
    }

    // الراسبون (في الكونكور والابريفة وغيرها، ajourné تعني راسب فقط)
    if (lower.contains('راسب') ||
        lower.contains('refusé') ||
        lower.contains('refuse') ||
        lower.contains('ajourne') ||
        lower.contains('ajourné') ||
        lower.contains('non admis') ||
        lower.contains('echec') ||
        lower.contains('échec')) {
      return 'راسب';
    }

    return '';
  }

  bool get isPassed => status == 'ناجح';
  bool get isFailed => status == 'راسب';
  bool get isAbsent => status == 'غائب';
  bool get isComplementary => status == 'تكميلي' || status == 'الدورة التكميلية' || status == 'مؤهل للدورة التكميلية';
  bool get isExpelled => status == 'مطرود';

  /// النقطة المستخدمة للترتيب
  double? get sortScore => score;

  /// النقطة المستخدمة للامتياز (دائماً /20)
  double? get excellenceScore => averageScore;
}

// ─── Cache Metadata ────────────────────────────────────────────────────────

class _CacheMeta {
  final String url;
  final int fetchedAtMs;
  final int contentHash;
  final int count;

  _CacheMeta({
    required this.url,
    required this.fetchedAtMs,
    required this.contentHash,
    required this.count,
  });

  Map<String, dynamic> toJson() => {
        'url': url,
        'fetchedAtMs': fetchedAtMs,
        'contentHash': contentHash,
        'count': count,
      };

  factory _CacheMeta.fromJson(Map<String, dynamic> j) => _CacheMeta(
        url: j['url'] as String? ?? '',
        fetchedAtMs: j['fetchedAtMs'] as int? ?? 0,
        contentHash: j['contentHash'] as int? ?? 0,
        count: j['count'] as int? ?? 0,
      );
}

// ─── ResultsService ────────────────────────────────────────────────────────

class ResultsService {
  // نستخدم ملفات على القرص لـ Cache البيانات الكبيرة بدل SharedPreferences
  static const _metaPrefix = 'rc_meta_v5_'; // v5 = file-based

  /// 30 دقيقة: Soft Expiry
  static const _cacheSoftMs = 30 * 60 * 1000;

  /// 7 أيام: Hard Expiry
  static const _cacheHardMs = 7 * 24 * 60 * 60 * 1000;

  static final Map<String, List<StudentResult>> _memCache = {};
  static final Map<String, Completer<List<StudentResult>>> _inFlight = {};

  // ─── احصل على مجلد الـ Cache ─────────────────────────────────────────────
  static Future<Directory> _getCacheDir() async {
    final base = await getApplicationCacheDirectory();
    final dir = Directory('${base.path}/results_cache');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  static File _cacheFile(String cacheKey, Directory dir) =>
      File('${dir.path}/$cacheKey.json');

  // ─── Public API ─────────────────────────────────────────────────────────

  static Future<List<StudentResult>> fetchResults(
    ExamType type,
    String url, {
    bool forceRefresh = false,
    void Function(List<StudentResult>)? onUpdate,
  }) async {
    if (url.isEmpty) return [];

    final cacheKey = '${type.name}_${url.hashCode}';

    try {
      // طلب مماثل قيد التنفيذ
      if (_inFlight.containsKey(cacheKey)) {
        return await _inFlight[cacheKey]!.future;
      }

      // ذاكرة الجلسة
      if (!forceRefresh && _memCache.containsKey(cacheKey)) {
        final cached = _memCache[cacheKey]!;
        _backgroundRefreshIfNeeded(cacheKey, type, url, onUpdate);
        return cached;
      }

      // Disk Cache
      if (!forceRefresh) {
        final diskResult = await _readDiskCache(cacheKey, type, url);
        if (diskResult != null) {
          _memCache[cacheKey] = diskResult;
          _backgroundRefreshIfNeeded(cacheKey, type, url, onUpdate);
          return diskResult;
        }
      }

      // شبكة
      return await _fetchFromNetwork(cacheKey, type, url, onUpdate);
    } catch (e) {
      // ملاذ أخير: Cache قديم
      try {
        final old = await _readDiskCacheAnyAge(cacheKey);
        if (old != null && old.isNotEmpty) {
          _memCache[cacheKey] = old;
          return old;
        }
      } catch (_) {}
      rethrow;
    }
  }

  static Future<void> clearResultsCache() async {
    _memCache.clear();
    _inFlight.clear();
    try {
      // حذف ملفات الـ Cache
      final dir = await _getCacheDir();
      for (final file in dir.listSync()) {
        if (file is File) file.deleteSync();
      }
    } catch (_) {}
    try {
      // حذف metadata من SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs
          .getKeys()
          .where((k) => k.startsWith(_metaPrefix))
          .toList();
      for (final k in keys) {
        await prefs.remove(k);
      }
    } catch (_) {}
  }

  static Future<void> clearCacheForUrl(ExamType type, String url) async {
    if (url.isEmpty) return;
    final cacheKey = '${type.name}_${url.hashCode}';
    _memCache.remove(cacheKey);
    try {
      _deleteCacheFileQuietly(cacheKey);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_metaPrefix + cacheKey);
    } catch (_) {}
  }

  // ─── Private helpers ─────────────────────────────────────────────────

  static Future<List<StudentResult>?> _readDiskCache(
      String cacheKey, ExamType type, String url) async {
    try {
      // قراءة metadata من SharedPreferences (صغيرة = مناسبة)
      final prefs = await SharedPreferences.getInstance();
      final metaStr = prefs.getString(_metaPrefix + cacheKey);
      if (metaStr == null) return null;

      final meta =
          _CacheMeta.fromJson(jsonDecode(metaStr) as Map<String, dynamic>);

      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - meta.fetchedAtMs > _cacheHardMs) {
        // انتهى الـ cache — احذف الملف أيضاً
        _deleteCacheFileQuietly(cacheKey);
        await prefs.remove(_metaPrefix + cacheKey);
        return null;
      }

      if (meta.url != url) return null;

      // قراءة البيانات من ملف على القرص
      final dir = await _getCacheDir();
      final file = _cacheFile(cacheKey, dir);
      if (!file.existsSync()) return null;

      final dataStr = await file.readAsString();
      final results = await compute(_decodeCacheIsolated, dataStr);
      return results;
    } catch (_) {
      return null;
    }
  }

  static void _backgroundRefreshIfNeeded(
    String cacheKey,
    ExamType type,
    String url,
    void Function(List<StudentResult>)? onUpdate,
  ) {
    if (onUpdate == null) return;
    _checkSoftExpiry(cacheKey).then((expired) {
      if (expired) {
        _fetchFromNetworkBackground(cacheKey, type, url, onUpdate);
      }
    });
  }

  static Future<bool> _checkSoftExpiry(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metaStr = prefs.getString(_metaPrefix + cacheKey);
      if (metaStr == null) return true;
      final meta =
          _CacheMeta.fromJson(jsonDecode(metaStr) as Map<String, dynamic>);
      final now = DateTime.now().millisecondsSinceEpoch;
      return (now - meta.fetchedAtMs) > _cacheSoftMs;
    } catch (_) {
      return true;
    }
  }

  static Future<void> _fetchFromNetworkBackground(
    String cacheKey,
    ExamType type,
    String url,
    void Function(List<StudentResult>) onUpdate,
  ) async {
    if (_inFlight.containsKey(cacheKey)) return;
    try {
      final body = await _downloadCsv(url);
      if (body == null) return;

      final newHash = body.hashCode;
      final prefs = await SharedPreferences.getInstance();
      final metaStr = prefs.getString(_metaPrefix + cacheKey);
      if (metaStr != null) {
        try {
          final meta = _CacheMeta.fromJson(
              jsonDecode(metaStr) as Map<String, dynamic>);
          if (meta.contentHash == newHash) return;
        } catch (_) {}
      }

      final results = await _parseCsvAsync(body, type);
      await _saveToDiskCache(
          cacheKey, type, url, results, newHash, body.length);
      _memCache[cacheKey] = results;
      onUpdate(results);
    } catch (_) {
      // صمت تام في الخلفية
    }
  }

  static Future<List<StudentResult>> _fetchFromNetwork(
    String cacheKey,
    ExamType type,
    String url,
    void Function(List<StudentResult>)? onUpdate,
  ) async {
    final completer = Completer<List<StudentResult>>();
    _inFlight[cacheKey] = completer;

    try {
      final body = await _downloadCsv(url);
      if (body == null) {
        completer.complete([]);
        return [];
      }

      final results = await _parseCsvAsync(body, type);
      await _saveToDiskCache(
          cacheKey, type, url, results, body.hashCode, body.length);
      _memCache[cacheKey] = results;
      completer.complete(results);
      onUpdate?.call(results);
      return results;
    } catch (e) {
      try {
        final old = await _readDiskCacheAnyAge(cacheKey);
        if (old != null && old.isNotEmpty) {
          _memCache[cacheKey] = old;
          completer.complete(old);
          return old;
        }
      } catch (_) {}
      completer.completeError(e);
      rethrow;
    } finally {
      _inFlight.remove(cacheKey);
    }
  }

  static Future<List<StudentResult>?> _readDiskCacheAnyAge(
      String cacheKey) async {
    try {
      final dir = await _getCacheDir();
      final file = _cacheFile(cacheKey, dir);
      if (!file.existsSync()) return null;
      final dataStr = await file.readAsString();
      final results = await compute(_decodeCacheIsolated, dataStr);
      return results;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _downloadCsv(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url), headers: {
            'Accept': 'text/csv,text/plain,*/*',
            'Cache-Control': 'no-cache',
          })
          .timeout(const Duration(seconds: 20)); // كان 30 — أسرع

      if (response.statusCode != 200) return null;

      // Offload decoding to isolate to prevent main thread freezing
      return await compute(_decodeResponseBytes, response.bodyBytes);
    } catch (_) {
      return null;
    }
  }

  static String? _decodeResponseBytes(List<int> bytes) {
    try {
      final body = utf8.decode(bytes);
      if (_looksLikeCsv(body)) return body;
    } catch (_) {}

    try {
      final body = latin1.decode(bytes);
      if (_looksLikeCsv(body)) return body;
    } catch (_) {}

    return null;
  }

  static bool _looksLikeCsv(String s) {
    if (s.isEmpty) return false;
    final firstLine = s.split('\n').first;
    return firstLine.contains(',') || firstLine.contains(';');
  }

  static Future<List<StudentResult>> _parseCsvAsync(
      String csv, ExamType type) async {
    try {
      return await compute(
          _parseCsvIsolated, {'csv': csv, 'type': type});
    } catch (e) {
      // إذا فشل الـ Isolate، حلّل في الـ main thread
      try {
        return _parseCsv(csv, type);
      } catch (_) {
        return [];
      }
    }
  }

  static List<StudentResult> _parseCsvIsolated(Map<String, dynamic> args) {
    try {
      final csv = args['csv'] as String;
      final type = args['type'] as ExamType;
      return _parseCsv(csv, type);
    } catch (_) {
      return [];
    }
  }

  static List<StudentResult> _parseCsv(String csv, ExamType type) {
    try {
      String cleaned = csv;
      // إزالة BOM
      if (cleaned.startsWith('\uFEFF')) cleaned = cleaned.substring(1);

      final lines = cleaned.split('\n');
      if (lines.isEmpty) return [];

      final firstLine = lines[0];
      final separator = firstLine.contains(';') ? ';' : ',';

      final headers = _splitLine(lines[0], separator);
      if (headers.isEmpty) return [];

      final results = <StudentResult>[];

      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        if (line.replaceAll(separator, '').trim().isEmpty) continue;

        try {
          final values = _splitLine(line, separator);
          final row = <String, String>{};
          for (int j = 0; j < headers.length; j++) {
            final key = headers[j].trim().replaceAll('"', '').trim();
            final val =
                j < values.length ? values[j].trim().replaceAll('"', '').trim() : '';
            if (key.isNotEmpty) row[key] = val;
          }

          final student = StudentResult.fromCsv(row, type);
          // تجاهل صفوف فارغة تماماً
          if (student.name.isEmpty &&
              student.id.isEmpty &&
              student.score == null) {
            continue;
          }
          results.add(student);
        } catch (_) {
          continue;
        }
      }

      return _assignRanks(results, type);
    } catch (_) {
      return [];
    }
  }

  // ─── ترتيب النتائج — مهم جداً ─────────────────────────────────────────
  // القاعدة: الناجحون دائماً أولاً مرتبون من الأعلى للأدنى
  //           ثم بقية الحالات (تكميلي، غائب، مطرود، راسب) مرتبون أيضاً
  static List<StudentResult> _assignRanks(
      List<StudentResult> results, ExamType type) {
    if (results.isEmpty) return results;

    try {
      if (type == ExamType.bac || type == ExamType.complementary) {
        return _assignRanksBac(results);
      } else {
        return _assignRanksGeneral(results, type);
      }
    } catch (_) {
      return results;
    }
  }

  /// ترتيب BAC: ناجح وطنياً أولاً ← ثم حسب الشعبة
  static List<StudentResult> _assignRanksBac(List<StudentResult> results) {
    // فصل الناجحين عن البقية
    final passed = results.where((r) => r.isPassed).toList();
    final others = results.where((r) => !r.isPassed).toList();

    // ترتيب الناجحين حسب المعدل (تنازلياً)
    passed.sort((a, b) => (b.score ?? -1).compareTo(a.score ?? -1));
    // ترتيب البقية (تكميلي، غائب، راسب) حسب المعدل (تنازلياً)
    others.sort((a, b) => (b.score ?? -1).compareTo(a.score ?? -1));

    // إسناد الترتيب الوطني للناجحين فقط
    final passedWithNational = <StudentResult>[];
    for (int i = 0; i < passed.length; i++) {
      final r = passed[i];
      passedWithNational.add(StudentResult(
        id: r.id,
        name: r.name,
        school: r.school,
        center: r.center,
        wilaya: r.wilaya,
        score: r.score,
        averageScore: r.averageScore,
        status: r.status,
        rank: r.rank,
        nationalRank: (i + 1).toString(),
        branch: r.branch,
        rawData: r.rawData,
      ));
    }

    // ترتيب حسب الشعبة وإسناد ترتيب الشعبة
    final grouped = <String, List<StudentResult>>{};
    for (final r in passedWithNational) {
      grouped.putIfAbsent(r.branch, () => []).add(r);
    }

    final finalPassed = <StudentResult>[];
    for (final entry in grouped.entries) {
      final branchList = List<StudentResult>.from(entry.value)
        ..sort((a, b) => (b.score ?? -1).compareTo(a.score ?? -1));
      for (int i = 0; i < branchList.length; i++) {
        final r = branchList[i];
        finalPassed.add(StudentResult(
          id: r.id,
          name: r.name,
          school: r.school,
          center: r.center,
          wilaya: r.wilaya,
          score: r.score,
          averageScore: r.averageScore,
          status: r.status,
          rank: (i + 1).toString(), // ترتيب الشعبة
          nationalRank: r.nationalRank,
          branch: r.branch,
          rawData: r.rawData,
        ));
      }
    }

    // إسناد ترتيب للراسبين والبقية
    final othersWithRank = <StudentResult>[];
    for (int i = 0; i < others.length; i++) {
      final r = others[i];
      othersWithRank.add(StudentResult(
        id: r.id,
        name: r.name,
        school: r.school,
        center: r.center,
        wilaya: r.wilaya,
        score: r.score,
        averageScore: r.averageScore,
        status: r.status,
        rank: r.rank,
        nationalRank: '',
        branch: r.branch,
        rawData: r.rawData,
      ));
    }

    // ترتيب العرض النهائي: ناجح أولاً ← مرتب حسب الترتيب الوطني
    final sortedPassed = List<StudentResult>.from(finalPassed)
      ..sort((a, b) {
        final na = int.tryParse(a.nationalRank) ?? 999999;
        final nb = int.tryParse(b.nationalRank) ?? 999999;
        return na.compareTo(nb);
      });

    return [...sortedPassed, ...othersWithRank];
  }

  /// ترتيب عام (Concours + Brevet): ناجح أولاً ← مرتب حسب score
  static List<StudentResult> _assignRanksGeneral(
      List<StudentResult> results, ExamType type) {
    // فصل الناجحين
    final passed = results.where((r) => r.isPassed).toList();
    final others = results.where((r) => !r.isPassed).toList();

    // ترتيب تنازلياً
    passed.sort((a, b) => (b.score ?? -1).compareTo(a.score ?? -1));
    others.sort((a, b) => (b.score ?? -1).compareTo(a.score ?? -1));

    // إسناد الترتيبات للناجحين
    final passedWithRank = <StudentResult>[];
    for (int i = 0; i < passed.length; i++) {
      final r = passed[i];
      passedWithRank.add(StudentResult(
        id: r.id,
        name: r.name,
        school: r.school,
        center: r.center,
        wilaya: r.wilaya,
        score: r.score,
        averageScore: r.averageScore,
        status: r.status,
        rank: (i + 1).toString(),
        nationalRank: (i + 1).toString(),
        branch: r.branch,
        rawData: r.rawData,
      ));
    }

    // إسناد ترتيبات للراسبين (تبدأ بعد الناجحين)
    final othersWithRank = <StudentResult>[];
    for (int i = 0; i < others.length; i++) {
      final r = others[i];
      othersWithRank.add(StudentResult(
        id: r.id,
        name: r.name,
        school: r.school,
        center: r.center,
        wilaya: r.wilaya,
        score: r.score,
        averageScore: r.averageScore,
        status: r.status,
        rank: r.rank, // لا نعطيهم ترتيباً جديداً
        nationalRank: '',
        branch: r.branch,
        rawData: r.rawData,
      ));
    }

    return [...passedWithRank, ...othersWithRank];
  }

  static List<String> _splitLine(String line, String sep) {
    if (line.isEmpty) return [];
    if (!line.contains('"')) {
      return line.split(sep);
    }
    final result = <String>[];
    bool inQuotes = false;
    final buf = StringBuffer();
    final len = line.length;
    for (int i = 0; i < len; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == sep && !inQuotes) {
        result.add(buf.toString());
        buf.clear();
      } else {
        buf.write(char);
      }
    }
    result.add(buf.toString());
    return result;
  }

  // ─── Disk Cache I/O ────────────────────────────────────────────────────

  static Future<void> _saveToDiskCache(
    String cacheKey,
    ExamType type,
    String url,
    List<StudentResult> results,
    int contentHash,
    int contentLength,
  ) async {
    try {
      // حفظ metadata الصغيرة في SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final meta = _CacheMeta(
        url: url,
        fetchedAtMs: DateTime.now().millisecondsSinceEpoch,
        contentHash: contentHash,
        count: results.length,
      );
      await prefs.setString(
          _metaPrefix + cacheKey, jsonEncode(meta.toJson()));

      // حفظ البيانات الكبيرة في ملف على القرص (أسرع بكثير)
      final jsonString = await compute(_encodeCacheIsolated, results);
      final dir = await _getCacheDir();
      final file = _cacheFile(cacheKey, dir);
      await file.writeAsString(jsonString);
    } catch (_) {
      // فشل الحفظ لا يوقف التطبيق
    }
  }

  static void _deleteCacheFileQuietly(String cacheKey) {
    _getCacheDir().then((dir) {
      final file = _cacheFile(cacheKey, dir);
      if (file.existsSync()) file.deleteSync();
    }).catchError((_) {});
  }

  static Map<String, dynamic> _toJson(StudentResult r) => {
        'id': r.id,
        'name': r.name,
        'school': r.school,
        'center': r.center,
        'wilaya': r.wilaya,
        'score': r.score,
        'averageScore': r.averageScore,
        'status': r.status,
        'rank': r.rank,
        'nationalRank': r.nationalRank,
        'branch': r.branch,
        'rawData': r.rawData,
      };

  static StudentResult _fromJson(Map<String, dynamic> j) => StudentResult(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        school: j['school'] as String? ?? '',
        center: j['center'] as String? ?? '',
        wilaya: j['wilaya'] as String? ?? '',
        score: j['score'] != null ? (j['score'] as num).toDouble() : null,
        averageScore: j['averageScore'] != null
            ? (j['averageScore'] as num).toDouble()
            : null,
        status: j['status'] as String? ?? 'راسب',
        rank: j['rank'] as String? ?? '',
        nationalRank: j['nationalRank'] as String? ?? '',
        branch: j['branch'] as String? ?? '',
        rawData: Map<String, String>.from(
            (j['rawData'] as Map<String, dynamic>? ?? {}).map(
                (k, v) => MapEntry(k, v?.toString() ?? ''))),
      );

  static List<StudentResult> _decodeCacheIsolated(String dataStr) {
    try {
      final List decoded = jsonDecode(dataStr) as List;
      return decoded
          .map((e) => _fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static String _encodeCacheIsolated(List<StudentResult> results) {
    try {
      return jsonEncode(results.map(_toJson).toList());
    } catch (_) {
      return '[]';
    }
  }

  // ─── Cache Info ─────────────────────────────────────────────────────────

  static Future<bool> isCacheStale(ExamType type, String url) async {
    if (url.isEmpty) return false;
    final cacheKey = '${type.name}_${url.hashCode}';
    return _checkSoftExpiry(cacheKey);
  }

  static Future<DateTime?> lastUpdated(ExamType type, String url) async {
    if (url.isEmpty) return null;
    try {
      final cacheKey = '${type.name}_${url.hashCode}';
      final prefs = await SharedPreferences.getInstance();
      final metaStr = prefs.getString(_metaPrefix + cacheKey);
      if (metaStr == null) return null;
      final meta =
          _CacheMeta.fromJson(jsonDecode(metaStr) as Map<String, dynamic>);
      return DateTime.fromMillisecondsSinceEpoch(meta.fetchedAtMs);
    } catch (_) {
      return null;
    }
  }
}
