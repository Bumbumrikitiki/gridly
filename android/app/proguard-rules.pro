# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**
-ignorewarnings

# Keep Flutter-related classes
-keep class com.google.android.material.** { *; }
-keep interface com.google.android.material.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep interface com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Google Mobile Ads
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enum values and valueOf() methods when building libraries
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Parcelable
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# PDF and Printing
-keep class com.itextpdf.** { *; }
-keep interface com.itextpdf.** { *; }

# Torch Light
-keep class dev.fluttercommunity.plus.torch_light.** { *; }

# Path Provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# Permission Handler
-keep class com.baseflow.permissionhandler.** { *; }
