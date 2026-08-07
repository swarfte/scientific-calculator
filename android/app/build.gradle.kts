import java.io.FileInputStream
import java.util.Properties
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use {
        keystoreProperties.load(it)
    }
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.swarfte.scientific_calculator"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.swarfte.scientific_calculator"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (!keystorePropertiesFile.isFile) {
                throw GradleException(
                    "找不到 android/key.properties，不能建立 signed release APK。"
                )
            }

            keyAlias =
                keystoreProperties.getProperty("keyAlias")
                    ?: throw GradleException(
                        "android/key.properties 缺少 keyAlias"
                    )

            keyPassword =
                keystoreProperties.getProperty("keyPassword")
                    ?: throw GradleException(
                        "android/key.properties 缺少 keyPassword"
                    )

            storePassword =
                keystoreProperties.getProperty("storePassword")
                    ?: throw GradleException(
                        "android/key.properties 缺少 storePassword"
                    )

            val storeFilePath =
                keystoreProperties.getProperty("storeFile")
                    ?: throw GradleException(
                        "android/key.properties 缺少 storeFile"
                    )

            /*
             * key.properties 位於 android/，而 storeFile 的路徑
             * 亦以 Android root project，即 android/ 為基準。
             */
            val resolvedStoreFile =
                rootProject.file(storeFilePath)

            if (!resolvedStoreFile.isFile) {
                throw GradleException(
                    "找不到 Android release keystore：" +
                        resolvedStoreFile.absolutePath
                )
            }

            storeFile = resolvedStoreFile
        }
    }

    buildTypes {
        release {
            signingConfig =
                signingConfigs.getByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}