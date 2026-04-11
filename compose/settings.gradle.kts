pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

@Suppress("UnstableApiUsage")
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_PROJECT)
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://maven.google.com") }
        maven { url = uri("https://jetbrains.org/kotlinx") }
    }
}

rootProject.name = "ChannelExampleApp"
include(":app")
include(":BBChannelCompose")
project(":BBChannelCompose").projectDir = file("../BBChannelCompose")

// Include the BB native player Compose SDK from local checkout
include(":bbnativeplayersdk-compose")
project(":bbnativeplayersdk-compose").projectDir = file("../bbnativeplayersdk-kotlin/bbnativeplayersdk-compose")
include(":bbnativeplayersdk-kotlin")
project(":bbnativeplayersdk-kotlin").projectDir = file("../bbnativeplayersdk-kotlin/bbnativeplayersdk-kotlin")
include(":bbnativeshared")
project(":bbnativeshared").projectDir = file("../bbnativeplayersdk-kotlin/bbnativeshared")
