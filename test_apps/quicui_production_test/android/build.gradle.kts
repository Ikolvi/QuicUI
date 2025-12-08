allprojects {
    repositories {
        // QuicUI engine artifacts (isolated from system Maven)
        val quicuiMaven = file(System.getProperty("user.home") + "/.quicui/maven")
        if (quicuiMaven.exists()) {
            maven {
                url = quicuiMaven.toURI()
                name = "quicuiLocal"
            }
        }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
