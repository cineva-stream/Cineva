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
