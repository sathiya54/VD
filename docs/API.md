# Virtual Diary — REST API v1 reference

Base URL: `http://127.0.0.1:8000/api/v1/` in development.

All authenticated endpoints require `Authorization: Bearer <access_token>`.

Error responses: `{"success": false, "message": "...", "error_code": "SOME_CODE"}`.
Paginated list responses: `{"count": N, "next": url|null, "previous": url|null, "results": [...]}`, 20 per page.

## Auth (`accounts` app)

| Method | Path | Notes |
|---|---|---|
| POST | `auth/register/` | `{username, email, password, password2}` → tokens + user |
| POST | `auth/login/` | `{username, password}` → tokens + user |
| POST | `auth/refresh/` | `{refresh}` → `{access}` |
| POST | `auth/logout/` | `{refresh}` → blacklists it, 205 |
| GET/PATCH | `auth/profile/` | user + profile fields (AI settings, theme, avatar, bio) |
| POST | `auth/password/change/` | `{old_password, new_password}` |
| POST | `auth/password/reset/` | `{email}` → always 200, emails a reset link (console backend in dev) |
| POST | `auth/password/reset/confirm/` | `{uid, token, new_password}` |
| DELETE | `auth/account/` | `{password}` → deletes the account |

## Diary (`diary` app)

| Method | Path | Notes |
|---|---|---|
| GET/POST | `entries/` | filters: `category`, `mood`, `tag`, `favorite`, `search`, `date_from`, `date_to` |
| GET/PUT/PATCH | `entries/<id>/` | |
| DELETE | `entries/<id>/` | soft delete → trash |
| POST | `entries/<id>/favorite/` | toggles favorite |
| POST | `entries/<id>/restore/` | restores from trash |
| DELETE | `entries/<id>/permanent/` | hard delete |
| GET | `entries/trash/` | paginated soft-deleted entries |
| GET/POST | `categories/` | `owner=null` categories are system defaults, shown to everyone |
| GET/POST | `tags/` | per-user |
| GET | `moods/` | 10 seeded defaults |
| GET | `prompts/today/` | today's journal prompt |

## Goals & Tasks

| Method | Path |
|---|---|
| GET/POST, GET/PUT/PATCH/DELETE | `goals/`, `goals/<id>/` |
| GET/POST | `goals/<id>/milestones/` |
| PATCH/DELETE | `milestones/<id>/` |
| GET/POST, GET/PUT/PATCH/DELETE | `tasks/`, `tasks/<id>/` |
| POST | `tasks/<id>/complete/` |

## Reminders, Events & Calendar

| Method | Path |
|---|---|
| GET/POST, PATCH/DELETE | `reminders/`, `reminders/<id>/` |
| GET/POST, PATCH/DELETE | `events/`, `events/<id>/` |
| GET | `calendar/?year=&month=` — aggregates entries, tasks, goals, reminders, events for that month |

## Memories

| Method | Path |
|---|---|
| GET/POST (multipart) | `memories/` — `{title, file, memory_type, taken_at}` |
| DELETE | `memories/<id>/` |

## Search & Analytics

| Method | Path |
|---|---|
| GET | `search/?q=&category=&mood=&tag=&favorite=&date_from=&date_to=` |
| GET | `analytics/summary/` — streaks, mood/category distribution, goals/tasks completed |
| GET | `analytics/on-this-day/` — past years' entries matching today's month/day |

## AI Assistant (optional — see `ANTHROPIC_API_KEY` in `.env`)

Gated by the user's `profile.ai_enabled` flag (off by default). Returns `503 {"error_code": "AI_NOT_CONFIGURED"}` if no API key is set on the server, and `403 {"error_code": "AI_DISABLED"}` if the user hasn't opted in.

| Method | Path | Body → Response |
|---|---|---|
| POST | `ai/title/` | `{content}` → `{title}` |
| POST | `ai/summary/` | `{content}` → `{summary}` |
| POST | `ai/tags/` | `{content}` → `{tags: [...]}` |
| POST | `ai/improve/` | `{content}` → `{improved_content}` |

## Notifications & Achievements

| Method | Path |
|---|---|
| GET | `notifications/` |
| POST | `notifications/<id>/read/` |
| GET | `achievements/` — evaluated/unlocked on read |

## Data isolation

Every list/detail endpoint scopes its queryset to `owner=request.user`; a request for another user's object id returns `404`, never `403` (so existence isn't leaked). See `backend/diary/tests.py::DiaryIsolationTests`, `backend/goals/tests.py`, `backend/tasks/tests.py` for the automated proof of this.
