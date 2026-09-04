import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfigProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  SharedPreferences? _prefs;

  bool _maintenanceMode = false;
  String _maintenanceMessage = 'نعمل الآن على إجراء بعض التحسينات الهامة.\nسيعود التطبيق للعمل بشكل طبيعي قريباً.';
  
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
  }

  void _loadFromCache() {
    if (_prefs == null) return;
    
    // We intentionally DO NOT cache maintenanceMode as true. 
    // If the user starts offline, we assume maintenance is OFF to avoid locking them out.
    // Maintenance mode requires an active connection to be verified as ON.
    _maintenanceMode = false; 
    
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
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        _maintenanceMode = data['isMaintenance'] == true;
        _maintenanceMessage = data['message'] ?? 'نعمل الآن على إجراء بعض التحسينات الهامة.\nسيعود التطبيق للعمل بشكل طبيعي قريباً.';
      } else {
        // If document doesn't exist, default to false
        _maintenanceMode = false;
      }
      notifyListeners();
    }, onError: (error) {
      debugPrint('[AppConfig] Error listening to maintenance mode: $error');
      // On connection error, default to false to protect against lockouts
      _maintenanceMode = false;
      notifyListeners();
    });
  }

  /// يمكن استدعاء هذه الدالة للتحقق اليدوي (مثلاً عند الضغط على زر إعادة المحاولة)
  Future<void> checkMaintenanceStatus() async {
    try {
      final doc = await _firestore.collection('app_settings').doc('maintenance').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _maintenanceMode = data['isMaintenance'] == true;
        _maintenanceMessage = data['message'] ?? _maintenanceMessage;
      } else {
        _maintenanceMode = false;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[AppConfig] Error checking maintenance status: $e');
      _maintenanceMode = false;
      notifyListeners();
    }
  }

  bool isFeatureEnabled(String featureKey) {
    return _featureFlags[featureKey] ?? false;
  }
}
