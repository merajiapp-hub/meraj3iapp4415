import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_settings.dart';

class AppConfigProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  SharedPreferences? _prefs;

  bool _maintenanceMode = false;
  String _maintenanceMessage = 'نعمل الآن على إجراء بعض التحسينات الهامة.\nسيعود التطبيق للعمل بشكل طبيعي قريباً.';
  bool _registrationOpen = true;
  bool _allowGuestView = false;

  Map<String, bool> _featureFlags = {
    'ai_enabled': true,
    'competition_enabled': true,
    'books_upload_enabled': true,
    'quizzes_enabled': true,
    'results_enabled': true,
  };
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

    _maintenanceMode = _prefs!.getBool('maintenance_mode') ?? false;
    _maintenanceMessage = _prefs!.getString('maintenance_message') ?? _maintenanceMessage;
    _registrationOpen = _prefs!.getBool('registration_open') ?? true;
    _allowGuestView = _prefs!.getBool('allow_guest_view') ?? false;

    _featureFlags = {
      'ai_enabled': _prefs!.getBool('ai_enabled') ?? true,
      'competition_enabled': _prefs!.getBool('competition_enabled') ?? true,
      'books_upload_enabled': _prefs!.getBool('books_upload_enabled') ?? true,
      'quizzes_enabled': _prefs!.getBool('quizzes_enabled') ?? true,
      'results_enabled': _prefs!.getBool('results_enabled') ?? true,
    };

    _initialized = true;
    notifyListeners();
  }

  Future<void> _saveFlagsToCache(Map<String, dynamic> data) async {
    if (_prefs == null) return;
    await _prefs!.setBool('ai_enabled', data['ai_enabled'] == true);
    await _prefs!.setBool('competition_enabled', data['competition_enabled'] == true);
    await _prefs!.setBool('books_upload_enabled', data['books_upload_enabled'] == true);
    await _prefs!.setBool('quizzes_enabled', data['quizzes_enabled'] == true);
    await _prefs!.setBool('results_enabled', data['results_enabled'] == true);
  }

  Future<void> _saveAppSettingsToCache(AppSettings settings) async {
    if (_prefs == null) return;
    await _prefs!.setBool('maintenance_mode', settings.maintenanceMode);
    await _prefs!.setString('maintenance_message', settings.maintenanceMessage);
    await _prefs!.setBool('registration_open', settings.registrationOpen);
    await _prefs!.setBool('allow_guest_view', settings.allowGuestView);
  }

  void _listenToFeatureFlags() {
    _firestore
        .collection('admin_settings')
        .doc('feature_flags')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        _featureFlags = {
          'ai_enabled': data['ai_enabled'] ?? true,
          'competition_enabled': data['competition_enabled'] ?? true,
          'books_upload_enabled': data['books_upload_enabled'] ?? true,
          'quizzes_enabled': data['quizzes_enabled'] ?? true,
          'results_enabled': data['results_enabled'] ?? true,
        };
        _saveFlagsToCache(data);
      }
      _initialized = true;
      notifyListeners();
    }, onError: (error) {
      debugPrint('[AppConfig] Error listening to feature flags: $error');
      _initialized = true;
      notifyListeners();
    });
  }

  void _listenToMaintenanceMode() {
    _firestore
        .collection('app_settings')
        .doc('maintenance')
        .snapshots()
        .listen((snapshot) {
      final settings = AppSettings.fromFirestore(snapshot.data());
      _maintenanceMode = settings.maintenanceMode;
      _maintenanceMessage = settings.maintenanceMessage;
      _saveAppSettingsToCache(settings);
      notifyListeners();
    }, onError: (error) {
      debugPrint('[AppConfig] Error listening to maintenance mode: $error');
      notifyListeners();
    });
  }

  void _listenToAppSettings() {
    _firestore
        .collection('app_config')
        .doc('settings')
        .snapshots()
        .listen((snapshot) {
      final settings = AppSettings.fromFirestore(snapshot.data());
      _registrationOpen = settings.registrationOpen;
      _allowGuestView = settings.allowGuestView;
      _saveAppSettingsToCache(settings);
      notifyListeners();
    }, onError: (error) {
      debugPrint('[AppConfig] Error listening to app settings: $error');
      notifyListeners();
    });
  }

  /// يمكن استدعاء هذه الدالة للتحقق اليدوي (مثلاً عند الضغط على زر إعادة المحاولة)
  Future<void> checkMaintenanceStatus() async {
    try {
      final doc = await _firestore.collection('app_settings').doc('maintenance').get();
      final settings = AppSettings.fromFirestore(doc.data());
      _maintenanceMode = settings.maintenanceMode;
      _maintenanceMessage = settings.maintenanceMessage;
      _saveAppSettingsToCache(settings);
      notifyListeners();
    } catch (e) {
      debugPrint('[AppConfig] Error checking maintenance status: $e');
      notifyListeners();
    }
  }

  Future<void> checkAppSettings() async {
    try {
      final doc = await _firestore.collection('app_config').doc('settings').get();
      final settings = AppSettings.fromFirestore(doc.data());
      _registrationOpen = settings.registrationOpen;
      _allowGuestView = settings.allowGuestView;
      _saveAppSettingsToCache(settings);
      notifyListeners();
    } catch (e) {
      debugPrint('[AppConfig] Error checking app settings: $e');
      notifyListeners();
    }
  }

  Future<void> _saveMaintenanceToCache() async {
    await _prefs?.setBool('maintenance_mode', _maintenanceMode);
    await _prefs?.setString('maintenance_message', _maintenanceMessage);
  }

  bool isFeatureEnabled(String featureKey) {
    return _featureFlags[featureKey] ?? false;
  }
}
