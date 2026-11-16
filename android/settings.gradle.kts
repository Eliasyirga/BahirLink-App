pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val sdkPath = properties.getProperty("flutter.sdk")
        require(sdkPath != null) { "flutter.sdk not set in local.properties" }
        sdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
    }
}

// Updated root name to match project
rootProject.name = "BahirLink-App"
include(":app")

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // AGP 8.13.1 with Gradle 9.1.0
    id("com.android.application") version "8.13.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.0" apply false
}