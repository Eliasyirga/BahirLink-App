allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Standard Flutter template: put Gradle outputs under <project>/build so the
// Flutter tool (and CI) find the APK at build/app/outputs/flutter-apk/.
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
