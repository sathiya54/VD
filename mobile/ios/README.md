# ios/ (placeholder)

This directory intentionally does not contain native iOS project files.
Flutter was not installed in the environment that hand-wrote this app's
`lib/` tree and `pubspec.yaml`, so the native scaffolding (the Xcode
project, `Info.plist`, etc.) could not be generated.

## To generate it

From the `mobile/` directory, once the Flutter SDK is installed (on macOS,
with Xcode installed):

```
flutter create --org com.virtualdiary --project-name virtual_diary .
```

This regenerates the missing `ios/` (and `android/`) folders in place
without touching the existing `lib/` or `pubspec.yaml`.

## Required configuration

- **Bundle identifier**: `com.virtualdiary.app`
  - Set in Xcode under the Runner target's Signing & Capabilities, or
    directly in `ios/Runner.xcodeproj/project.pbxproj`
    (`PRODUCT_BUNDLE_IDENTIFIER`).
- Add the following usage description keys to `ios/Runner/Info.plist`,
  required by the features in this app:
  - `NSCameraUsageDescription` - used for diary cover photos and memories
  - `NSPhotoLibraryUsageDescription` - used to pick cover photos and memories
  - `NSPhotoLibraryAddUsageDescription` - if saving exported content back to
    the photo library
- Local notifications (used for reminders) require no extra Info.plist entry
  for basic alerts, but request notification permission at runtime via
  `flutter_local_notifications`' iOS initialization.
