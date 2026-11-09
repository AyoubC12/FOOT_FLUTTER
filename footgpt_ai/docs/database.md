# PostgreSQL model

Django is the source of schema. Tests use SQLite; runtime uses Postgres from `.env`.

## Core relations

- `accounts.User` — email unique, `USERNAME_FIELD = email`
- `accounts.Favorite` — `(user, item_type, item_external_id)` unique. Not moved to `favorites` to avoid a data migration of existing rows.
- `football.Team` / `Player` / `Match` — `external_id` unique (API-Football ids)
- `football.Match` — FKs to home/away teams; indexes on `(status, kickoff_at)` and `league_name`
- `football.SavedPlayerComparison` — per-user pair + season
- `predictions.HistoricalMatch` — finished results only; indexes on team + kickoff
- `predictions.Prediction` / `ModelEvaluation` — stored probabilities and training metrics
- `assistant.Conversation` / `ChatMessage`
- `tactics.TacticalBoard` — JSON players
- `notifications.DeviceToken` — unique FCM token; index `(user, is_active)`
- `notifications.NotificationLog` — outbound attempts (no secrets in payload)
- `administration.AuditLog` — indexes on action/time and resource

## Constraints

- Cascade user-owned rows (favorites, tokens, boards, chats).
- `SET_NULL` on player.team and audit actor when the related row is removed.
- Scores and live status on `football.Match` are nullable until the provider returns them.

Apply: `python manage.py migrate`
