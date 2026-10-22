import java.util.Properties
import java.io.FileInputStream
import java.io.File

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.primadev.cineva"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.primadev.cineva"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a")
        }
    }

    signingConfigs {
        create("release") {
            val keyAliasVal = keystoreProperties.getProperty("keyAlias")
            val keyPasswordVal = keystoreProperties.getProperty("keyPassword")
            val storeFileVal = keystoreProperties.getProperty("storeFile")
            val storePasswordVal = keystoreProperties.getProperty("storePassword")

            if (storeFileVal != null && keyAliasVal != null && storePasswordVal != null && keyPasswordVal != null) {
                val resolvedStoreFile = if (File(storeFileVal).isAbsolute) {
                    File(storeFileVal)
                } else {
                    val inApp = file(storeFileVal)
                    if (inApp.exists()) inApp else rootProject.file(storeFileVal)
                }
                storeFile = resolvedStoreFile
                storePassword = storePasswordVal
                keyAlias = keyAliasVal
                keyPassword = keyPasswordVal
            }
        }
    }

    buildTypes {
        release {
            val releaseSigning = signingConfigs.findByName("release")
            if (releaseSigning?.storeFile?.exists() == true) {
                signingConfig = releaseSigning
            } else {
                signingConfig = signingConfigs.getByName("debug")
            }
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

// Automatically generate Cineva_v{version}.apk after release assemble
afterEvaluate {
    tasks.findByName("assembleRelease")?.doLast {
        var version = flutter.versionName ?: android.defaultConfig.versionName
        if (version.isNullOrEmpty()) {
            val pubspecFile = File(rootDir.parentFile, "pubspec.yaml")
            if (pubspecFile.exists()) {
                val match = Regex("""version:\s*([0-9]+\.[0-9]+\.[0-9]+)""").find(pubspecFile.readText())
                if (match != null) {
                    version = match.groupValues[1]
                }
            }
        }
        val finalVersion = version ?: "1.0.1"
        val customName = "Cineva_v${finalVersion}.apk"
        val flutterApkDir = File(rootDir.parentFile, "build/app/outputs/flutter-apk")
        val gradleApkDir = File(layout.buildDirectory.get().asFile, "outputs/apk/release")

        flutterApkDir.mkdirs()

        // Clean up previous Cineva_v*.apk so only the active version is present
        flutterApkDir.listFiles()?.filter { it.name.startsWith("Cineva_v") && it.name.endsWith(".apk") }?.forEach { oldFile ->
            if (oldFile.name != customName) {
                oldFile.delete()
            }
        }

        val gradleApk = File(gradleApkDir, "app-release.apk")
        if (gradleApk.exists()) {
            val destInFlutter = File(flutterApkDir, customName)
            val destInGradle = File(gradleApkDir, customName)
            gradleApk.copyTo(destInFlutter, overwrite = true)
            gradleApk.copyTo(destInGradle, overwrite = true)
            println("\n=======================================================")
            println(" [Cineva Release] Output APK Successfully Generated:")
            println(" -> ${destInFlutter.absolutePath}")
            println("=======================================================\n")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
