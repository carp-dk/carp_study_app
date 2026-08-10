# Preserve app + Movesense MDS classes
-keep class dk.cachet.carp_study_app.** { *; }
-keep class com.google.android.play.core.** { *; }
-keep class org.joda.convert.** { *; }

# Preserve all classes and methods that might contain callback methods
-keep class * {
    public void SDSInternalCallback(int, int, java.lang.String, byte[]);
}

# Preserve all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Preserve all classes and methods in your app's package
-keep class com.movesense.mds.**{*;}

# Please add these rules to your existing keep rules in order to suppress warnings.
# This is generated automatically by the Android Gradle plugin.
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task
-dontwarn org.joda.convert.FromString
-dontwarn org.joda.convert.ToString