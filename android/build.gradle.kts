allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// Force all plugin subprojects (e.g. agora_rtc_engine) to compile against SDK 36.
// Needed because agora_rtc_engine 6.5.x pins an old compileSdk internally.
// Force all plugin subprojects (e.g. agora_rtc_engine) to compile against SDK 36.
subprojects {
    fun applyCompileSdk(project: Project) {
        project.extensions.findByType(com.android.build.gradle.BaseExtension::class.java)
            ?.compileSdkVersion(36)
    }

    if (state.executed) {
        applyCompileSdk(this)
    } else {
        afterEvaluate { applyCompileSdk(this) }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}