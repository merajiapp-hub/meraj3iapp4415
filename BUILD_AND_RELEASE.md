# دليل البناء والإصدار — MERAJ3I

> آخر تحديث: أكتوبر 2026 | الإصدار: 6.9.8+22

---

## 1. الإصدارات المعتمدة والمثبّتة

| الأداة | الإصدار المعتمد | ملاحظة |
|--------|----------------|---------|
| Flutter (محلي) | **3.47.5** | channel stable |
| Flutter (Shorebird) | **3.47.6** | مضمّن في Shorebird |
| Dart | **3.13.4** | مع Flutter 3.47.5 |
| Shorebird | **1.6.124+** | استخدم shorebird upgrade للتحديث |
| Gradle Wrapper | **8.14** | في gradle-wrapper.properties |
| Android Gradle Plugin | **8.11.1** | في settings.gradle.kts |
| Kotlin | **2.2.20** | في settings.gradle.kts |
| Java | **17** | JAVA_HOME=C:\Program Files\Java\jdk-17.0.20.1 |
| Android minSdk | **24** | في app/build.gradle.kts |
| Java Compatibility | **17** | sourceCompatibility + targetCompatibility |

---

## 2. السبب الجذري للعطل (اكتوبر 2026) — موثَّق

### المشكلة
فشل امر shorebird release android بسبب:

    registration of listener on 'Gradle.buildFinished' is unsupported
    registration of listener on 'Gradle.addListener' is unsupported
    Task ':app:compileFlutterBuildRelease' invocation of 'Task.project' is unsupported

### السبب الجذري
كان android/gradle.properties يحتوي على:
    org.gradle.configuration-cache=true   <-- الجاني

سكربت Shorebird الداخلي shorebird_trace_init.gradle يستخدم APIs قديمة من Gradle
غير متوافقة مع Configuration Cache في Gradle 8+.

### الإصلاح المطبَّق
    org.gradle.configuration-cache=false

### لماذا هذا الحل؟
- Configuration Cache ميزة اختيارية لتسريع البناء المتكرر
- Shorebird لا يدعمها رسمياً حتى تاريخ هذا التوثيق
- لا يؤثر تعطيلها على صحة التطبيق او وظائفه

---

## 3. متطلبات البيئة

`powershell
C:\Program Files\Java\jdk-27 = "C:\Program Files\Java\jdk-17.0.20.1"
 = "-Duser.language=en -Duser.country=US"
`

ملفات إعداد Android المطلوبة:
- android/key.properties         : بيانات مفتاح التوقيع (لا تُضف للـ git)
- android/upload-keystore.jks    : مفتاح التوقيع (لا تُضف للـ git)
- android/local.properties       : مسار Flutter SDK (مولَّد تلقائياً)
- android/app/google-services.json : إعدادات Firebase

---

## 4. اوامر البناء والإصدار

`powershell
# فحص سريع
.\tooling\pre_release_check.ps1 -Mode check

# بناء APK للاختبار
flutter build apk --release
# الناتج: build\app\outputs\flutter-apk\app-release.apk

# بناء AAB لـ Play Store
flutter build appbundle --release
# الناتج: build\app\outputs\bundle\release\app-release.aab

# إصدار Shorebird
.\build-release.ps1
# او يدوياً:
shorebird release android --artifact apk

# نشر Patch
shorebird patch android --artifact apk
`

---

## 5. خطوات الإصدار الكاملة بالترتيب

1. flutter clean
2. flutter pub get
3. flutter analyze          # يجب ان يعطي "No issues found"
4. flutter build apk --release
5. flutter build appbundle --release
6. shorebird release android --artifact apk

قاعدة: لا تنتقل للخطوة التالية اذا فشلت السابقة.

---

## 6. الاخطاء المعروفة وحلولها

### Gradle.buildFinished / Gradle.addListener / Task.project
الحل: android/gradle.properties يجب ان يحتوي على:
    org.gradle.configuration-cache=false

### Flutter SDK not found في Gradle
الحل: شغّل flutter pub get لتوليد android/local.properties

### DEX او MultiDex
الحل: تاكد في app/build.gradle.kts:
    multiDexEnabled = true

### توقيع APK فاشل
الحل: تحقق من android/key.properties وصحة المسارات

### ارقام عربية في ملفات الإصدار
الحل: تاكد في gradle.properties:
    -Duser.language=en -Duser.country=US

---

## 7. كيفية تحديث ادوات البناء بامان

ترتيب التحديث الامن:
1. تحديث Shorebird اولاً: shorebird upgrade
2. التحقق من متطلبات الإصدار الجديد
3. تحديث Gradle اذا طُلب
4. تحديث AGP اذا طُلب
5. اختبار البناء قبل رفع اي إصدار

قاعدة ذهبية: لا تحدّث اكثر من اداة واحدة في المرة الواحدة.

مصفوفة التوافق:
- AGP vs Gradle: https://developer.android.com/build/releases/gradle-plugin
- Shorebird vs Flutter: https://docs.shorebird.dev/

---

## 8. خطوات استعادة الحالة السابقة

`powershell
git log --oneline -10
git checkout HEAD -- android/gradle.properties
git checkout HEAD -- android/gradle/wrapper/gradle-wrapper.properties
git checkout HEAD -- android/settings.gradle.kts
git checkout HEAD -- android/build.gradle.kts
git checkout HEAD -- android/app/build.gradle.kts
flutter clean
flutter pub get
flutter build apk --release
`

---

## 9. الامور التي يجب عدم تغييرها بدون سبب

| الإعداد | القيمة الحالية | السبب |
|---------|--------------|-------|
| applicationId | com.bebeye.myapp | معرّف التطبيق في Play Store |
| minSdk | 24 | متطلب minimum لـ local_auth وغيره |
| isMinifyEnabled | true | مطلوب من Shorebird لدمج DEX |
| configuration-cache | false | توافق Shorebird |
| multiDexEnabled | true | مطلوب من Shorebird |
| pubspec.lock | لا تحذف | يثبّت إصدارات الحزم |

---

## 10. معلومات Shorebird

- App ID: b400a658-8957-4625-bd03-0d800bba19e3
- لوحة التحكم: https://console.shorebird.dev
- Flutter المستخدم من Shorebird: 3.47.6 (مختلف قليلاً عن المحلي 3.47.5)
- هذا الاختلاف الصغير طبيعي ومقبول

---

## 11. ملاحظات امنية

- android/key.properties في .gitignore
- android/upload-keystore.jks في .gitignore
- لا تضع كلمات مرور او مفاتيح API في الكود
- لا تضع Shorebird token في الملفات المُرفوعة للـ git
