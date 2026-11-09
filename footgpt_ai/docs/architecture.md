# Architecture

FootGPT AI is a mobile client plus a versioned REST backend. Live scores, player stats, and chat completions are never generated in Flutter.

## System

```
Flutter (Riverpod, GoRouter, Dio)
        |  JWT Bearer
        v
Django /api/v1/  (also /api/ compatibility)
        |-- football  --> API-Football (server key)
        |-- predictions --> sklearn artifact (pandas/numpy)
        |-- assistant --> OpenAI Chat Completions (server key)
        |-- tactics, favorites, notifications, administration
        v
PostgreSQL
```

## Flutter

Organization is **feature-first**. Each feature owns:

| Layer | Role |
| --- | --- |
| `presentation` | Screens, widgets, Riverpod controllers |
| `domain` | Contracts and feature rules (no Dio, no widgets) |
| `data` | Repositories calling `ApiPaths` |

Shared UI lives in `lib/core/widgets`. Networking lives in `lib/core/network`. The only runtime backend setting in the app is `API_BASE_URL` (`String.fromEnvironment`).

Splash and onboarding are first-class modules. Auth still re-exports those screens so older imports compile. Settings lives under `features/settings`; profile re-exports the same screen.

Notifications UI is a stub until FlutterFire options exist. Adding `firebase_messaging` without those files would break analyze/test on machines without Firebase config.

## Django applications

| App | Responsibility |
| --- | --- |
| `accounts` | User, JWT, password reset, `Favorite` table |
| `football` | API-Football proxy, cached fixtures/players |
| `predictions` | Historical matches, train/estimate 1X2 |
| `assistant` | Conversations, OpenAI tools |
| `tactics` | Boards, suggest/compare |
| `favorites` | `/favorites/` ViewSet over `accounts.Favorite` |
| `notifications` | Device tokens, FCM adapter (no-op without credentials) |
| `administration` | Staff-only audit log list (`administration` avoids clashing with `django.contrib.admin`) |

JWT: SimpleJWT access 30 minutes, refresh 7 days, rotation + blacklist. Default permission is `IsAuthenticated`. Auth and password-reset endpoints are `AllowAny` with scoped throttles.

## AI split

1. **Prediction engine** — `backend/predictions`. Tabular sklearn. Missing features are explicit; no leakage from future kickoffs.
2. **Assistant** — `backend/assistant`. Natural language + read-only football tools. Must not claim live scores the proxy did not return.

Tactical “AI notes” may call OpenAI but fall back to verified formation text when the key is absent.

## Secrets

- `backend/.env` (see `.env.example`)
- Never commit keys. Never send them to Flutter, dart-defines, or `manifest.json`.
