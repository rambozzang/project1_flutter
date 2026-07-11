import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 릴리즈 서명 정보는 app/key.properties에서 로드 (Groovy 시절과 동일)
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("app/key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.codelabtiger.skysnap"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
        freeCompilerArgs += listOf(
            "-Xjvm-default=all",
            "-Xopt-in=kotlin.RequiresOptIn"
        )
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
    }

    defaultConfig {
        applicationId = "com.codelabtiger.skysnap"
        // 마이그레이션 후 flutter 기본값(21)으로 하향됐던 것을 26으로 복원(검증 범위 일치).
        minSdk = 26
        targetSdk = 35  // Android 15의 16KB 페이지 정렬 요구사항 회피
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
        ndk {
            abiFilters += listOf("armeabi-v7a", "arm64-v8a")
        }
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        getByName("debug") {
            signingConfig = signingConfigs.getByName("debug")
            packaging {
                jniLibs {
                    // Android 15 16KB page size 호환을 위해 반드시 false여야 합니다.
                    useLegacyPackaging = false
                }
            }
        }
        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = true
            signingConfig = signingConfigs.getByName("release")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            packaging {
                jniLibs {
                    // Android 15 16KB page size 호환을 위해 반드시 false여야 합니다.
                    // true면 APK에서 압축 해제되는 .so가 16KB 정렬을 만족하지 못해
                    // "ELF alignment check failed" 오류가 발생합니다.
                    useLegacyPackaging = false
                }
            }
        }
    }

    applicationVariants.all {
        resValue("string", "app_name", "SkySnap")
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7:1.9.24")
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.appcompat:appcompat:1.6.1")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation(platform("com.google.firebase:firebase-bom:33.1.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("androidx.window:window:1.2.0")
    implementation("androidx.window:window-java:1.2.0")
    implementation("com.google.android.gms:play-services-ads:22.6.0")
}
