plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.flutterdemo0" // Đảm bảo namespace được khai báo
    compileSdk = flutter.compileSdkVersion

    // Đặt phiên bản NDK chính xác
    ndkVersion = "27.0.12077973"  // Sử dụng phiên bản NDK yêu cầu cho flutter_blue

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.flutterdemo0"  // ID ứng dụng Android
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
    }

    buildTypes {
        release {
            isMinifyEnabled = true  // Sửa từ minifyEnabled thành isMinifyEnabled
            isShrinkResources = true  // Sửa từ shrinkResources thành isShrinkResources
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),  // Đổi cú pháp
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."  // Đường dẫn đến thư mục Flutter
}
