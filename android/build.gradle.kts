buildscript {
    repositories {
        google()  // Make sure this is present
        mavenCentral()
    }
    dependencies {
        // Add this line for Google Services plugin
        classpath("com.google.gms:google-services:4.3.15")
    }
}

allprojects {
    repositories {
        google()  // Make sure this is present
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
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


