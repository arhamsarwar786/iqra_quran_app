# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ObjectBox
-keep class io.objectbox.relation.ToMany { *; }
-keep class io.objectbox.relation.ToOne { *; }
-keep class * extends io.objectbox.relation.ToOne

# If you use the @Entity annotation:
-keep @io.objectbox.annotation.Entity class * { *; }

# If you use the @Id annotation:
-keepclassmembers class * {
    @io.objectbox.annotation.Id <fields>;
}

# Keep the generated MyObjectBox class
-keep class com.devsinntechnologies.iqraquran.objectbox.MyObjectBox { *; }
-keep class **.MyObjectBox { *; }

# Just Audio
-keep class com.ryanheise.just_audio.** { *; }
-keep class com.google.android.exoplayer2.** { *; }

# Adhan / Geolocation
-keep class com.google.android.gms.** { *; }
-keep class com.baseflow.geolocator.** { *; }

# Google Play Core (Resolves R8 missing class errors in Flutter)
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.google.gson.** { *; }
-keepattributes Signature, *Annotation*, EnclosingMethod
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep class * implements com.google.gson.TypeAdapter

# Keep members of any class that might be serialized/deserialized
-keepclassmembers class * {
  @com.google.gson.annotations.SerializedName <fields>;
}
