import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

// Written by tools/apply_tenant.py – one file per active tenant
val tenant = Properties().apply {
    val f = rootProject.file("tenant.properties"); if (f.exists()) f.inputStream().use { load(it) }
}
val ks = Properties().apply {
    val p = tenant.getProperty("keystoreProperties"); if (p != null && file(p).exists()) file(p).inputStream().use { load(it) }
}

android {
    packaging { jniLibs { useLegacyPackaging = true; excludes += listOf("lib/armeabi-v7a/**", "lib/x86_64/**", "lib/x86/**") } }
    buildFeatures { resValues = true }
    namespace = "de.bartuan.loyalty.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        ndk { abiFilters += listOf("arm64-v8a") }
        applicationId = tenant.getProperty("packageId", "de.bartuan.loyalty.template")
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        versionCode = tenant.getProperty("versionCode", "1").toInt()
        versionName = tenant.getProperty("versionName", "1.0")
        resValue("string", "app_name", tenant.getProperty("appName", "Loyalty").replace("\\", "").replace("'", "\\'").replace("\"", "\\\""))
    }

    signingConfigs {
        if (ks.getProperty("storeFile") != null) create("tenant") {
            storeFile = file(ks.getProperty("storeFile"))
            storePassword = ks.getProperty("storePassword")
            keyAlias = ks.getProperty("keyAlias")
            keyPassword = ks.getProperty("keyPassword")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("tenant") ?: signingConfigs.getByName("debug")
        }
    }
}

dependencies { coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") }

kotlin { compilerOptions { jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17 } }

flutter { source = "../.." }
