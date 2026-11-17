import java.io.File
import java.io.FileInputStream
import java.util.*

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing. Values come from android/key.properties when it exists
// (gitignored), otherwise from environment variables, so the store and key
// passwords can be injected at build time (e.g. read from macOS Keychain)
// without ever being written to disk:
//   COLOPHON_KEYSTORE, COLOPHON_KEY_ALIAS, COLOPHON_STORE_PASSWORD,
//   COLOPHON_KEY_PASSWORD
val keyProperties = Properties().apply {
    val file = File("key.properties")
    if (file.exists()) load(FileInputStream(file))
}

fun signingValue(property: String, env: String): String? =
    keyProperties.getProperty(property) ?: System.getenv(env)

val detKeyAlias = signingValue("keyAlias", "COLOPHON_KEY_ALIAS")
val detKeyPassword = signingValue("keyPassword", "COLOPHON_KEY_PASSWORD")
val detStoreFile = signingValue("storeFile", "COLOPHON_KEYSTORE")
val detStorePassword = signingValue("storePassword", "COLOPHON_STORE_PASSWORD")
val hasReleaseSigning =
    listOf(detKeyAlias, detKeyPassword, detStoreFile, detStorePassword).all { it != null }

android {
    namespace = "de.doen1el.calibreWebCompanion"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    defaultConfig {
        // Colophon is a fork of Calibre Web Companion with its own identity,
        // so it installs next to the original. The Kotlin package
        // (namespace) is unchanged: native code and widget providers are
        // addressed by it, not by the application id.
        applicationId = "io.github.z33dd.colophon"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode * 10 + 3
        versionName = flutter.versionName

        manifestPlaceholders["appLabel"] = "Colophon"
    }

    dependenciesInfo {
        // Disables dependency metadata when building APKs.
        includeInApk = false
        // Disables dependency metadata when building Android App Bundles.
        includeInBundle = false
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = detKeyAlias
                keyPassword = detKeyPassword
                storeFile = file(detStoreFile!!)
                storePassword = detStorePassword
            }
        }
    }

    buildTypes {
        getByName("debug") {
            // Own applicationId so a local debug build installs next to the
            // release app instead of replacing it.
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
            manifestPlaceholders["appLabel"] = "Colophon Debug"

            isMinifyEnabled = true
            isShrinkResources = true

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            isDebuggable = true
        }

        getByName("release") {
            // No signing values: the release APK stays unsigned (it won't
            // install) instead of silently using the debug key. Debug builds
            // are unaffected.
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                logger.warn("Colophon: release signing not configured; APK will be unsigned.")
            }

            isMinifyEnabled = true
            isShrinkResources = true
            
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
    }
}

flutter {
    source = "../.."
}