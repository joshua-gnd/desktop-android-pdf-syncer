// 1. ADD THIS BLOCK AT THE VERY TOP OF THE FILE
// This intercepts the internal build scripts of third-party plugins before they compile
buildscript {
    repositories {
        google()
        mavenCentral()
    }
}

// Keep your existing allprojects configuration below
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Keep your existing custom directory mappings completely unchanged
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}