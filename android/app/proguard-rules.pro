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

## Keep all model classes (adjust package if needed)
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
