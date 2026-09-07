// services/remote_config_service.dart
// خدمة Firebase Remote Config — ديناميكية كاملة
// أي مفتاح جديد في competitions_data يظهر تلقائياً
import 'dart:async';
import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/competition_model.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._();
  static RemoteConfigService get instance => _instance;
  RemoteConfigService._();

  FirebaseRemoteConfig get _rc => FirebaseRemoteConfig.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _initialized = false;
  bool _initializing = false;
  final Completer<void> _initCompleter = Completer<void>();

  // Cache في الذاكرة
  List<CompetitionModel>? _cached;
  DateTime? _cachedAt;
  static const _cacheDuration = Duration(minutes: 10);

  // ─── بيانات احتياطية ───────────────────────────────────────────────
  static const Map<String, Map<String, dynamic>> _fallbackData = {
    'concours': {
      'title': 'كونكور 2026',
      'link':
          'https://docs.google.com/spreadsheets/d/1jMXqMtXHFdWdkzVz9OpYKr8XxUPfW3B0GQ2L7NvCeRI/export?format=csv&gid=361235812',
      'is_published': true,
      'order': 0,
    },
    'brevet': {
      'title': 'ابريفة 2026',
      'link':
          'https://docs.google.com/spreadsheets/d/1jMXqMtXHFdWdkzVz9OpYKr8XxUPfW3B0GQ2L7NvCeRI/export?format=csv&gid=1962707704',
      'is_published': true,
      'order': 1,
    },
    'bac': {
      'title': 'الباكلوريا – الدورة العادية',
      'link':
          'https://docs.google.com/spreadsheets/d/1jMXqMtXHFdWdkzVz9OpYKr8XxUPfW3B0GQ2L7NvCeRI/export?format=csv&gid=1215098731',
      'is_published': true,
      'order': 2,
    },
    'complementary': {
      'title': 'الباكلوريا – الدورة التكميلية',
      'link': '',
      'is_published': false,
      'order': 3,
    },
    'concours_excellence': {
      'title': '⭐ امتياز Concours',
      'link': '',
      'is_published': false,
      'order': 4,
    },
    'brevet_excellence': {
      'title': '⭐ امتياز Brevet',
      'link': '',
      'is_published': false,
      'order': 5,
    },
  };

  // ─── تهيئة مرة واحدة ──────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;
    if (_initializing) {
      await _initCompleter.future;
      return;
    }
    _initializing = true;

    try {
      await _rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 15),
          minimumFetchInterval: const Duration(minutes: 5),
        ),
      );
      await _rc.setDefaults({
        'competitions_data': jsonEncode(_buildDefaultJson()),
      });
      unawaited(_rc.fetchAndActivate());
    } catch (_) {
      // فشل التهيئة لا يوقف التطبيق
    } finally {
      _initialized = true;
      if (!_initCompleter.isCompleted) _initCompleter.complete();
      _initializing = false;
    }
  }

  // ─── جلب قائمة المسابقات — ديناميكي كامل ─────────────────────────

  /// يقرأ كل المفاتيح من Remote Config ويعرضها،
  /// بما فيها أي مفتاح جديد أضيف بعد إصدار التطبيق.
  Future<List<CompetitionModel>> fetchCompetitions({
    bool forceRefresh = false,
  }) async {
    // Cache
    if (!forceRefresh &&
        _cached != null &&
        _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < _cacheDuration) {
      return _cached!;
    }

    QuerySnapshot<Map<String, dynamic>>? firestoreSnapshot;
    try {
      // Read the collection first. The project contains documents written by
      // older admin versions, so filtering by one status field at query level
      // can hide valid competitions when the schemas are mixed.
      firestoreSnapshot = await _firestore
          .collection('competition_results')
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      firestoreSnapshot = null;
    }

    if (firestoreSnapshot != null) {
      final result =
          firestoreSnapshot.docs
              .map((doc) => CompetitionModel.fromJson(doc.id, doc.data()))
              .where(
                (competition) =>
                    competition.isPublished &&
                    _isValidLink(competition.link),
              )
              .toList()
            ..sort((a, b) {
              final order = a.order.compareTo(b.order);
              return order != 0 ? order : a.rawKey.compareTo(b.rawKey);
            });
      _cached = result;
      _cachedAt = DateTime.now();
      // Firestore is authoritative, including the legitimate empty state.
      return result;
    }

    try {
      if (!_initialized) await initialize();
      if (forceRefresh) await _rc.fetchAndActivate();

      final raw = _rc.getString('competitions_data');
      if (raw.isNotEmpty) {
        final Map<String, dynamic> parsed = jsonDecode(raw);
        final result = _parseAllCompetitions(parsed);
        _cached = result;
        _cachedAt = DateTime.now();
        return result;
      }
    } catch (_) {}

    final fallback = _fallbackCompetitions();
    _cached = fallback;
    _cachedAt = DateTime.now();
    return fallback;
  }

  static bool _isValidLink(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;
  }

  Future<void> refreshInBackground() async {
    try {
      await _rc.fetchAndActivate();
      _cached = null;
    } catch (_) {}
  }

  void invalidateCache() {
    _cached = null;
    _cachedAt = null;
  }

  // ─── Private ────────────────────────────────────────────────────────

  /// يحوّل كل مفاتيح الـ JSON إلى CompetitionModel —
  /// لا يهمل أي مفتاح جديد
  List<CompetitionModel> _parseAllCompetitions(Map<String, dynamic> data) {
    final result = <CompetitionModel>[];
    for (final entry in data.entries) {
      if (entry.value is Map<String, dynamic>) {
        result.add(
          CompetitionModel.fromJson(
            entry.key,
            entry.value as Map<String, dynamic>,
          ),
        );
      }
    }
    // ترتيب حسب حقل order ثم اسم المفتاح
    result.sort((a, b) => a.order.compareTo(b.order));
    return result;
  }

  List<CompetitionModel> _fallbackCompetitions() {
    return _fallbackData.entries
        .map((e) => CompetitionModel.fromJson(e.key, e.value))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  Map<String, dynamic> _buildDefaultJson() {
    return Map.from(_fallbackData);
  }
}

void unawaited(Future<void> future) {
  future.catchError((_) {});
}
