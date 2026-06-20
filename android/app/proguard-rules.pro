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

# Suppress missing Play Core classes (used by Flutter for deferred components)
-dontwarn com.google.android.play.core.**

# Keep RevenueCat (purchases_flutter) native SDK — used reflectively for
# subscriptions/IAP. Without this, release (minified) builds can break purchases.
-keep class com.revenuecat.purchases.** { *; }
-dontwarn com.revenuecat.purchases.**

# Keep Play Billing classes used by RevenueCat.
-keep class com.android.billingclient.** { *; }
-dontwarn com.android.billingclient.**

# Keep PostHog (posthog_flutter) native SDK so analytics keep working in release.
-keep class com.posthog.** { *; }
-dontwarn com.posthog.**

# NOTE: Hive needs no ProGuard keep — it is pure Dart (runs in the Dart VM,
# not the JVM), so R8/ProGuard cannot strip its generated TypeAdapters.
