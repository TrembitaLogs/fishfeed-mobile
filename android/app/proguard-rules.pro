# Flutter-specific ProGuard rules

# Keep Flutter engine classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Keep Google Play Services (for Google Sign-In, Ads)
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Keep AndroidX classes used by plugins
-keep class androidx.** { *; }
-dontwarn androidx.**

# Keep workmanager classes
-keep class androidx.work.** { *; }

# Keep classes for flutter_local_notifications
-keep class com.dexterous.** { *; }

# Keep classes for flutter_secure_storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }
