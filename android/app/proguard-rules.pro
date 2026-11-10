# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Media Kit (MPV native video player & JNI bindings)
-keep class com.alexmercerind.mediakit.** { *; }
-keep class com.ryanheise.** { *; }
-keep class media.kmp.** { *; }
-keepclasseswithmembernames class * {
    native <methods>;
}

# WebView Flutter (Embedded streams & JavaScript Interfaces)
-keepattributes JavascriptInterface
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keep class io.flutter.plugins.webviewflutter.** { *; }

# Plus plugins (Connectivity Plus, Package Info Plus)
-keep class dev.fluttercommunity.plus.** { *; }
-keep class io.flutter.plugins.pathprovider.** { *; }

# Keep all native methods across the project
-keepclasseswithmembers class * {
    native <methods>;
}

# Parcelable & Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    !private <fields>;
    !private <methods>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Don't warn on known library references
-dontwarn io.flutter.**
-dontwarn com.alexmercerind.**
-dontwarn dev.fluttercommunity.**

# AndroidX WorkManager & Worker classes
-keep class com.primadev.cineva.UpdateCheckWorker { *; }
-keep class com.primadev.cineva.UpdateAlarmReceiver { *; }
-keep class androidx.work.** { *; }
-keep class * extends androidx.work.ListenableWorker {
    public <init>(android.content.Context, androidx.work.WorkerParameters);
}

# Firebase & Google Play Services
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
-keep class io.flutter.plugins.firebase.** { *; }

# Firebase Auth, Database & Google Sign In
-keep class io.flutter.plugins.firebase.auth.** { *; }
-keep class io.flutter.plugins.firebase.database.** { *; }
-keep class io.flutter.plugins.googlesignin.** { *; }
-keep class com.google.android.gms.auth.api.signin.** { *; }
-keep class com.google.firebase.auth.** { *; }
-keep class com.google.firebase.database.** { *; }
-dontwarn com.google.android.gms.auth.api.signin.**

# Firebase Analytics & App Measurement
-keep class com.google.android.gms.measurement.** { *; }
-keep class com.google.android.gms.common.** { *; }

# Keep google-services generated resource identifiers from resource shrinking
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Mobile Scanner & Google ML Kit Barcode
-keep class dev.steenbakker.mobile_scanner.** { *; }
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Image Picker & File Picker
-keep class io.flutter.plugins.imagepicker.** { *; }
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# SQFlite & URL Launcher
-keep class com.tekartik.sqflite.** { *; }
-keep class io.flutter.plugins.urllauncher.** { *; }

# Screen Brightness, Volume Controller & Wakelock Plus
-keep class com.github.linusu.screen_brightness.** { *; }
-keep class com.kurenai.volume_controller.** { *; }
-keep class dev.fluttercommunity.plus.wakelock.** { *; }
-keep class androidx.core.content.FileProvider { *; }

