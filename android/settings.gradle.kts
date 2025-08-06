import java.io.FileInputStream
import java.util.Properties

val localProperties = Properties()
val localPropertiesFile = File(rootDir, "local.properties")
if (localPropertiesFile.exists()) {
    localProperties.load(FileInputStream(localPropertiesFile))
}
val flutterSdkPath = localProperties.getProperty("flutter.sdk")

if (flutterSdkPath != null) {
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")
}

include(":app")
