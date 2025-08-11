// android/settings.gradle.kts — Flutter-aware settings for Gradle Kotlin DSL

pluginManagement {
    // 1) Репозитории — оставляем как было
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }

    // 2) Находим путь к Flutter SDK:
    //    Сначала из переменной окружения FLUTTER_SDK (подходит для CI/Codex),
    //    иначе читаем android/local.properties (локальная разработка).
    val flutterSdkPath = providers.environmentVariable("FLUTTER_SDK").orNull ?: run {
        val props = java.util.Properties()
        val f = file("local.properties")
        if (f.exists()) f.inputStream().use { props.load(it) }
        props.getProperty("flutter.sdk")
            ?: throw GradleException(
                "Flutter SDK path not set. Define FLUTTER_SDK env var or add android/local.properties with 'flutter.sdk=/path/to/flutter'"
            )
    }

    // 3) Делаем gradle-aware Flutter build logic
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")
}

dependencyResolutionManagement {
    // Оставляем твои репозитории
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "Poker_Analyzer"
include(":app")
