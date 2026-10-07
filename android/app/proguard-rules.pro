## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

## Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

## flutter_local_notifications
-keep class com.dexterous.** { *; }

## Keep all model classes
-keepclassmembers class ** {
    @com.google.gson.annotations.SerializedName <fields>;
}

## Gson
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**

## General Android
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

## ─── FIX: R8 missing Play Core classes (referenced by Flutter engine) ───
## These classes are referenced by Flutter's deferred component manager
## but are NOT needed for apps that don't use deferred components.
## Using -dontwarn suppresses the error without adding the library.
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

## Keep the Play Core class references alive but don't fail if missing
-keep class com.google.android.play.core.splitcompat.SplitCompatApplication { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

## ─── FIX: Kotlin metadata version mismatch ───
-dontwarn kotlin.Metadata
-dontwarn kotlinx.**

## ─── FIX: Firebase Auth Kotlin metadata warning ───
-dontwarn com.google.firebase.auth.AuthKt

## Suppress all other warnings to prevent build failures
-ignorewarnings
