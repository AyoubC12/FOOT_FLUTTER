# REST API (`/api/v1/`)

All routes below are also available without `v1` (`/api/...`) for current Dio clients that still used the unversioned prefix.

Authentication: `Authorization: Bearer <access>`.

| Method | Path | Auth | Notes |
| --- | --- | --- | --- |
| POST | `/api/v1/auth/register/` | public | Returns user + JWT |
| POST | `/api/v1/auth/login/` | public | Email + password |
| POST | `/api/v1/auth/logout/` | JWT | Blacklists refresh |
| POST | `/api/v1/auth/token/refresh/` | public | Rotating refresh |
| GET/PATCH | `/api/v1/auth/profile/` | JWT | |
| POST | `/api/v1/auth/password-reset/` | public | |
| GET/POST | `/api/v1/auth/favorites/` | JWT | Legacy nested favorites |
| GET/POST | `/api/v1/favorites/` | JWT | Canonical favorites |
| GET | `/api/v1/football/fixtures/live/` | JWT | Provider proxy |
| GET | `/api/v1/football/fixtures/` | JWT | |
| GET | `/api/v1/football/fixtures/{id}/` | JWT | |
| GET | `/api/v1/football/competitions/` | JWT | Seeded catalog |
| GET | `/api/v1/football/competitions/{id}/seasons/` | JWT | 2009–2027 labels |
| GET | `/api/v1/football/catalog/teams/` | JWT | Local stored clubs |
| GET | `/api/v1/football/teams/` | JWT | Provider proxy; persists clubs |
| GET | `/api/v1/football/teams/{id}/seasons/` | JWT | Stored historical rows |
| GET | `/api/v1/football/players/` | JWT | |
| GET | `/api/v1/football/players/{id}/statistics/` | JWT | |
| GET | `/api/v1/football/players/compare/` | JWT | |
| GET/POST | `/api/v1/football/players/comparisons/` | JWT | Saved comparisons |
| GET | `/api/v1/football/standings/` | JWT | |
| GET | `/api/v1/football/head-to-head/` | JWT | |
| GET/POST | `/api/v1/predictions/` | JWT | Stored estimates |
| POST | `/api/v1/predictions/estimate/` | JWT | sklearn 1X2 |
| POST | `/api/v1/assistant/chat/` | JWT | OpenAI on server |
| GET | `/api/v1/assistant/messages/` | JWT | |
| GET | `/api/v1/assistant/suggestions/` | JWT | |
| GET/POST | `/api/v1/tactics/boards/` | JWT | |
| POST | `/api/v1/tactics/suggest/` | JWT | |
| POST | `/api/v1/tactics/compare/` | JWT | |
| GET/POST | `/api/v1/notifications/devices/` | JWT | FCM token register |
| GET | `/api/v1/administration/audit-logs/` | staff | |

DEBUG only: `/api/schema/`, `/api/docs/`, `/api/redoc/`.

When `FOOTBALL_API_KEY` is empty, football proxy endpoints return **503** rather than invented fixtures.
