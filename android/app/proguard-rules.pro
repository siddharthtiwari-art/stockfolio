# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep http / networking
-dontwarn okhttp3.**
-dontwarn okio.**

# Keep JSON model fields
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.sid.stockfolio.** { *; }
