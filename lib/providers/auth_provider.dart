import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? _user;
  Map<String, dynamic>? _userData;
  bool _isGuest = false;
  bool _initialized = false;

  AuthProvider() {
    // قراءة الحالة المحلية الأولية بشكل متزامن دون انتظار
    _user = _auth.currentUser;
    _isGuest = false; // سيُحدَّث من SharedPreferences لاحقاً

    // الاستماع لتغييرات Auth — بدون عمليات ثقيلة فيه
    _auth.authStateChanges().listen((user) {
      _user = user;
      if (user != null) {
        _isGuest = false;
        // تحميل بيانات المستخدم في الخلفية بدون تعليق الـ listener
        _loadUserDataBackground();
      }
      _initialized = true;
      notifyListeners();
    });

    // تحديث FCM Token عند التجديد — في الخلفية تماماً
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      _updateFCMTokenBackground(token);
    });

    // قراءة حالة الـ Guest من SharedPreferences في الخلفية
    _loadGuestStateBackground();
  }

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isGuest => _isGuest;
  bool get initialized => _initialized;
  Map<String, dynamic>? get userData => _userData;

  // ─── getInitialAuthState مع Timeout آمن ──────────────────────────────────
  // يُستخدم في SplashScreen للانتظار حتى يحسم Firebase حالة المستخدم
  // مع ضمان عدم التعليق أبداً (Timeout = 8 ثوانٍ)
  Future<User?> getInitialAuthState() async {
    try {
      final user = await _auth.authStateChanges().first
          .timeout(const Duration(seconds: 8), onTimeout: () {
        debugPrint('[Auth] getInitialAuthState timeout — using currentUser');
        return _auth.currentUser;
      });
      _user = user;
      _initialized = true;
      return user;
    } catch (e) {
      debugPrint('[Auth] getInitialAuthState error: $e');
      _initialized = true;
      return _auth.currentUser;
    }
  }

  ImageProvider? get profileImageProvider {
    final base64Str = _userData?['profileImageBase64'];
    if (base64Str != null && base64Str.isNotEmpty) {
      try {
        return MemoryImage(base64Decode(base64Str));
      } catch (_) {}
    }
    if (_user?.photoURL != null && _user!.photoURL!.isNotEmpty) {
      return NetworkImage(_user!.photoURL!);
    }
    return null;
  }

  // ─── تحميل حالة الـ Guest في الخلفية — لا تعليق ──────────────────────────
  void _loadGuestStateBackground() {
    SharedPreferences.getInstance().then((prefs) {
      final guest = prefs.getBool('isGuest') ?? false;
      if (_isGuest != guest) {
        _isGuest = guest;
        notifyListeners();
      }
    }).catchError((_) {});
  }

  // ─── تحميل بيانات المستخدم في الخلفية — لا تعليق ─────────────────────────
  void _loadUserDataBackground() {
    if (_user == null) return;
    Future.microtask(() async {
      try {
        final doc = await _firestore
            .collection('users')
            .doc(_user!.uid)
            .get()
            .timeout(const Duration(seconds: 10));
        if (doc.exists && doc.data() != null) {
          _userData = doc.data();
          notifyListeners();
        }
      } catch (e) {
        debugPrint('[Auth] _loadUserDataBackground error: $e');
      }
      // تحديث Token في الخلفية بعد تحميل البيانات
      _updateFCMTokenBackground(null);
    });
  }

  // ─── تحديث FCM Token في الخلفية — لا تعليق أبداً ────────────────────────
  void _updateFCMTokenBackground(String? knownToken) {
    Future.microtask(() async {
      if (_user == null) return;
      try {
        final token = knownToken ??
            await FirebaseMessaging.instance
                .getToken()
                .timeout(const Duration(seconds: 8));
        await updateFCMToken(token);
      } catch (_) {}
    });
  }

  // ─── تسجيل الدخول بالبريد ────────────────────────────────────────────────
  Future<String?> signIn(String email, String password) async {
    try {
      await _auth
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 15));
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'لا يوجد حساب بهذا البريد الإلكتروني';
        case 'wrong-password':
          return 'كلمة المرور غير صحيحة';
        case 'invalid-email':
          return 'البريد الإلكتروني غير صالح';
        case 'user-disabled':
          return 'هذا الحساب معطّل';
        case 'invalid-credential':
          return 'بيانات الدخول غير صحيحة';
        case 'network-request-failed':
          return 'تعذر الاتصال بالإنترنت. تحقق من اتصالك وأعد المحاولة.';
        case 'too-many-requests':
          return 'محاولات كثيرة. انتظر قليلاً وأعد المحاولة.';
        default:
          return 'خطأ في تسجيل الدخول: ${e.message}';
      }
    } catch (e) {
      if (e.toString().contains('timeout') ||
          e.toString().contains('TimeoutException')) {
        return 'انتهت مهلة الاتصال. تحقق من الإنترنت وأعد المحاولة.';
      }
      return 'خطأ غير متوقع: $e';
    }
  }

  Future<String?> signInWithPhone(String phone, String password) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10));

      if (userDoc.docs.isEmpty) {
        return 'لا يوجد حساب مرتبط بهذا الرقم';
      }

      final email = userDoc.docs.first.data()['email'] as String;
      return await signIn(email, password);
    } on FirebaseAuthException catch (e) {
      return 'خطأ: ${e.message}';
    } catch (e) {
      if (e.toString().contains('timeout')) {
        return 'انتهت مهلة الاتصال. أعد المحاولة.';
      }
      return 'خطأ في تسجيل الدخول بالهاتف: $e';
    }
  }

  Future<String?> signUp(
    String name,
    String email,
    String password,
    String phone,
    String gender,
  ) async {
    try {
      final phoneCheck = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10));
      if (phoneCheck.docs.isNotEmpty) {
        return 'رقم الهاتف مستخدم في حساب آخر';
      }

      final cred = await _auth
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 15));
      await cred.user?.updateDisplayName(name);

      await _firestore.collection('users').doc(cred.user!.uid).set({
        'name': name,
        'email': email,
        'phone': phone,
        'gender': gender,
        'createdAt': FieldValue.serverTimestamp(),
        'profileImageUrl': null,
        'uid': cred.user!.uid,
      }).timeout(const Duration(seconds: 10));
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'هذا البريد الإلكتروني مستخدم مسبقاً';
        case 'weak-password':
          return 'كلمة المرور ضعيفة جداً (6 أحرف على الأقل)';
        case 'invalid-email':
          return 'البريد الإلكتروني غير صالح';
        case 'network-request-failed':
          return 'تعذر الاتصال بالإنترنت.';
        default:
          return 'خطأ في إنشاء الحساب: ${e.message}';
      }
    } catch (e) {
      return 'خطأ غير متوقع: $e';
    }
  }

  Future<void> updateFCMToken(String? token) async {
    if (_user != null && token != null && token.isNotEmpty) {
      try {
        await _firestore.collection('users').doc(_user!.uid).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }).timeout(const Duration(seconds: 8));
      } catch (e) {
        debugPrint('[Auth] Error updating FCM token: $e');
      }
    }
  }

  Future<void> setGuestMode(bool value) async {
    _isGuest = value;
    notifyListeners();
    // حفظ في الخلفية
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('isGuest', value);
    }).catchError((_) {});
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut().timeout(const Duration(seconds: 10));
    } catch (_) {}
    _isGuest = false;
    _userData = null;
    notifyListeners();

    // تنظيف في الخلفية
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('isGuest');
      final keys = prefs.getKeys().toList();
      for (final key in keys) {
        if (key.startsWith('favorite_') ||
            key.startsWith('downloads_') ||
            key.startsWith('reading_') ||
            key.startsWith('study_tasks')) {
          prefs.remove(key);
        }
      }
    }).catchError((_) {});
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _auth
          .sendPasswordResetEmail(email: email)
          .timeout(const Duration(seconds: 10));
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'خطأ: $e';
    }
  }

  Future<String?> updateProfile(
    String name,
    String? imageUrl, {
    String? base64Image,
  }) async {
    try {
      if (_user != null) {
        await _user!
            .updateDisplayName(name)
            .timeout(const Duration(seconds: 10));
        if (imageUrl != null) {
          await _user!
              .updatePhotoURL(imageUrl)
              .timeout(const Duration(seconds: 10));
        }

        final updateData = <String, dynamic>{'name': name};
        if (imageUrl != null) updateData['profileImageUrl'] = imageUrl;
        if (base64Image != null) updateData['profileImageBase64'] = base64Image;

        await _firestore
            .collection('users')
            .doc(_user!.uid)
            .update(updateData)
            .timeout(const Duration(seconds: 10));

        _loadUserDataBackground();
        notifyListeners();
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ─── تسجيل الدخول بـ Google ─────────────────────────────────────────────
  Future<String?> signInWithGoogle() async {
    try {
      final googleUser =
          await _googleSignIn.signIn().timeout(const Duration(seconds: 30));
      if (googleUser == null) return 'تم إلغاء تسجيل الدخول بـ Google';

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth
          .signInWithCredential(credential)
          .timeout(const Duration(seconds: 15));
      final user = userCredential.user;
      if (user == null) return 'فشل تسجيل الدخول بـ Google';

      // حفظ بيانات المستخدم في Firestore في الخلفية
      Future.microtask(() async {
        try {
          final doc = await _firestore.collection('users').doc(user.uid).get();
          if (!doc.exists) {
            await _firestore.collection('users').doc(user.uid).set({
              'name': user.displayName ?? '',
              'email': user.email ?? '',
              'phone': '',
              'gender': 'غير محدد',
              'createdAt': FieldValue.serverTimestamp(),
              'profileImageUrl': user.photoURL,
              'uid': user.uid,
              'provider': 'google',
            });
          }
        } catch (_) {}
      });

      _loadUserDataBackground();
      notifyListeners();
      return null;
    } catch (e) {
      if (e.toString().contains('timeout')) {
        return 'انتهت مهلة الاتصال. أعد المحاولة.';
      }
      return 'خطأ في تسجيل الدخول بـ Google: $e';
    }
  }

  Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}
