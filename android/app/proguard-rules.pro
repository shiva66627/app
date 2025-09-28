# Keep Razorpay SDK classes (so R8 doesn’t strip them out)
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**

# Fix for missing proguard.annotation
-dontwarn proguard.annotation.**
