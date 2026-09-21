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
        // Google Play 요구: 2026-08-31 부터 최신 안드로이드 출시 1년 이내 타겟만 업데이트 가능.
        // Android 16(API 36) 이상이어야 앱 업데이트를 계속 올릴 수 있다.
        //
        // 이전 주석에 "35 = 16KB 페이지 정렬 요구사항 회피"라고 적혀 있었으나 사실과 다르다.
        // 16KB 호환은 targetSdk 로 회피하는 것이 아니라 .so 의 ELF 정렬로 결정된다.
        // 실제로 NDK 28 + MLKit 17.3.0 강제로 전 라이브러리가 이미 16KB 이상 정렬돼 있다.
        targetSdk = 36
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

    // 개발 빌드를 **스토어 설치본과 나란히** 깔기 위한 별도 패키지.
    //
    // 폰에 깔린 스토어 빌드는 Play 재서명 키라 우리 키로 만든 빌드가 덮어쓰지
    // 못한다(INSTALL_FAILED_UPDATE_INCOMPATIBLE). 지우고 깔면 로그인·데이터가
    // 날아가므로, 패키지명을 갈라 둘을 같이 둔다.
    //
    // **기본은 꺼져 있다.** `-PdevId` 를 줄 때만 켜진다 — 스토어·CI 경로는 손대지
    // 않는다.
    //
    //     flutter build apk --profile -P devId
    //
    // ⚠️ 이 빌드에서는 **소셜 로그인이 안 된다.** 카카오 키해시·네이버·Firebase
    //    OAuth 가 전부 패키지명 단위로 등록돼 있다. 로그인 화면의
    //    `테스트 계정으로 로그인 (개발용)` 으로 들어간다(kReleaseMode 로 가려져
    //    릴리즈에는 없다).
    // ⚠️ FCM·Firebase Auth 도 기대하지 말 것. 화면을 눈으로 보려고 만든 길이다.
    //
    // 자세한 건 `src/README-dev-package.md`.
    val useDevId = project.hasProperty("devId")

    buildTypes {
        getByName("debug") {
            if (useDevId) applicationIdSuffix = ".dev"
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
        // profile 은 flutter gradle plugin 이 만든다. 성능은 profile 로만 잴 수
        // 있으므로(debug 는 JIT 라 UI 스레드가 3~10배 느리다) 여기에도 붙인다.
        findByName("profile")?.apply {
            if (useDevId) applicationIdSuffix = ".dev"
        }
    }

    applicationVariants.all {
        resValue("string", "app_name", "SkySnap")
    }
}

flutter {
    source = "../.."
}

// ── 16KB 페이지 크기 호환 ──
// mobile_scanner(^5.2.3)가 전이 의존으로 끌어오는 MLKit 바코드 17.2.0은
// libbarhopper_v3.so 가 4KB(2**12) 정렬이라 Android 15+ 16KB 페이지 기기에서 비호환.
// 16KB(2**14) 정렬이 적용된 17.3.0+ 로 강제한다. (Play는 2025-11-01부터 targetSdk 35+ 앱에 16KB 지원 의무화)
configurations.all {
    resolutionStrategy {
        force("com.google.mlkit:barcode-scanning:17.3.0")
    }
}

dependencies {
    // 영상 피드 전용 네이티브 플레이어(MomoVideo) — 자매 앱(모모앨범)에서 이식.
    //
    // video_player 플러그인이 전이 의존으로 media3 를 가져오지만, 우리 코드가
    // 직접 쓰므로 **버전을 명시**한다. 전이 의존에 기대면 플러그인이 올라갈 때
    // 조용히 같이 올라가 API 가 바뀐다.
    //
    // 왜 직접 쓰나: 플러그인은 `DefaultLoadControl` 의 **뒤 버퍼만** 열어 준다.
    // 메모리를 먹는 앞 버퍼(기본 50초·플레이어당 최대 125MB)는 손댈 수 없어
    // 모모앨범 실기기에서 자바 힙 상한 256MB 를 쳤다(2026-09-19 OOM 두 건).
    implementation("androidx.media3:media3-exoplayer:1.9.2")
    implementation("androidx.media3:media3-exoplayer-hls:1.9.2")
    implementation("androidx.media3:media3-exoplayer-dash:1.9.2")

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
