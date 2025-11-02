# QuicUI Code Push - ProGuard Rules
# Preserve FlutterLoader and QuicUI Code Push classes

# Keep FlutterLoader class and all its methods
-keep class io.flutter.embedding.engine.loader.FlutterLoader { *; }
-keepclassmembers class io.flutter.embedding.engine.loader.FlutterLoader { *; }

# Keep QuicUICodePushLoader class and all its methods
-keep class io.flutter.embedding.engine.loader.QuicUICodePushLoader { *; }
-keepclassmembers class io.flutter.embedding.engine.loader.QuicUICodePushLoader { *; }

# CRITICAL: Don't remove any Log calls (preserve all logging)
-assumenosideeffects class android.util.Log {
    # Comment out to preserve ALL logs including debug
    # public static *** d(...);
    # public static *** v(...);
}

# Keep all android.util.Log methods (don't strip info, warning, error logs)
-keep class android.util.Log {
    public static *** d(...);
    public static *** i(...);
    public static *** w(...);
    public static *** e(...);
    public static *** v(...);
}

# Don't optimize or obfuscate QuicUI classes
-keepnames class io.flutter.embedding.engine.loader.** { *; }

# Keep all methods in QuicUI Code Push plugin
-keep class com.quicui.** { *; }
-keepclassmembers class com.quicui.** { *; }

# Preserve line numbers for debugging stack traces
-keepattributes SourceFile,LineNumberTable

# Keep annotations
-keepattributes *Annotation*

# Standard Flutter rules (if not already included)
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }

# Preserve native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Context parameter in constructors (needed for QuicUICodePushLoader)
-keepclassmembers class * {
    public <init>(android.content.Context);
}
