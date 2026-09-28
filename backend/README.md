# Virtual Diary — Backend (Django)

Django 5 + Django REST Framework backend for Virtual Diary. Serves both the
server-rendered Bootstrap web app (session auth) and the JSON REST API at
`/api/v1/` (JWT auth) that the Flutter mobile app consumes.

## Requirements

- Python 3.12+ (developed against 3.14)
- MySQL 8.x for production-shaped local dev (optional — see below)

## Setup

```bash
cd backend
python -m venv venv
venv\Scripts\activate          # Windows
pip install -r requirements.txt
copy .env.example .env         # then edit values as needed
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver
```

Visit `http://127.0.0.1:8000/` for the web app, `http://127.0.0.1:8000/admin/`
for the Django admin, and `http://127.0.0.1:8000/api/v1/` for the API root.

## Database: SQLite by default, MySQL when you're ready

This machine didn't have a MySQL server available while scaffolding, so
`DB_ENGINE` in `.env` is left blank and the project falls back to SQLite —
everything above works out of the box with zero extra setup.

To switch to MySQL (the project's target database per the spec):

1. Install MySQL 8.x and create a database: `CREATE DATABASE virtual_diary CHARACTER SET utf8mb4;`
2. In `.env`, set `DB_ENGINE=mysql` and fill in `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_HOST`, `DB_PORT`.
3. Run `python manage.py migrate` again against the new database.

The project uses `PyMySQL` (pure Python) rather than `mysqlclient`, so no C
compiler or MySQL client headers are needed on Windows.

## Running tests

```bash
python manage.py test
```

Covers auth (register/login/refresh/password change/reset/account deletion)
and — most importantly — that one user can never read, edit, or delete
another user's diary entries, goals, or tasks (`*/tests.py::*Isolation*`).

## AI assistant (optional)

Leave `ANTHROPIC_API_KEY` blank in `.env` to keep AI features off — the
`/api/v1/ai/*` endpoints will respond with a clean `503 AI_NOT_CONFIGURED`
instead of erroring. Set the key and a user must also enable AI in their
profile settings before AI endpoints will run for them.

## Project layout

```
backend/
  config/           settings, root urls, wsgi/asgi
  api/v1/           versioned API url aggregator (imports each app's urls.py)
  common/           abstract SyncModel (created_at/updated_at/deleted_at/version), AuditLog
  accounts/         custom User, Profile, JWT auth endpoints
  diary/            entries, categories, tags, moods, journal prompts
  goals/, tasks/, reminders/, events/, memories/, notifications/, achievements/
  analytics/        computed-on-the-fly summary + on-this-day endpoints
  search/           cross-field diary search endpoint
  ai_assistant/      optional Anthropic-backed AI endpoints
  webapp/           server-rendered Bootstrap web app (session auth)
```

Templates and static assets for the web app live at the repo root in
`../web/templates/` and `../web/static/` (a sibling of `backend/`, per the
project layout), not inside `backend/`.

## Switching to a separate frontend later

CORS is enabled (`CORS_ALLOW_ALL_ORIGINS=True` in dev) so the API can also be
called from a separately-hosted web frontend if the Bootstrap templates are
ever replaced — no backend changes required beyond tightening
`CORS_ALLOWED_ORIGINS` for production.

## What's deliberately not done here

- MySQL isn't actually running against this backend yet (see above) — the
  code is ready, it just needs a real server.
- No production deployment (nginx/gunicorn/hosting) is configured — see the
  root `README.md` "Status & what's next" section.
