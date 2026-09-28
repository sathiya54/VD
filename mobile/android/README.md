# android/ (placeholder)

This directory intentionally does not contain native Android project files.
Flutter was not installed in the environment that hand-wrote this app's
`lib/` tree and `pubspec.yaml`, so the native scaffolding (Gradle files,
`AndroidManifest.xml`, etc.) could not be generated.

## To generate it

From the `mobile/` directory, once the Flutter SDK is installed:

```
flutter create --org com.virtualdiary --project-name virtual_diary .
```

This regenerates the missing `android/` (and `ios/`) folders in place
without touching the existing `lib/` or `pubspec.yaml`.

## Required configuration

- **Application ID**: `com.virtualdiary.app`
  - Set in `android/app/build.gradle` as `applicationId "com.virtualdiary.app"`.
- Add the following permissions to `android/app/src/main/AndroidManifest.xml`
  as needed by the features in this app (camera/gallery for cover photos and
  memories, notifications for local reminders, internet for API access):
  - `android.permission.INTERNET`
  - `android.permission.CAMERA`
  - `android.permission.READ_MEDIA_IMAGES` / `READ_EXTERNAL_STORAGE` (per target SDK)
  - `android.permission.POST_NOTIFICATIONS` (Android 13+)
- If targeting the Android emulator against a locally-run backend, no extra
  network security config should be required for `http://10.0.2.2:8000/`
  during development, but production builds should only ever call HTTPS
  endpoints (see `lib/core/constants.dart`).
