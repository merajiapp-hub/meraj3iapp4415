import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.bebeye.myapp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.bebeye.myapp"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // Minification is REQUIRED by Shorebird to merge all DEX into one file
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
dependencies {
  // Core library desugaring (required by flutter_local_notifications)
  coreLibraryDesugaring("com.android.tools:desugar_jdk_libs_nio:2.1.4")

  // MultiDex support (required by Shorebird)
  implementation("androidx.multidex:multidex:2.0.1")

  // Import the Firebase BoM
  implementation(platform("com.google.firebase:firebase-bom:34.10.0"))

  // When using the BoM, don't specify versions in Firebase dependencies
  implementation("com.google.firebase:firebase-analytics")

  // Add the dependencies for any other desired Firebase products
  // https://firebase.google.com/docs/android/setup#available-libraries
}

configurations.all {
    resolutionStrategy {
        force("androidx.browser:browser:1.8.0")
        force("androidx.activity:activity-ktx:1.9.3")
        force("androidx.activity:activity:1.9.3")
        force("androidx.core:core-ktx:1.13.1")
        force("androidx.core:core:1.13.1")
        force("androidx.navigationevent:navigationevent-android:1.0.0")
    }
}

// Fix: Ensure Kotlin compiles before Java to allow GeneratedPluginRegistrant.java
// to reference Kotlin classes from Firebase and other plugins.
afterEvaluate {
    listOf("Debug", "Release").forEach { variant ->
        tasks.findByName("compile${variant}JavaWithJavac")?.let { task ->
            task.dependsOn("compile${variant}Kotlin")
        }
    }
    
    // FORCE JAVAC to use Java 17
    tasks.withType(JavaCompile::class.java).configureEach {
        options.release.set(17)
        sourceCompatibility = "17"
        targetCompatibility = "17"
    }
}