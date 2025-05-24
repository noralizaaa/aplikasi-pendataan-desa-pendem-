// android/app/build.gradle.kts (Module-level build.gradle.kts)

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Tambahkan plugin Google Services di sini
    id("com.google.gms.google-services")
}

android {
    namespace = "com.bpsbatu.aplikasi_pendataan_desa"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" //flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.bpsbatu.aplikasi_pendataan_desa"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23 //flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // --- START: Tambahkan bagian ini untuk mendukung arsitektur x86/x86_64 ---
        // Ini memastikan bahwa file .so yang diperlukan untuk emulator x86 disertakan dalam APK.
        ndk {
            // Sertakan semua ABI umum, termasuk x86 dan x86_64 untuk emulator.
            abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a", "x86", "x86_64"))
        }
        // --- END: Tambahkan bagian ini ---
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Import the Firebase BoM (Bill of Materials)
    implementation(platform("com.google.firebase:firebase-bom:33.14.0"))

    // TODO: Tambahkan dependensi untuk produk Firebase yang ingin Anda gunakan
    // Saat menggunakan BoM, jangan tentukan versi dalam dependensi Firebase
    implementation("com.google.firebase:firebase-analytics")

    // Contoh dependensi Firebase lainnya (hapus jika tidak diperlukan)
    // implementation("com.google.firebase:firebase-auth")
    // implementation("com.google.firebase:firebase-firestore")
    // implementation("com.google.firebase:firebase-messaging")

    // Tambahkan dependensi untuk produk Firebase lainnya yang diinginkan
    // https://firebase.google.com/docs/android/setup#available-libraries
}

flutter {
    source = "../.."
}