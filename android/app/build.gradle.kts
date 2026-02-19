plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.first_app"
    compileSdk = 34 // Replace flutter.compileSdkVersion if needed

    ndkVersion = "27.0.12077973" // Force stable NDK

    defaultConfig {
        applicationId = "com.example.first_app"
        minSdk = flutter.minSdkVersion // Replace flutter.minSdkVersion if needed
        targetSdk = 34 // Replace flutter.targetSdkVersion if needed
        versionCode = 1 // Replace flutter.versionCode if needed
        versionName = "1.0.0" // Replace flutter.versionName if needed
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug") // For release, create proper signing
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    // Optional: Enable viewBinding if you use Android views
    // buildFeatures {
    //     viewBinding = true
    // }
}

flutter {
    source = "../.."
}
