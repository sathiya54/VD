# Virtual Diary - Mobile App (Flutter)

This is the Flutter mobile client for Virtual Diary, an AI-powered personal
journal and life-management app. It talks to the Django REST Framework
backend in `../backend/` over the fixed `api/v1/` contract.

## About this scaffolding

The Flutter SDK was **not installed** in the environment that authored this
project, so nothing here was generated with `flutter create`, and nothing
was verified with `flutter pub get` / `flutter analyze` / `flutter build`.
Instead, `pubspec.yaml` and the entire `lib/` tree were written by hand
against well-known, stable package APIs. The `android/` and `ios/` folders
contain only short README placeholders explaining what to generate.

**You must run `flutter create .` once, locally, before this project will
build**, to fill in the native Android/iOS scaffolding around the existing
`lib/` and `pubspec.yaml`.

## Getting started

1. **Install the Flutter SDK** (stable channel):
   https://docs.flutter.dev/get-started/install
   Verify with:
   ```
   flutter doctor
   ```

2. **Generate native scaffolding** (run once, from this `mobile/` directory):
   ```
   flutter create --org com.virtualdiary --project-name virtual_diary .
   ```
   This fills in `android/` and `ios/` without touching the hand-written
   `lib/` or `pubspec.yaml`. Then set the application id / bundle id to
   `com.virtualdiary.app` as described in `android/README.md` and
   `ios/README.md` (this step is manual since `flutter create` derives ids
   from `--org`/`--project-name`, which should already produce this id, but
   double check the generated files).

3. **Install dependencies**:
   ```
   flutter pub get
   ```

4. **Point the app at your backend** — edit `lib/core/constants.dart`:
   - **Android emulator** (backend running on your dev machine):
     `http://10.0.2.2:8000/api/v1/` (already the default). `10.0.2.2` is the
     emulator's alias for the host machine's `localhost`.
   - **iOS simulator**: use `http://localhost:8000/api/v1/` instead, since
     the iOS simulator shares the host's network namespace.
   - **Physical device** (Android or iOS) on the same Wi-Fi as your dev
     machine: use your machine's LAN IP, e.g. `http://192.168.1.23:8000/api/v1/`.
     Make sure the Django dev server is run with `python manage.py runserver 0.0.0.0:8000`
     so it accepts connections from other devices.
   - **Production**: set `prodBaseUrl` to your real HTTPS API domain, e.g.
     `https://api.yourdomain.com/api/v1/`, and switch
     `ApiConfig.environment` to `ApiEnvironment.prod` for release builds (or
     wire this to `--dart-define` flavors for a more robust setup).

5. **Run the app**:
   ```
   flutter run
   ```

## Project structure

```
lib/
  main.dart              # entrypoint, MultiProvider + MaterialApp (Material 3, light/dark/system)
  core/                  # API client, secure token storage, theme, constants, Result/ApiException
  models/                # Plain Dart data classes matching the backend contract
  services/              # One service per REST resource, wraps Dio calls, returns Result<T>
  providers/             # ChangeNotifier state holders consumed by screens via `provider`
  navigation/            # AppRoot (splash -> auth -> shell) and MainShell (bottom nav + drawer)
  screens/               # One folder per feature area (auth, home, diary, calendar, goals, ...)
  widgets/                # Shared reusable UI pieces (buttons, cards, empty/error/loading states, ...)
```

## Notes on implementation choices

- **Tokens** are stored exclusively via `flutter_secure_storage`
  (`lib/core/secure_storage.dart`) — never in `SharedPreferences`.
  `SharedPreferences` is used only for non-secret local state: the diary
  draft autosave blob and the light/dark/system theme preference.
- **`ApiClient`** (`lib/core/api_client.dart`) attaches the bearer token to
  every request, and on a 401 attempts a single refresh-and-retry before
  forcing a logout if the refresh also fails.
- **Diary editor autosave**: while composing a *new* entry, the title/content
  are debounce-saved to local storage. Opening the editor for a new entry
  checks for a leftover draft and offers to restore or discard it.
- **Pagination**: the diary list and memories grid use infinite scroll
  against the DRF `{count, next, previous, results}` pagination shape rather
  than fetching everything at once.
- **AI features** are gated behind the user's `ai_enabled` profile flag; if
  the backend still responds with a `503`/`AI_NOT_CONFIGURED` error, the UI
  shows a friendly inline message instead of crashing.
- The diary content field is a plain multiline `TextField` for now (see the
  comment in `lib/screens/diary/diary_editor_screen.dart`) — swapping in a
  rich text package such as `flutter_quill` later shouldn't require changing
  the surrounding form/autosave logic.

## Known deviations from a "final" build

- `android/` and `ios/` are placeholders only (see above) — this is expected
  and documented, not an oversight.
- The forgot-password screen calls `auth/password/reset/`, which the
  backend does implement (always returns 200 and emails a reset link if the
  address is registered); it still fails gracefully with a friendly message
  if a given backend deployment doesn't expose it.
- `flutter_local_notifications` is initialized and can show immediate local
  notifications; wiring exact-time background scheduling for reminders would
  additionally require the `timezone` package and per-platform setup, which
  is called out as a follow-up in `lib/core/local_notifications.dart`.
