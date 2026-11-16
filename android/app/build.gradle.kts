import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing: android/key.properties (git-ignored) with
//   storePassword=...  keyPassword=...  keyAlias=...  storeFile=<path to .jks>
// When it is absent (CI, fresh clones) release builds fall back to the debug
// key so `flutter build apk --release` still works — such APKs must NOT be
// published to the Play Store.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

android {
    // Clean namespace config matching standard production naming convention
    namespace = "com.bahirlink.app"
    compileSdk = 36 

    // Updated unified NDK version to eliminate cross-plugin build dependencies mismatch
    ndkVersion = "28.2.13676358" 

    defaultConfig {
        applicationId = "com.bahirlink.app"
        minSdk = flutter.minSdkVersion // Set to 21 to explicitly support flutter_launcher_icons config
        targetSdk = 36 
        versionCode = 1 
        versionName = "1.0.0" 
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }
}

flutter {
    source = "../.."
}
