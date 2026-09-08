import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../core/account_status.dart';
import '../services/admin_activity_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final GoogleSignIn _googleSignIn;

  User? _user;
  Map<String, dynamic>? _userData;
  bool _isGuest = false;
  bool _initialized = false;
  bool _isAdmin = false;
  bool _mustChangePassword = false;
  bool _profileReady = false;
  bool _isAccountSuspended = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _accountStatusSubscription;

  AuthProvider() {
    if (!kIsWeb) {
      _googleSignIn = GoogleSignIn();
    }
    // قراءة الحالة المحلية الأولية بشكل متزامن دون انتظار
    _user = _auth.currentUser;
    _isGuest = false; // سيُحدَّث من SharedPreferences لاحقاً

    // الاستماع لتغييرات Auth — بدون عمليات ثقيلة فيه
    _auth.authStateChanges().listen((user) async {
      _user = user;
      if (user != null) {
        _isGuest = false;
        _profileReady = false;
        _isAccountSuspended = false;
        try {
          await ensureUserDocument(user);
          await _checkAdminStatus(user);
          await refreshAccountStatus();
        } catch (e) {
          debugPrint('[Auth] Profile provisioning failed: $e');
        }
      } else {
        _isAdmin = false;
        _mustChangePassword = false;
        _profileReady = false;
        _isAccountSuspended = false;
        _accountStatusSubscription?.cancel();
        _accountStatusSubscription = null;
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

  // ─── التحقق من صلاحية Admin (Firestore + Custom Claims) ──────────────────
  // يتحقق من مجموعة admins في Firestore أولاً (لا تحتاج Cloud Functions)
  // ثم يحاول Custom Claims كاحتياطي (إذا نُشرت Functions لاحقاً)

  Future<void> _checkAdminStatus(User user) async {
    try {
      final email = user.email?.trim().toLowerCase();
      final isKnownAdmin = email == 'mma831770@gmail.com' ||
          email == 'abdellahismd@gmail.com';

      if (isKnownAdmin) {
        _isAdmin = true;
        debugPrint('[Auth] Admin confirmed via Email for ${user.email}');
        return;
      }

      try {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        final data = userDoc.data();
        final role = (data?['role'] ?? data?['userRole'] ?? '').toString().toLowerCase();
        final isAdminFlag = data?['isAdmin'] == true;
        _isAdmin = role == 'admin' || isAdminFlag;
        debugPrint('[Auth] Admin status from Firestore: $_isAdmin for ${user.email}');
      } catch (_) {
        _isAdmin = false;
      }
    } catch (e) {
      debugPrint('[Auth] Error checking admin status: $e');
      _isAdmin = false;
    }
  }

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isGuest => _isGuest;
  bool get initialized => _initialized;
  bool get isAdmin => _isAdmin;
  bool get profileReady => _profileReady;
  bool get mustChangePassword => _mustChangePassword;
  Map<String, dynamic>? get userData => _userData;
  bool get isAccountSuspended => _isAccountSuspended;
  String get suspendedReason => normalizeAccountStatus(_userData).reason;

  // ─── getInitialAuthState مع Timeout آمن ──────────────────────────────────
  // يُستخدم في SplashScreen للانتظار حتى يحسم Firebase حالة المستخدم
  // مع ضمان عدم التعليق أبداً (Timeout = 8 ثوانٍ)
  Future<User?> getInitialAuthState() async {
    try {
      final user = await _auth.authStateChanges().first.timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          debugPrint('[Auth] getInitialAuthState timeout — using currentUser');
          return _auth.currentUser;
        },
      );
      _user = user;
      if (user != null) {
        try {
          await ensureUserDocument(user);
          await refreshAccountStatus();
        } catch (e) {
          debugPrint('[Auth] Initial profile provisioning failed: $e');
          _user = null;
          await _auth.signOut();
        }
      }
      _initialized = true;
      return _user;
    } catch (e) {
      debugPrint('[Auth] getInitialAuthState error: $e');
      _initialized = true;
      return _user;
    }
  }

  Future<bool> refreshAccountStatus() async {
    if (_user == null) {
      _isAccountSuspended = false;
      return false;
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_user!.uid)
          .get()
          .timeout(const Duration(seconds: 10));

      final data = doc.data();
      _userData = data ?? _userData;
      final snapshot = normalizeAccountStatus(data ?? _userData);
      _isAccountSuspended = snapshot.isSuspended;
      _profileReady = true;

      if (snapshot.isSuspended) {
        _accountStatusSubscription?.cancel();
        _accountStatusSubscription = _firestore
            .collection('users')
            .doc(_user!.uid)
            .snapshots()
            .listen((event) {
              final eventData = event.data();
              final eventSnapshot = normalizeAccountStatus(eventData);
              _userData = eventData ?? _userData;
              _isAccountSuspended = eventSnapshot.isSuspended;
              notifyListeners();
            });
      } else {
        _accountStatusSubscription?.cancel();
        _accountStatusSubscription = null;
      }

      notifyListeners();
      return !snapshot.isSuspended;
    } catch (e) {
      debugPrint('[Auth] refreshAccountStatus error: $e');
      _isAccountSuspended = false;
      notifyListeners();
      return false;
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
    SharedPreferences.getInstance()
        .then((prefs) {
          final guest = prefs.getBool('isGuest') ?? false;
          if (_isGuest != guest) {
            _isGuest = guest;
            notifyListeners();
          }
        })
        .catchError((_) {});
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
          if (_userData?['isSuspended'] == true) {
            signOut();
            return;
          }
          _mustChangePassword = _userData?['mustChangePassword'] == true;
          notifyListeners();
        } else {
          signOut();
          return;
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
        final token =
            knownToken ??
            await FirebaseMessaging.instance.getToken().timeout(
              const Duration(seconds: 8),
            );
        await updateFCMToken(token);
      } catch (_) {}
    });
  }

  // ─── تسجيل الدخول بالبريد ────────────────────────────────────────────────
  Future<String?> signIn(String email, String password) async {
    try {
      final cred = await _auth
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 15));

      if (cred.user != null) {
        try {
          await ensureUserDocument(cred.user!, provider: 'email');
          final userDoc = await _firestore.collection('users').doc(cred.user!.uid).get();
          final snapshot = normalizeAccountStatus(userDoc.data());
          _user = cred.user;
          _userData = userDoc.data();
          _isAccountSuspended = snapshot.isSuspended;
          _profileReady = true;

          if (snapshot.isSuspended) {
            _user = cred.user;
            _userData = userDoc.data();
            _isAccountSuspended = true;
            _profileReady = true;
            notifyListeners();
            return 'suspended';
          }
        } on FirebaseException catch (e) {
          await _auth.signOut();
          return 'تعذر تحميل ملف المستخدم: ${e.message ?? e.code}';
        }

        await AdminActivityService.log(
          type: AdminActivityType.userLoggedIn,
          title: 'تسجيل دخول مستخدم',
          description: 'قام المستخدم ${cred.user!.email} بتسجيل الدخول',
          targetUserId: cred.user!.uid,
          metadata: {'email': cred.user!.email, 'provider': 'email'},
        );
      }
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

  // ─── تسجيل حساب جديد — مع إصلاح permission-denied ──────────────────────
  // الترتيب الصحيح: Auth أولاً ← uid متاح ← Firestore تستقبل الكتابة
  // مع retry تلقائي (1 ثانية تأخير لـ token propagation) وrollback عند الفشل
  Future<String?> signUp(
    String name,
    String email,
    String password,
    String phone,
    String gender,
  ) async {
    UserCredential? cred;
    try {
      // الخطوة 1: إنشاء حساب Firebase Auth أولاً (المستخدم الآن لديه uid)
      cred = await _auth
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 15));

      // الخطوة 2: تحديث اسم العرض
      await cred.user?.updateDisplayName(name);

      // الخطوة 3: التحقق من تفرد رقم الهاتف (المستخدم الآن مسجل → uid موجود)
      try {
        final phoneCheck = await _firestore
            .collection('users')
            .where('phone', isEqualTo: phone)
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 10));
        if (phoneCheck.docs.isNotEmpty) {
          // rollback: نحذف حساب Auth لأن الهاتف مكرر
          await cred.user?.delete();
          return 'رقم الهاتف مستخدم في حساب آخر';
        }
      } catch (phoneCheckError) {
        // إذا فشل الـ phone check (مثل مشكلة شبكة)، نكمل ونسمح بالتسجيل
        debugPrint('[SignUp] Phone check warning: $phoneCheckError');
      }

      // الخطوة 4: كتابة مستند Firestore مع retry واحد
      final userData = {
        'name': name,
        'email': email,
        'phone': phone,
        'gender': gender,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActivity': FieldValue.serverTimestamp(),
        'profileImageUrl': null,
        'uid': cred.user!.uid,
        'provider': 'email',
        'role': 'user',
        'isActive': true,
      };

      bool firestoreSuccess = false;
      String? firestoreError;

      // المحاولة الأولى
      try {
        await _firestore
            .collection('users')
            .doc(cred.user!.uid)
            .set(userData)
            .timeout(const Duration(seconds: 10));
        final savedProfile = await _firestore
            .collection('users')
            .doc(cred.user!.uid)
            .get()
            .timeout(const Duration(seconds: 10));
        firestoreSuccess = savedProfile.exists;
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') {
          // انتظر ثانية لـ Auth token يُنشر على Firestore rules
          debugPrint('[SignUp] Token propagation delay — retrying in 1s...');
          await Future.delayed(const Duration(seconds: 1));
          // المحاولة الثانية (Retry)
          try {
            // إعادة تحميل token بعد الانتظار
            await cred.user?.getIdToken(true);
            await _firestore
                .collection('users')
                .doc(cred.user!.uid)
                .set(userData)
                .timeout(const Duration(seconds: 10));
            final savedProfile = await _firestore
                .collection('users')
                .doc(cred.user!.uid)
                .get()
                .timeout(const Duration(seconds: 10));
            firestoreSuccess = savedProfile.exists;
          } catch (retryError) {
            firestoreError = retryError.toString();
          }
        } else {
          firestoreError = e.message;
        }
      } catch (e) {
        firestoreError = e.toString();
      }

      if (!firestoreSuccess) {
        // Rollback: حذف حساب Auth لتجنب حالة غير متسقة
        debugPrint(
          '[SignUp] Firestore failed — rolling back Auth: $firestoreError',
        );
        try {
          await cred.user?.delete();
        } catch (_) {}
        return 'حدث خطأ أثناء حفظ البيانات. أعد المحاولة. ($firestoreError)';
      }

      // الخطوة 5: إشعار الإدارة بتسجيل مستخدم جديد (في الخلفية)
      AdminActivityService.log(
        type: AdminActivityType.userRegistered,
        title: 'تسجيل مستخدم جديد',
        description: 'سجل مستخدم جديد باسم: $name ($email)',
        targetUserId: cred.user!.uid,
        targetUserName: name,
        metadata: {'email': email, 'phone': phone},
      ).catchError((_) {});

      // التسجيل يجهز الحساب فقط؛ تسجيل الدخول يتم من شاشة الدخول التالية.
      await _auth.signOut();
      _user = null;
      _userData = null;
      return null; // نجح التسجيل
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'هذا البريد الإلكتروني مستخدم مسبقاً';
        case 'weak-password':
          return 'كلمة المرور ضعيفة جداً (6 أحرف على الأقل)';
        case 'invalid-email':
          return 'البريد الإلكتروني غير صالح';
        case 'network-request-failed':
          return 'تعذر الاتصال بالإنترنت. تحقق من اتصالك وأعد المحاولة.';
        case 'too-many-requests':
          return 'محاولات كثيرة. انتظر قليلاً وأعد المحاولة.';
        default:
          return 'خطأ في إنشاء الحساب: ${e.message}';
      }
    } catch (e) {
      if (e.toString().contains('timeout') ||
          e.toString().contains('TimeoutException')) {
        return 'انتهت مهلة الاتصال. تحقق من الإنترنت وأعد المحاولة.';
      }
      return 'خطأ غير متوقع: $e';
    }
  }

  Future<void> updateFCMToken(String? token) async {
    if (_user != null && token != null && token.isNotEmpty) {
      try {
        await _firestore
            .collection('users')
            .doc(_user!.uid)
            .set({
              'fcmToken': token,
              'fcmTokens': FieldValue.arrayUnion([token]),
              'lastTokenUpdate': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true))
            .timeout(const Duration(seconds: 8));
      } catch (e) {
        debugPrint('[Auth] Error updating FCM token: $e');
      }
    }
  }

  Future<void> setGuestMode(bool value) async {
    _isGuest = value;
    notifyListeners();
    SharedPreferences.getInstance()
        .then((prefs) {
          prefs.setBool('isGuest', value);
        })
        .catchError((_) {});
  }

  Future<void> signOut() async {
    final currentUser = _user;
    try {
      await _auth.signOut().timeout(const Duration(seconds: 10));
    } catch (_) {}

    if (currentUser != null) {
      AdminActivityService.log(
        type: AdminActivityType.userLoggedOut,
        title: 'تسجيل خروج مستخدم',
        description: 'قام المستخدم ${currentUser.email} بتسجيل الخروج',
        targetUserId: currentUser.uid,
        metadata: {'email': currentUser.email},
      ).catchError((_) {});
    }

    _isGuest = false;
    _userData = null;
    _isAdmin = false;
    _mustChangePassword = false;
    _isAccountSuspended = false;
    _accountStatusSubscription?.cancel();
    _accountStatusSubscription = null;
    notifyListeners();

    // تسجيل الخروج ينهي الجلسة فقط؛ لا نحذف بيانات المستخدم المحلية أو السحابية.
    SharedPreferences.getInstance()
        .then((prefs) {
          prefs.remove('isGuest');
        })
        .catchError((_) {});
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
      late final UserCredential userCredential;
      if (kIsWeb) {
        userCredential = await _auth
            .signInWithPopup(GoogleAuthProvider())
            .timeout(const Duration(seconds: 45));
      } else {
        final googleUser = await _googleSignIn.signIn().timeout(
          const Duration(seconds: 30),
        );
        if (googleUser == null) return 'تم إلغاء تسجيل الدخول بـ Google';

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await _auth
            .signInWithCredential(credential)
            .timeout(const Duration(seconds: 15));
      }
      final user = userCredential.user;
      if (user == null) return 'فشل تسجيل الدخول بـ Google';

      // لا نعلن نجاح تسجيل Google قبل إنشاء profile والتأكد من وجوده.
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final isNewProfile = !doc.exists;
      final savedProfile = await ensureUserDocument(user);
      final snapshot = normalizeAccountStatus(savedProfile.data());
      _user = user;
      _userData = savedProfile.data();
      _isAccountSuspended = snapshot.isSuspended;
      _profileReady = true;
      if (snapshot.isSuspended) {
        _isAccountSuspended = true;
        _userData = savedProfile.data();
        _profileReady = true;
        notifyListeners();
        return 'suspended';
      }

      try {
        if (isNewProfile) {
          // تسجيل نشاط مستخدم جديد
          await AdminActivityService.log(
            type: AdminActivityType.userRegistered,
            title: 'تسجيل مستخدم جديد',
            description: 'سجل مستخدم جديد باسم: ${user.displayName} (Google)',
            targetUserId: user.uid,
            targetUserName: user.displayName,
            metadata: {'email': user.email, 'provider': 'google'},
          );
        } else {
          // تسجيل دخول
          await AdminActivityService.log(
            type: AdminActivityType.userLoggedIn,
            title: 'تسجيل دخول مستخدم',
            description: 'قام المستخدم ${user.email} بتسجيل الدخول (Google)',
            targetUserId: user.uid,
            metadata: {'email': user.email, 'provider': 'google'},
          );
        }
      } catch (e) {
        debugPrint('[Google] Activity logging warning: $e');
      }

      _user = user;
      _userData = savedProfile.data();
      _profileReady = true;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('[Google] Authentication failed: ${e.code} ${e.message}');
      return _googleAuthErrorMessage(e);
    } on FirebaseException catch (e) {
      debugPrint('[Google] Firestore stage failed: ${e.code} ${e.message}');
      await _auth.signOut();
      return _googleErrorMessage(e);
    } catch (e) {
      await _auth.signOut();
      if (e.toString().contains('timeout')) {
        return 'انتهت مهلة الاتصال. أعد المحاولة.';
      }
      return 'خطأ في تسجيل الدخول بـ Google: $e';
    }
  }

  /// Ensures users/{uid} exists without overwriting profile fields edited in-app.
  Future<DocumentSnapshot<Map<String, dynamic>>> ensureUserDocument(
    User user, {
    String provider = 'google',
  }) async {
    if (user.uid.isEmpty) {
      throw FirebaseException(plugin: 'firebase_auth', code: 'missing-uid');
    }

    final ref = _firestore.collection('users').doc(user.uid);
    final current = await ref.get().timeout(const Duration(seconds: 10));
    final data = current.data();
    final update = <String, dynamic>{
      'uid': user.uid,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
      'lastActivity': FieldValue.serverTimestamp(),
    };

    if (!current.exists) {
      update.addAll({
        'fullName': user.displayName ?? (provider == 'google' ? 'مستخدم Google' : 'مستخدم جديد'),
        'name': user.displayName ?? (provider == 'google' ? 'مستخدم Google' : 'مستخدم جديد'),
        'email': user.email ?? '',
        'photoUrl': user.photoURL ?? '',
        'profileImageUrl': user.photoURL,
        'phone': '',
        'educationLevel': '',
        'gender': 'غير محدد',
        'authProvider': provider,
        'provider': provider,
        'role': 'user',
        'isActive': true,
        'accountStatus': 'active',
        'isSuspended': false,
        'suspensionReason': '',
        'suspensionStartAt': null,
        'suspensionEndAt': null,
        'suspendedAt': null,
        'suspendedBy': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else if (data != null) {
      if (!data.containsKey('fullName') && !data.containsKey('name')) {
        update['fullName'] = user.displayName ?? (provider == 'google' ? 'مستخدم Google' : 'مستخدم جديد');
      }
      if (!data.containsKey('authProvider') && !data.containsKey('provider')) {
        update['authProvider'] = provider;
        update['provider'] = provider;
      }      if (!data.containsKey('accountStatus')) {
        update['accountStatus'] = 'active';
      }
      if (!data.containsKey('isSuspended')) {
        update['isSuspended'] = false;
      }
      if (!data.containsKey('suspensionReason')) {
        update['suspensionReason'] = '';
      }
      if (!data.containsKey('suspensionStartAt')) {
        update['suspensionStartAt'] = null;
      }
      if (!data.containsKey('suspensionEndAt')) {
        update['suspensionEndAt'] = null;
      }
      if (!data.containsKey('suspendedAt')) {
        update['suspendedAt'] = null;
      }
      if (!data.containsKey('suspendedBy')) {
        update['suspendedBy'] = null;
      }    }

    await ref.set(update, SetOptions(merge: true)).timeout(const Duration(seconds: 10));
    final saved = await ref.get().timeout(const Duration(seconds: 10));
    if (!saved.exists || saved.data() == null) {
      throw FirebaseException(plugin: 'cloud_firestore', code: 'profile-not-created');
    }
    _userData = saved.data();
    _mustChangePassword = _userData?['mustChangePassword'] == true;
    _profileReady = true;
    return saved;
  }

  String _googleErrorMessage(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'تم تسجيل Google، لكن لا يمكن حفظ ملفك. تحقق من اتصالك ثم أعد المحاولة.';
      case 'unavailable':
      case 'network-request-failed':
        return 'تعذر الاتصال بقاعدة البيانات. أعد المحاولة عند توفر الإنترنت.';
      case 'profile-not-created':
        return 'تعذر تجهيز ملف المستخدم. أعد المحاولة.';
      default:
        return 'تعذر إكمال تسجيل الدخول بـ Google. أعد المحاولة.';
    }
  }

  String _googleAuthErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
        return 'تم إلغاء تسجيل الدخول بـ Google.';
      case 'popup-blocked':
        return 'تم حظر نافذة Google. اسمح بالنوافذ المنبثقة ثم أعد المحاولة.';
      case 'unauthorized-domain':
        return 'النطاق الحالي غير مضاف إلى Authorized domains في Firebase Authentication.';
      case 'account-exists-with-different-credential':
        return 'هذا البريد مرتبط بطريقة دخول أخرى. استخدم البريد وكلمة المرور.';
      case 'network-request-failed':
        return 'تعذر الاتصال بخدمة Google. تحقق من الإنترنت وأعد المحاولة.';
      default:
        return 'تعذر تسجيل الدخول بـ Google (${error.code}). أعد المحاولة.';
    }
  }

  Future<String?> deleteAccount() async {
    try {
      if (_user != null) {
        // Soft delete logic for 30-day disable
        await _firestore
            .collection('users')
            .doc(_user!.uid)
            .update({
              'disabled': true,
              'deletedAt': FieldValue.serverTimestamp(),
            })
            .timeout(const Duration(seconds: 10));

        await signOut();
        return null;
      }
      return 'المستخدم غير مسجل الدخول';
    } catch (e) {
      return 'حدث خطأ أثناء تعطيل الحساب: $e';
    }
  }

  Future<void> signOutGoogle() async {
    if (kIsWeb) return;
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}
