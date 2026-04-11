buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Match the player SDK's Kotlin and AGP versions
        classpath("com.android.tools.build:gradle:8.7.3")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.3.10")
        classpath("org.jetbrains.kotlin:kotlin-serialization:2.3.10")
        classpath("org.jetbrains.kotlin:compose-compiler-gradle-plugin:2.3.10")
        // Required by bbnativeshared
        classpath("com.squareup.sqldelight:gradle-plugin:1.4.4")
        // Required by bbnativeplayersdk-compose
        classpath("com.vanniktech:gradle-maven-publish-plugin:0.33.0")
        classpath("org.jetbrains.dokka:dokka-gradle-plugin:1.9.20")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://maven.google.com") }
        maven { url = uri("https://jetbrains.org/kotlinx") }
    }
    // Ext properties required by bbnativeplayersdk submodules
    ext["kotlin_version"] = "2.3.10"
    ext["sqlDelightVersion"] = "1.4.4"
    ext["ktorVersion"] = "3.1.3"
    ext["ktorVersionRange"] = "[2.0, 3.5)"
    ext["coroutinesVersion"] = "1.10.2"
    ext["coroutinesVersionRange"] = "[1.9.0, 1.11.0)"
}

// Force Kotlin stdlib version across all modules to match the compiler
subprojects {
    configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "org.jetbrains.kotlin") {
                useVersion("2.3.10")
            }
        }
    }
}
