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
        isCoreLibraryDesugaringEnabled = true
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

// Automatically generate Cineva_v{version}-{abi}.apk and Cineva_v{version}.apk after release assemble
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
        val finalVersion = version ?: "1.1.2"
        val flutterApkDir = File(rootDir.parentFile, "build/app/outputs/flutter-apk")
        val gradleApkDir = File(layout.buildDirectory.get().asFile, "outputs/apk/release")

        flutterApkDir.mkdirs()

        // Mapping of source Gradle APK names to customized Cineva release filenames
        val apkMapping = mapOf(
            "app-arm64-v8a-release.apk" to listOf("Cineva_v${finalVersion}-arm64-v8a.apk"),
            "app-armeabi-v7a-release.apk" to listOf("Cineva_v${finalVersion}-armeabi-v7a.apk"),
            "app-x86_64-release.apk" to listOf("Cineva_v${finalVersion}-x86_64.apk"),
            "app-release.apk" to listOf("Cineva_v${finalVersion}.apk")
        )

        val activeCustomNames = apkMapping.values.flatten().toSet()

        // Clean up previous older version Cineva_v*.apk files so directory stays tidy
        flutterApkDir.listFiles()?.filter { it.name.startsWith("Cineva_v") && it.name.endsWith(".apk") }?.forEach { oldFile ->
            if (!activeCustomNames.contains(oldFile.name)) {
                oldFile.delete()
            }
        }

        println("\n=======================================================")
        println(" [Cineva Release] Output APK Artifacts Generated:")

        var generatedCount = 0
        apkMapping.forEach { (sourceName, targetNames) ->
            val sourceApk = listOf(
                File(gradleApkDir, sourceName),
                File(flutterApkDir, sourceName)
            ).firstOrNull { it.exists() }

            if (sourceApk != null) {
                targetNames.forEach { targetName ->
                    val destInFlutter = File(flutterApkDir, targetName)
                    val destInGradle = File(gradleApkDir, targetName)
                    sourceApk.copyTo(destInFlutter, overwrite = true)
                    sourceApk.copyTo(destInGradle, overwrite = true)
                    println(" -> ${destInFlutter.name} (${destInFlutter.length() / (1024 * 1024)} MB)")
                    generatedCount++
                }
            }
        }

        if (generatedCount == 0) {
            println(" (No release APKs found to rename in ${gradleApkDir.name})")
        }
        println(" Target Output: ${flutterApkDir.absolutePath}")
        println("=======================================================\n")
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    val media3Version = "1.8.0"
    implementation("androidx.media3:media3-common:$media3Version")
    implementation("androidx.media3:media3-transformer:$media3Version")
    implementation("androidx.media3:media3-muxer:$media3Version")
    implementation("androidx.media3:media3-extractor:$media3Version")
    implementation("androidx.work:work-runtime-ktx:2.9.0")
}
