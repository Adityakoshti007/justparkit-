plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.justparkit"

    // Use explicit numeric SDK values — don't mix with flutter.* placeholders here
    compileSdk = 35

    // NDK required by firebase plugins
    ndkVersion = "27.0.12077973"

     defaultConfig {
        applicationId = "com.example.justparkit" // keep yours
        minSdk = 23
        targetSdk = 34 // you can keep/update to 35 if you like
        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    buildTypes {
        release {
            // For now use debug signing (change for production)
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.6.0"))
    implementation("com.google.firebase:firebase-analytics")
}
