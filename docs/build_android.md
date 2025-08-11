# Android build notes

Gradle looks for the Flutter SDK in two ways:

1. `FLUTTER_SDK` environment variable (also honors `FLUTTER_HOME`).
2. `android/local.properties` with a `flutter.sdk=/path/to/flutter` entry.

The repository provides `scripts/setup_flutter_localprops.sh` which detects the
SDK path and writes `android/local.properties` accordingly. Run it before
invoking Gradle on fresh machines.

Locally you can set `FLUTTER_SDK` in your shell or create `android/local.properties`
manually:

```properties
flutter.sdk=/absolute/path/to/flutter
```

This keeps Gradle stable on clean runners and ensures plugin resolution works.
