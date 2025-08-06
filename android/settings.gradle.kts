pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "Poker_Analyzer"
include(":app")

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
