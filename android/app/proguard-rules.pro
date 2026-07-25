# Flutter ML Kit Text Recognition Proguard rules
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions

# Alcorlink Camera & SecuGen FDx SDK Proguard rules
# Keep all classes, methods, and fields as they are accessed by native C++/JNI libraries via reflection
-keep class com.alcorlink.** { *; }
-dontwarn com.alcorlink.**

-keep class SecuGen.** { *; }
-dontwarn SecuGen.**

-keep class com.secugen.** { *; }
-dontwarn com.secugen.**

