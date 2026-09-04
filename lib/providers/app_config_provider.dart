import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfigProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  SharedPreferences? _prefs;

  bool _maintenanceMode = false;
  Map<String, bool> _featureFlags = {
    'ai_enabled': true,
    'competition_enabled': true,
    'books_upload_enabled': true,
    'quizzes_enabled': true,
    'results_enabled': true,
  };
  bool _initialized = false;

  bool get maintenanceMode => _maintenanceMode;
  Map<String, bool> get featureFlags => _featureFlags;
  bool get initialized => _initialized;

  AppConfigProvider() {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadFromCache();
    _listenToConfig();
  }

  void _loadFromCache() {
    if (_prefs == null) return;
    _maintenanceMode = _prefs!.getBool('maintenance_mode') ?? false;
    
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

  Future<void> _saveToCache(Map<String, dynamic> data) async {
    if (_prefs == null) return;
    await _prefs!.setBool('maintenance_mode', data['maintenance_mode'] == true);
    await _prefs!.setBool('ai_enabled', data['ai_enabled'] == true);
    await _prefs!.setBool('competition_enabled', data['competition_enabled'] == true);
    await _prefs!.setBool('books_upload_enabled', data['books_upload_enabled'] == true);
    await _prefs!.setBool('quizzes_enabled', data['quizzes_enabled'] == true);
    await _prefs!.setBool('results_enabled', data['results_enabled'] == true);
  }

  void _listenToConfig() {
    _firestore
        .collection('admin_settings')
        .doc('feature_flags')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        _maintenanceMode = data['maintenance_mode'] == true;
        
        _featureFlags = {
          'ai_enabled': data['ai_enabled'] == true,
          'competition_enabled': data['competition_enabled'] == true,
          'books_upload_enabled': data['books_upload_enabled'] == true,
          'quizzes_enabled': data['quizzes_enabled'] == true,
          'results_enabled': data['results_enabled'] == true,
        };
        
        _saveToCache(data);
      }
      _initialized = true;
      notifyListeners();
    }, onError: (error) {
      debugPrint('[AppConfig] Error listening to config: $error');
      // On error, we rely on cached values loaded earlier
      _initialized = true;
      notifyListeners();
    });
  }

  bool isFeatureEnabled(String featureKey) {
    return _featureFlags[featureKey] ?? false;
  }
}
