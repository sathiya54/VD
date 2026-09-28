# 📔 Virtual Diary

AI-powered personal journal, memory, productivity and life-management
platform — one account, three surfaces: web, Android and iOS, all backed by
a single Django REST API.

```
Flutter (Android / iOS)  ─┐
                           ├─ HTTPS → /api/v1/ (JWT) ─→ Django REST Framework ─→ MySQL*
Bootstrap web app (Django templates, session auth) ─────┘
```
\* MySQL-ready, currently running on SQLite locally — see `backend/README.md`.

## Repository layout

```
VD/
├── backend/     Django project: REST API v1, web app, admin, all business logic
├── web/         Templates + static assets rendered by backend/webapp (Bootstrap 5, Quill.js)
├── mobile/      Flutter app (Android + iOS), talks only to /api/v1/
├── docs/        API.md — full endpoint reference
└── README.md    this file
```

## Quick start — backend + web

```bash
cd backend
python -m venv venv && venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver
```

Then open `http://127.0.0.1:8000/` (web app) or `http://127.0.0.1:8000/admin/`.
Full details, including how to switch from SQLite to MySQL, are in
[`backend/README.md`](backend/README.md).

## Quick start — mobile

```bash
cd mobile
flutter create .        # generates android/ + ios/ native scaffolding (first time only)
flutter pub get
flutter run
```

See [`mobile/README.md`](mobile/README.md) for pointing the app at your
backend URL (emulator vs. real device vs. production).

## API reference

[`docs/API.md`](docs/API.md) — every endpoint, request/response shape, and
the error-code convention used across the project.

## What's built

- **Backend**: custom user model, JWT auth (register/login/refresh/logout,
  password change + reset, account deletion), diary (entries, categories,
  tags, moods, trash/restore, favorites, journal prompts, writing streaks),
  goals + milestones, tasks, reminders, events + aggregated calendar,
  memories (validated file uploads), search, analytics (mood/category
  distribution, on-this-day), achievements (auto-evaluated), notifications,
  an optional Anthropic-backed AI assistant (title/summary/tags/improve —
  off unless a server key **and** the user's own AI setting are both on),
  a security audit log, Django admin for every model, and automated tests
  proving one account can never read, edit or delete another's data.
- **Web app**: Bootstrap 5 + Quill.js — register/login/logout, password
  reset, dashboard (streak, entries, today's prompt, tasks, upcoming),
  diary CRUD with rich text + trash/restore, goals, tasks, profile/settings.
- **Mobile app**: Flutter project (Material 3, bottom nav, secure token
  storage, offline-draft autosave) covering the same feature set against
  the identical API — see `mobile/README.md` for its own notes and caveats.

## Status & what's next

This was built end-to-end in one pass, so a few things from the full 86-section
spec are intentionally deferred rather than faked:

- **MySQL**: the backend is fully MySQL-ready (`DB_ENGINE=mysql` in `.env`)
  but runs on SQLite here because no MySQL server was available on this
  machine. Point it at a real MySQL 8.x instance whenever you have one.
- **Flutter SDK**: not installed on this machine, so the mobile app's Dart
  source was hand-written and could not be run through `flutter analyze` /
  `flutter run` here. Treat it as a strong first draft — run `flutter pub
  get` and fix whatever the compiler flags before shipping it.
- **AI assistant**: wired up against the Anthropic API but needs your own
  `ANTHROPIC_API_KEY` in `backend/.env` to actually respond.
- **App Store / Play Store release** (signing keys, store listings,
  screenshots, compliance review): needs real developer accounts and
  credentials only you can provide — not something to fabricate.
- **Offline sync, semantic AI search, family sharing, monetization**: left
  as the "future" items the original spec also marks as future work; the
  data model (`created_at`/`updated_at`/`deleted_at`/`version` on synced
  models) is already shaped to support a sync engine later.

## Testing

```bash
cd backend && python manage.py test
```
