import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/favorite_results_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/quiz_provider.dart';
import 'providers/task_provider.dart';
import 'providers/downloads_provider.dart';
import 'providers/notifications_provider.dart';
import 'providers/reading_provider.dart';
import 'providers/statistics_provider.dart';
import 'providers/schedule_provider.dart';
import 'providers/student_provider.dart';
import 'providers/notes_provider.dart';
import 'screens/splash_screen.dart';
import 'data/notification_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:receive_intent/receive_intent.dart';
import 'data/ad_manager.dart';
import 'screens/pdf_viewer_screen.dart';
import 'services/remote_config_service.dart';

// معالج الإشعارات في الخلفية الكاملة (يجب أن يكون دالة عامة خارج الكلاس)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Background message: ${message.notification?.title}');

  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      final title =
          message.notification?.title ?? message.data['title'] ?? 'إشعار جديد';
      final body = message.notification?.body ?? message.data['body'] ?? '';
      final typeStr = message.data['type'];
      int type = 0;
      switch (typeStr) {
        case 'update':
          type = 1;
          break;
        case 'reminder':
          type = 2;
          break;
        case 'system':
          type = 3;
          break;
      }

      final id = DateTime.now().millisecondsSinceEpoch.toString();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(id)
          .set({
            'id': id,
            'title': title,
            'body': body,
            'type': type,
            'isRead': false,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
    } catch (e) {
      debugPrint('Background save error: $e');
    }
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// يعالج ملفات PDF التي تُفتح عبر MERAJ3I من مدير الملفات أو المتصفح
void _handleIncomingPdfIntent() async {
  try {
    final intent = await ReceiveIntent.getInitialIntent();
    if (intent != null && intent.data != null) {
      final String? path = intent.data;
      if (path != null && path.toLowerCase().endsWith('.pdf')) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => PdfViewerScreen(
                pdfUrl: '',
                localPath: path.replaceFirst('file://', ''),
                title: path.split('/').last,
                book: null,
              ),
            ),
          );
        });
      }
    }
  } catch (e) {
    debugPrint('PDF intent handling error: $e');
  }

  ReceiveIntent.receivedIntentStream.listen((intent) {
    if (intent?.data != null) {
      final String? path = intent!.data;
      if (path != null && path.toLowerCase().endsWith('.pdf')) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => PdfViewerScreen(
              pdfUrl: '',
              localPath: path.replaceFirst('file://', ''),
              title: path.split('/').last,
              book: null,
            ),
          ),
        );
      }
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── العمليات الحرجة فقط قبل runApp ──────────────────────────────────

  // منع تدوير الشاشة
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // تفعيل وضع الشاشة الكاملة وإخفاء أزرار النظام السفلية
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // شريط الحالة وشريط التنقل شفافان مع تعطيل التباين الإجباري لتحقيق Edge-to-Edge حقيقي
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  // تهيئة Firebase (حرجة — مطلوبة قبل runApp)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Enable Offline Persistence for performance
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // إعداد معالج الإشعارات في الخلفية الكاملة
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  // ── تشغيل التطبيق أولاً ────────────────────────────────────────────
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => FavoriteResultsProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => DownloadsProvider()),
        ChangeNotifierProxyProvider<AuthProvider, NotificationsProvider>(
          create: (_) => NotificationsProvider(),
          update: (_, auth, previous) {
            previous?.updateUser(auth.user?.uid);
            return previous!;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, ReadingProvider>(
          create: (_) => ReadingProvider(),
          update: (_, auth, previous) {
            previous?.updateUid(auth.user?.uid);
            return previous!;
          },
        ),
        ChangeNotifierProvider(create: (_) => StatisticsProvider()),
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
        ChangeNotifierProvider(create: (_) => NotesProvider()),
      ],
      child: const Meraj3iApp(),
    ),
  );

  // ── العمليات الثقيلة في الخلفية بعد runApp ──────────────────────────
  _initHeavyServicesAsync();
}

/// عمليات ثقيلة تُنفَّذ في الخلفية بعد ظهور الـ UI
Future<void> _initHeavyServicesAsync() async {
  // انتظار frame واحد لضمان ظهور الـ UI أولاً
  await Future.delayed(const Duration(milliseconds: 150));

  // تهيئة الإشعارات المحلية
  try {
    await NotificationService().init();
  } catch (e) {
    debugPrint('Notification init error: $e');
  }

  // تهيئة AdMob
  try {
    await MobileAds.instance.initialize();
    AdManager.loadInterstitialAd();
    AdManager.loadRewardedAd();
  } catch (e) {
    debugPrint('AdMob init error: $e');
  }

  // طلب صلاحية الإشعارات و FCM Token
  try {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    final token = await FirebaseMessaging.instance.getToken();
    debugPrint('FCM Token: $token');
  } catch (e) {
    debugPrint('FCM init error: $e');
  }

  // تهيئة Remote Config في الخلفية (prefetch للنتائج)
  try {
    await RemoteConfigService.instance.initialize();
  } catch (e) {
    debugPrint('RemoteConfig init error: $e');
  }

  // معالجة PDF intent
  _handleIncomingPdfIntent();
}

class Meraj3iApp extends StatelessWidget {
  const Meraj3iApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Meraj3i',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      navigatorKey: navigatorKey,
      locale: const Locale('ar', ''),
      // دعم كامل للغة العربية RTL
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
      home: const SplashScreen(),
    );
  }
}
