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

// Workaround: irondash_engine_context 0.5.5 was compiled against android-31 but
// transitively requires androidx.fragment:1.7.1 which has minCompileSdk=34.
// AGP 8 checkAarMetadata blocks the build. Override compileSdk for all library
// subprojects so the check passes.
// Tracked: https://github.com/brewkits/hyper_render/issues/5
subprojects {
    val project = this
    if (project.state.executed) {
        project.extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)?.apply {
            compileSdk = 35
        }
    } else {
        project.afterEvaluate {
            project.extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)?.apply {
                compileSdk = 35
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
