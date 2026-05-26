plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
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

    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug") 
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
