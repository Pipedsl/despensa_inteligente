# Flutter core
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }

# Firebase — conserva clases con models que usan reflection (Firestore)
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Firestore: modelos y campos anotados
-keepclasseswithmembers class * {
    @com.google.firebase.firestore.PropertyName <methods>;
}
-keepclasseswithmembers class * {
    @com.google.firebase.firestore.DocumentId <fields>;
}

# Google Sign-In
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }

# ML Kit Barcode Scanning (mobile_scanner)
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_** { *; }
-dontwarn com.google.mlkit.**

# GRPC (usado por Firestore)
-keep class io.grpc.** { *; }
-dontwarn io.grpc.**

# OkHttp (usado por http + Firebase + clients HTTP en general)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }

# Gson (reflection para serialización JSON)
-keepattributes Signature
-keep class com.google.gson.** { *; }
-keep class com.google.gson.reflect.TypeToken
-keep class * extends com.google.gson.reflect.TypeToken

# Kotlin metadata (reflection)
-keep class kotlin.Metadata { *; }
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# Mantener los POJOs usados por Firestore (modelos de la app)
# Si se agregan nuevos models con reflection, agregar sus paths acá.
-keep class com.webiados.despensa_inteligente.** { *; }

# Play Core — Flutter engine lo referencia para deferred components
# (no usamos deferred components — ignoramos los warnings)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Evitar warnings de clases referenciadas pero no usadas en release
-dontwarn javax.annotation.**
-dontwarn org.checkerframework.**
-dontwarn org.codehaus.mojo.animal_sniffer.**
-dontwarn java.lang.invoke.StringConcatFactory
