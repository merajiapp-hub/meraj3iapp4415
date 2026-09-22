import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../core/account_status.dart';
import '../services/admin_activity_service.dart';
import '../services/login_activity_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  Map<String, dynamic>? _userData;
  bool _isGuest = false;
  bool _initialized = false;
  bool _isAdmin = false;
  bool _mustChangePassword = false;
  bool _profileReady = false;
  bool _isAccountSuspended = false;
  bool _isRegistering = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _accountStatusSubscription;

  static const String _defaultPhoneCountryCode = '222';

  static String normalizePhoneValue(String value) {
    var digits = value.trim().replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.isEmpty) return '';

    if (digits.startsWith('00')) {
      digits = digits.substring(2);
    }
    if (digits.startsWith('+')) {
      digits = digits.substring(1);
    }

    digits = digits.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';

    if (digits.startsWith('0') && digits.length > 1) {
      digits = digits.substring(1);
    }

    if (!digits.startsWith(_defaultPhoneCountryCode)) {
      digits = _defaultPhoneCountryCode + digits;
    }

    return '+$digits';
  }

  static String canonicalRegistrationEmail(String? email, String phone) {
    final cleanEmail = (email ?? '').trim().toLowerCase();
    if (cleanEmail.isNotEmpty) return cleanEmail;
    final digits = normalizePhoneValue(phone).substring(1);
    return 'phone.$digits@auth.meraj3i.invalid';
  }

  String normalizePhone(String value) =>
      AuthProvider.normalizePhoneValue(value);

  String _phoneAuthEmail(String phone) =>
      AuthProvider.canonicalRegistrationEmail(null, phone);

  String _providerForUser(User user) {
    if (user.email?.endsWith('@auth.meraj3i.invalid') == true) {
      return 'phone';
    }
    return 'email';
  }

  String? resolvePhoneValue(Map<String, dynamic>? data) {
    if (data == null) return null;
    for (final key in const [
      'phone',
      'phoneNumber',
      'mobile',
      'telephone',
      'phoneNormalized',
    ]) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  Future<void> _linkPhoneCredential(
    User user,
    String phone,
    String password,
  ) async {
    final email = _phoneAuthEmail(phone);
    if (user.providerData.any((info) => info.email == email)) return;
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await user.linkWithCredential(credential);
  }

  static String safeFallbackDisplayName({
    String? fullName,
    String? email,
    String? provider,
  }) {
    final candidate = (fullName ?? '').trim();
    if (candidate.isNotEmpty) return candidate;

    final emailCandidate = (email ?? '').trim();
    if (emailCandidate.isNotEmpty && emailCandidate.contains('@')) {
      final local = emailCandidate.split('@').first.trim();
      if (local.isNotEmpty) return local;
    }

    return provider == 'google' ? 'مستخدم Google' : 'مستخدم';
  }

  Map<String, dynamic> buildUserProfileData({
    required String uid,
    required String name,
    required String email,
    required String phone,
    required String gender,
    required String provider,
    String? profileImageUrl,
  }) {
    final normalizedPhone = normalizePhone(phone);
    final safeEmail = email.trim();
    final safeName = name.trim().isNotEmpty
        ? name.trim()
        : safeFallbackDisplayName(email: safeEmail, provider: provider);
    final profile = <String, dynamic>{
      'uid': uid,
      'name': safeName,
      'fullName': safeName,
      'email': safeEmail.toLowerCase(),
      'phone': normalizedPhone,
      'phoneNumber': normalizedPhone,
      'phoneNormalized': normalizedPhone,
      'gender': gender.trim().isNotEmpty ? gender : 'غير محدد',
      'provider': provider,
      'authProvider': provider,
      'role': 'user',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastActivity': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    };

    if (profileImageUrl != null && profileImageUrl.trim().isNotEmpty) {
      profile['profileImageUrl'] = profileImageUrl;
      profile['photoUrl'] = profileImageUrl;
    }

    return profile;
  }

  AuthProvider() {
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
        if (!_isRegistering) {
          try {
            await ensureUserDocument(user, provider: _providerForUser(user));
            await _checkAdminStatus(user);
            await refreshAccountStatus();
          } catch (e) {
            debugPrint('[Auth] Profile provisioning failed: $e');
          }
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
      final isKnownAdmin =
          email == 'mma831770@gmail.com' || email == 'abdellahismd@gmail.com';

      if (isKnownAdmin) {
        _isAdmin = true;
        debugPrint('[Auth] Admin confirmed via Email for ${user.email}');
        return;
      }

      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        final data = userDoc.data();
        final role = (data?['role'] ?? data?['userRole'] ?? '')
            .toString()
            .toLowerCase();
        final isAdminFlag = data?['isAdmin'] == true;
        _isAdmin = role == 'admin' || isAdminFlag;
        debugPrint(
          '[Auth] Admin status from Firestore: $_isAdmin for ${user.email}',
        );
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
          await ensureUserDocument(user, provider: _providerForUser(user));
          await refreshAccountStatus();
        } catch (e) {
          debugPrint('[Auth] Initial profile provisioning failed: $e');
          debugPrint(
            '[Auth] Profile is not ready yet; preserving Firebase session.',
          );
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
          final userDoc = await _firestore
              .collection('users')
              .doc(cred.user!.uid)
              .get();
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
            LoginActivityService.record(
              result: 'account_suspended',
              method: 'email',
              identifier: email,
            );
            return 'suspended';
          }
        } on FirebaseException catch (e) {
          if (e.code == 'permission-denied') {
            debugPrint(
              '[Auth] Permission denied while loading user doc for ${cred.user!.uid}.',
            );
            _user = cred.user;
            return 'تم تسجيل الدخول، لكن تعذر تحميل ملف المستخدم. أعد المحاولة.';
          }
          _user = cred.user;
          return 'تعذر تحميل ملف المستخدم: ${e.message ?? e.code}';
        }

        await AdminActivityService.log(
          type: AdminActivityType.userLoggedIn,
          title: 'تسجيل دخول مستخدم',
          description: 'قام المستخدم ${cred.user!.email} بتسجيل الدخول',
          targetUserId: cred.user!.uid,
          metadata: {'email': cred.user!.email, 'provider': 'email'},
        );
        LoginActivityService.record(
          result: 'success',
          method: 'email',
          identifier: email,
        );
      }
      return null;
    } on FirebaseAuthException catch (e) {
      final result = switch (e.code) {
        'user-not-found' => 'account_not_found',
        'wrong-password' => 'invalid_password',
        'invalid-credential' => 'invalid_credential',
        'invalid-email' => 'invalid_identifier',
        'user-disabled' => 'account_disabled',
        'too-many-requests' => 'repeated_failure',
        'network-request-failed' => 'network_error',
        _ => 'auth_error',
      };
      LoginActivityService.record(
        result: result,
        method: 'email',
        authCode: e.code,
        identifier: email,
      );
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
        LoginActivityService.record(
          result: 'network_error',
          method: 'email',
          authCode: 'timeout',
          identifier: email,
        );
        return 'انتهت مهلة الاتصال. تحقق من الإنترنت وأعد المحاولة.';
      }
      LoginActivityService.record(
        result: 'system_error',
        method: 'email',
        authCode: 'unexpected',
        identifier: email,
      );
      return 'خطأ غير متوقع: $e';
    }
  }

  Future<String?> signInWithPhone(String phone, String password) async {
    final normalizedPhone = normalizePhone(phone);
    try {
      final credential = await _auth
          .signInWithEmailAndPassword(
            email: _phoneAuthEmail(normalizedPhone),
            password: password,
          )
          .timeout(const Duration(seconds: 15));
      final user = credential.user;
      if (user == null) return 'تعذر تحميل الحساب. أعد المحاولة.';
      await ensureUserDocument(user, provider: 'phone');
      final snapshot = normalizeAccountStatus(_userData);
      _user = user;
      _isAccountSuspended = snapshot.isSuspended;
      _profileReady = true;
      notifyListeners();
      LoginActivityService.record(
        result: snapshot.isSuspended ? 'account_suspended' : 'success',
        method: 'phone',
        identifier: normalizedPhone,
      );
      return snapshot.isSuspended ? 'suspended' : null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        // الحسابات القديمة استخدمت البريد الحقيقي كهوية Auth. رقّعها عند أول دخول.
        try {
          final userDoc = await _firestore
              .collection('users')
              .where('phoneNormalized', isEqualTo: normalizedPhone)
              .limit(1)
              .get()
              .timeout(const Duration(seconds: 10));
          final legacyDocs = userDoc.docs.isNotEmpty
              ? userDoc.docs
              : (await _firestore
                        .collection('users')
                        .where('phone', isEqualTo: normalizedPhone)
                        .limit(1)
                        .get()
                        .timeout(const Duration(seconds: 10)))
                    .docs;
          final legacyDoc = legacyDocs.isEmpty ? null : legacyDocs.first;
          if (legacyDoc == null) {
            LoginActivityService.record(
              result: 'account_not_found',
              method: 'phone',
              authCode: e.code,
              identifier: normalizedPhone,
            );
            return 'لا يوجد حساب مرتبط بهذا الرقم';
          }
          final data = legacyDoc.data();
          final email = (data['email'] as String?)?.trim();
          if (email == null || email.isEmpty) {
            LoginActivityService.record(
              result: 'account_not_found',
              method: 'phone',
              authCode: e.code,
              identifier: normalizedPhone,
            );
            return 'لا يوجد حساب مرتبط بهذا الرقم';
          }
          final legacy = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          final user = legacy.user;
          if (user == null) return 'تعذر تحميل الحساب. أعد المحاولة.';
          await _linkPhoneCredential(user, normalizedPhone, password);
          await ensureUserDocument(user, provider: 'phone');
          final snapshot = normalizeAccountStatus(_userData);
          _user = user;
          _isAccountSuspended = snapshot.isSuspended;
          _profileReady = true;
          notifyListeners();
          LoginActivityService.record(
            result: snapshot.isSuspended ? 'account_suspended' : 'success',
            method: 'phone',
            identifier: normalizedPhone,
          );
          return snapshot.isSuspended ? 'suspended' : null;
        } on FirebaseAuthException catch (legacyError) {
          LoginActivityService.record(
            result: _loginActivityResult(legacyError.code, phoneLogin: true),
            method: 'phone',
            authCode: legacyError.code,
            identifier: normalizedPhone,
          );
          return _authErrorMessage(legacyError, phoneLogin: true);
        }
      }
      LoginActivityService.record(
        result: _loginActivityResult(e.code, phoneLogin: true),
        method: 'phone',
        authCode: e.code,
        identifier: normalizedPhone,
      );
      return _authErrorMessage(e, phoneLogin: true);
    } catch (e) {
      if (e.toString().contains('timeout')) {
        LoginActivityService.record(
          result: 'network_error',
          method: 'phone',
          authCode: 'timeout',
          identifier: normalizedPhone,
        );
        return 'انتهت مهلة الاتصال. أعد المحاولة.';
      }
      LoginActivityService.record(
        result: 'system_error',
        method: 'phone',
        authCode: 'unexpected',
        identifier: normalizedPhone,
      );
      return 'تعذر تسجيل الدخول بهذا الرقم. أعد المحاولة.';
    }
  }

  String _loginActivityResult(String code, {bool phoneLogin = false}) {
    switch (code) {
      case 'user-not-found':
        return 'account_not_found';
      case 'wrong-password':
        return 'invalid_password';
      case 'invalid-credential':
        return phoneLogin ? 'account_not_found' : 'invalid_credential';
      case 'user-disabled':
        return 'account_disabled';
      case 'too-many-requests':
        return 'repeated_failure';
      case 'network-request-failed':
        return 'network_error';
      default:
        return 'auth_error';
    }
  }

  String _authErrorMessage(FirebaseAuthException e, {bool phoneLogin = false}) {
    switch (e.code) {
      case 'user-not-found':
      case 'invalid-credential':
        return phoneLogin
            ? 'لا يوجد حساب مرتبط بهذا الرقم'
            : 'بيانات الدخول غير صحيحة';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'user-disabled':
        return 'هذا الحساب معطّل';
      case 'network-request-failed':
        return 'تعذر الاتصال بالإنترنت. تحقق من اتصالك وأعد المحاولة.';
      case 'too-many-requests':
        return 'محاولات كثيرة. انتظر قليلاً وأعد المحاولة.';
      default:
        return 'تعذر تسجيل الدخول. تحقق من البيانات وأعد المحاولة.';
    }
  }

  // ─── تسجيل حساب جديد — مع إصلاح permission-denied ──────────────────────
  // الترتيب الصحيح: التحقق من التكرار أولاً → Auth أولاً → Firestore يدون الملف
  // ثم rollback تلقائي إن فشل إنشاء الملف، وتجنب ترك حساب معلق في Auth.
  Future<String?> signUp(
    String name,
    String familyName,
    String email,
    String password,
    String phone,
    String gender,
  ) async {
    UserCredential? cred;
    final normalizedPhone = normalizePhone(phone);
    final displayName = [
      name.trim(),
      familyName.trim(),
    ].where((part) => part.isNotEmpty).join(' ').trim();
    final authEmail = AuthProvider.canonicalRegistrationEmail(
      email,
      normalizedPhone,
    );

    _isRegistering = true;

    try {
      final existingUser = _auth.currentUser;
      if (existingUser != null &&
          (existingUser.email == authEmail ||
              existingUser.providerData.any(
                (info) => info.email == authEmail,
              ))) {
        try {
          await existingUser.updateDisplayName(displayName);

          final mergedUserData = <String, dynamic>{
            'name': displayName,
            'fullName': displayName,
            'firstName': name.trim(),
            'lastName': familyName.trim(),
            'email': email.trim().isNotEmpty
                ? email.trim().toLowerCase()
                : existingUser.email ?? '',
            'phone': normalizedPhone,
            'phoneNumber': normalizedPhone,
            'phoneNormalized': normalizedPhone,
            'gender': gender,
          };

          final savedProfile = await ensureUserDocument(
            existingUser,
            provider: email.trim().isEmpty ? 'phone' : 'email',
            registrationData: mergedUserData,
          );

          _user = existingUser;
          _userData = savedProfile.data();
          _profileReady = _userData != null;

          await _checkAdminStatus(existingUser);
          await refreshAccountStatus();

          _isRegistering = false;
          notifyListeners();
          return null;
        } catch (e) {
          debugPrint('[SignUp] Existing Auth user profile recovery failed: $e');
          _isRegistering = false;
          return 'الحساب موجود، لكن تعذر إكمال ملفه الآن. أعد المحاولة.';
        }
      }

      if (existingUser != null) {
        _isRegistering = false;
        return 'يوجد حساب مسجل الدخول حاليًا. سجّل الخروج أولًا لإنشاء حساب آخر.';
      }

      final duplicateEmail = email.trim().isNotEmpty
          ? await _firestore
                .collection('users')
                .where('email', isEqualTo: email.trim().toLowerCase())
                .limit(1)
                .get()
                .timeout(const Duration(seconds: 8))
          : null;
      final duplicatePhone = await _firestore
          .collection('users')
          .where('phoneNormalized', isEqualTo: normalizedPhone)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 8));
      final legacyDuplicatePhone = duplicatePhone.docs.isEmpty
          ? await _firestore
                .collection('users')
                .where('phone', isEqualTo: normalizedPhone)
                .limit(1)
                .get()
                .timeout(const Duration(seconds: 8))
          : null;

      if ((duplicateEmail?.docs.isNotEmpty ?? false) ||
          duplicatePhone.docs.isNotEmpty ||
          (legacyDuplicatePhone?.docs.isNotEmpty ?? false)) {
        _isRegistering = false;
        return email.trim().isEmpty
            ? 'رقم الهاتف مستخدم في حساب آخر'
            : 'هذا البريد الإلكتروني مستخدم مسبقاً';
      }

      cred = await _auth
          .createUserWithEmailAndPassword(email: authEmail, password: password)
          .timeout(const Duration(seconds: 15));

      final newUser = cred.user;
      if (newUser == null) {
        _isRegistering = false;
        return 'تعذر إنشاء الحساب. أعد المحاولة.';
      }

      try {
        await newUser.updateDisplayName(displayName);
      } catch (_) {}

      final userData = buildUserProfileData(
        uid: newUser.uid,
        name: displayName,
        email: email,
        phone: phone,
        gender: gender,
        provider: email.trim().isEmpty ? 'phone' : 'email',
      );
      userData['firstName'] = name.trim();
      userData['lastName'] = familyName.trim();
      userData['email'] = authEmail;
      userData['phone'] = normalizedPhone;
      userData['phoneNumber'] = normalizedPhone;
      userData['phoneNormalized'] = normalizedPhone;

      try {
        final savedProfile = await ensureUserDocument(
          newUser,
          provider: email.trim().isEmpty ? 'phone' : 'email',
          registrationData: userData,
        );

        _user = newUser;
        _userData = savedProfile.data();
        _profileReady = _userData != null;
      } catch (firestoreError) {
        debugPrint('[SignUp] Firestore profile write failed: $firestoreError');
        try {
          await newUser.delete();
        } catch (_) {}
        try {
          await _auth.signOut();
        } catch (_) {}
        _isRegistering = false;
        return 'تعذر إكمال إنشاء ملف الحساب (Firestore Error). حاول مجدداً.';
      }

      AdminActivityService.log(
        type: AdminActivityType.userRegistered,
        title: 'تسجيل مستخدم جديد',
        description: 'سجل مستخدم جديد باسم: $name ($authEmail)',
        targetUserId: newUser.uid,
        targetUserName: name,
        metadata: {'email': authEmail, 'phone': normalizedPhone},
      ).catchError((_) {});

      await _checkAdminStatus(newUser);
      await refreshAccountStatus();

      _isRegistering = false;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      _isRegistering = false;
      switch (e.code) {
        case 'email-already-in-use':
          return email.trim().isEmpty
              ? 'رقم الهاتف مستخدم في حساب آخر'
              : 'هذا البريد الإلكتروني مستخدم مسبقاً';
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
      _isRegistering = false;
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
    String? familyName,
    String? phone,
    String? gender,
    String? base64Image,
  }) async {
    try {
      if (_user != null) {
        final fullName = [
          name.trim(),
          (familyName ?? '').trim(),
        ].where((part) => part.isNotEmpty).join(' ').trim();

        await _user!
            .updateDisplayName(fullName.isNotEmpty ? fullName : name)
            .timeout(const Duration(seconds: 10));
        if (imageUrl != null) {
          await _user!
              .updatePhotoURL(imageUrl)
              .timeout(const Duration(seconds: 10));
        }

        final updateData = <String, dynamic>{
          'name': name.trim(),
          'fullName': fullName.isNotEmpty ? fullName : name.trim(),
          'firstName': name.trim(),
          'lastName': (familyName ?? '').trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (phone != null && phone.trim().isNotEmpty) {
          final normalizedPhone = normalizePhone(phone);
          updateData['phone'] = normalizedPhone;
          updateData['phoneNumber'] = normalizedPhone;
          updateData['phoneNormalized'] = normalizedPhone;
        }

        if (gender != null && gender.trim().isNotEmpty) {
          updateData['gender'] = gender.trim();
        }

        if (imageUrl != null) updateData['profileImageUrl'] = imageUrl;
        if (base64Image != null) updateData['profileImageBase64'] = base64Image;

        await _firestore
            .collection('users')
            .doc(_user!.uid)
            .set(updateData, SetOptions(merge: true))
            .timeout(const Duration(seconds: 10));

        _loadUserDataBackground();
        notifyListeners();
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Ensures users/{uid} exists without overwriting profile fields edited in-app.
  Future<DocumentSnapshot<Map<String, dynamic>>> ensureUserDocument(
    User user, {
    String provider = 'google',
    Map<String, dynamic>? registrationData,
  }) async {
    if (user.uid.isEmpty) {
      throw FirebaseException(plugin: 'firebase_auth', code: 'missing-uid');
    }

    final ref = _firestore.collection('users').doc(user.uid);
    final current = await ref.get().timeout(const Duration(seconds: 10));
    final data = current.data();
    final update = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
      'lastActivity': FieldValue.serverTimestamp(),
    };

    if (!current.exists) {
      if (registrationData != null) {
        update.addAll(registrationData);
        update['uid'] = user.uid;
        if (!update.containsKey('createdAt')) {
          update['createdAt'] = FieldValue.serverTimestamp();
        }
      } else {
        final fallbackName = safeFallbackDisplayName(
          fullName: user.displayName,
          email: user.email,
          provider: provider,
        );
        update.addAll({
          'uid': user.uid,
          'fullName': fallbackName,
          'name': fallbackName,
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
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } else if (data != null) {
      if (!data.containsKey('fullName') && !data.containsKey('name')) {
        update['fullName'] = safeFallbackDisplayName(
          fullName: user.displayName,
          email: user.email,
          provider: provider,
        );
      }
      if (!data.containsKey('authProvider') && !data.containsKey('provider')) {
        update['authProvider'] = provider;
        update['provider'] = provider;
      }
      if (!data.containsKey('createdAt')) {
        update['createdAt'] = FieldValue.serverTimestamp();
      }
      if (registrationData != null) {
        final safeUpdates = Map<String, dynamic>.from(registrationData)
          ..remove('uid')
          ..remove('role')
          ..remove('isActive')
          ..remove('createdAt');
        update.addAll(safeUpdates);
      }
    }

    try {
      await ref
          .set(update, SetOptions(merge: true))
          .timeout(const Duration(seconds: 10));
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        debugPrint(
          '[Auth] ensureUserDocument permission denied for ${user.uid}; refreshing token and retrying once.',
        );
        await user.getIdToken(true);
        await ref
            .set(update, SetOptions(merge: true))
            .timeout(const Duration(seconds: 10));
      } else {
        rethrow;
      }
    }
    final saved = await ref.get().timeout(const Duration(seconds: 10));
    if (!saved.exists || saved.data() == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'profile-not-created',
      );
    }
    _userData = saved.data();
    _mustChangePassword = _userData?['mustChangePassword'] == true;
    _profileReady = true;
    return saved;
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
}
