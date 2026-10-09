import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_settings.dart';

class AppConfigProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  SharedPreferences? _prefs;

  bool _maintenanceMode = false;
  String _maintenanceMessage =
      'نعمل الآن على إجراء بعض التحسينات الهامة.\nسيعود التطبيق للعمل بشكل طبيعي قريباً.';
  bool _registrationOpen = true;
  bool _allowGuestView = false;

  static const Map<String, bool> _defaultFeatureFlags = {
    'competition_enabled': true,
    'books_upload_enabled': true,
    'quizzes_enabled': true,
    'results_enabled': true,
    'allow_pdf_download': true,
    'enable_chat': true,
    'show_ads': false,
    'force_update': false,
  };

  static const List<String> _featureFlagKeys = [
    'competition_enabled',
    'books_upload_enabled',
    'quizzes_enabled',
    'results_enabled',
    'allow_pdf_download',
    'enable_chat',
    'show_ads',
    'force_update',
  ];

  Map<String, bool> _featureFlags = Map<String, bool>.from(_defaultFeatureFlags);
  bool _initialized = false;

  bool get maintenanceMode => _maintenanceMode;
  String get maintenanceMessage => _maintenanceMessage;
  bool get registrationOpen => _registrationOpen;
  bool get allowGuestView => _allowGuestView;
  Map<String, bool> get featureFlags => _featureFlags;
  bool get initialized => _initialized;

  AppConfigProvider() {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadFromCache();
    _listenToFeatureFlags();
    _listenToMaintenanceMode();
    _listenToAppSettings();
  }

  void _loadFromCache() {
    if (_prefs == null) return;

    // Maintenance is a hard app gate and must follow Firestore only.
    // A stale local cached value must never override the admin-controlled state.
    _maintenanceMode = false;
    _maintenanceMessage =
        _prefs!.getString('maintenance_message') ?? _maintenanceMessage;
    _registrationOpen = _prefs!.getBool('registration_open') ?? true;
    _allowGuestView = _prefs!.getBool('allow_guest_view') ?? false;

    _featureFlags = {
      for (final key in _featureFlagKeys)
        key: _prefs!.getBool(key) ?? _defaultFeatureFlags[key]!,
    };

    _initialized = true;
    notifyListeners();
  }

  Future<void> _saveFlagsToCache(Map<String, dynamic> data) async {
    if (_prefs == null) return;
    for (final key in _featureFlagKeys) {
      final value = data[key] is bool ? data[key] as bool : _defaultFeatureFlags[key]!;
      await _prefs!.setBool(key, value);
    }
  }

  Future<void> _saveAppSettingsToCache() async {
    if (_prefs == null) return;
    await _prefs!.setBool('maintenance_mode', _maintenanceMode);
    await _prefs!.setString('maintenance_message', _maintenanceMessage);
    await _prefs!.setBool('registration_open', _registrationOpen);
    await _prefs!.setBool('allow_guest_view', _allowGuestView);
  }

  Map<String, bool> _normalizeFeatureFlags(Map<String, dynamic>? data) {
    final resolved = <String, bool>{};
    for (final key in _featureFlagKeys) {
      final raw = data?[key];
      resolved[key] = raw is bool ? raw : _defaultFeatureFlags[key]!;
    }
    return resolved;
  }

  void _listenToFeatureFlags() {
    _firestore
        .collection('admin_settings')
        .doc('feature_flags')
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.exists && snapshot.data() != null) {
              final data = snapshot.data()!;
              _featureFlags = _normalizeFeatureFlags(data);
              _saveFlagsToCache(data);
            } else {
              _featureFlags = Map<String, bool>.from(_defaultFeatureFlags);
            }
            _initialized = true;
            notifyListeners();
          },
          onError: (error) {
            debugPrint('[AppConfig] Error listening to feature flags: $error');
            _initialized = true;
            notifyListeners();
          },
        );
  }

  void _listenToMaintenanceMode() {
    _firestore
        .collection('app_settings')
        .doc('maintenance')
        .snapshots()
        .listen(
          (snapshot) {
            final settings = AppSettings.fromFirestore(snapshot.data());
            _maintenanceMode = settings.maintenanceMode;
            _maintenanceMessage = settings.maintenanceMessage;
            _saveAppSettingsToCache();
            notifyListeners();
          },
          onError: (error) {
            debugPrint(
              '[AppConfig] Error listening to maintenance mode: $error',
            );
            notifyListeners();
          },
        );
  }

  void _listenToAppSettings() {
    _firestore
        .collection('app_config')
        .doc('settings')
        .snapshots()
        .listen(
          (snapshot) {
            final settings = AppSettings.fromFirestore(snapshot.data());
            _registrationOpen = settings.registrationOpen;
            _allowGuestView = settings.allowGuestView;
            _saveAppSettingsToCache();
            notifyListeners();
          },
          onError: (error) {
            debugPrint('[AppConfig] Error listening to app settings: $error');
            notifyListeners();
          },
        );
  }

  /// يمكن استدعاء هذه الدالة للتحقق اليدوي (مثلاً عند الضغط على زر إعادة المحاولة)
  Future<void> checkMaintenanceStatus() async {
    try {
      final doc = await _firestore
          .collection('app_settings')
          .doc('maintenance')
          .get();
      final settings = AppSettings.fromFirestore(doc.data());
      _maintenanceMode = settings.maintenanceMode;
      _maintenanceMessage = settings.maintenanceMessage;
      _saveAppSettingsToCache();
      notifyListeners();
    } catch (e) {
      debugPrint('[AppConfig] Error checking maintenance status: $e');
      notifyListeners();
    }
  }

  Future<void> checkAppSettings() async {
    try {
      final doc = await _firestore
          .collection('app_config')
          .doc('settings')
          .get();
      final settings = AppSettings.fromFirestore(doc.data());
      _registrationOpen = settings.registrationOpen;
      _allowGuestView = settings.allowGuestView;
      _saveAppSettingsToCache();
      notifyListeners();
    } catch (e) {
      debugPrint('[AppConfig] Error checking app settings: $e');
      notifyListeners();
    }
  }

  bool isFeatureEnabled(String featureKey) {
    return _featureFlags[featureKey] ?? false;
  }
}
