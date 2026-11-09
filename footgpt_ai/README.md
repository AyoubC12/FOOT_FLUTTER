# FootGPT AI

Full-stack football intelligence: Flutter client, Django REST API, sklearn 1X2 engine, and a separate OpenAI assistant. Provider keys stay on the server.

## Layout

```
footgpt_ai/
  lib/                 Flutter (feature-first, Clean Architecture)
  backend/             Django + DRF + PostgreSQL
  docs/                Architecture, API, database
  test/                Flutter unit + widget tests
  integration_test/    Flutter integration tests
```

## Flutter

Requirements: Flutter SDK matching `pubspec.yaml` (`sdk: ^3.13.5`).

```
flutter pub get
flutter analyze
flutter test
```

Point the app at Django with a dart-define (never a football or OpenAI key):

```
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

Features: `splash`, `onboarding`, `auth`, `dashboard`, `matches`, `predictions`, `players`, `tactics`, `chatbot`, `favorites`, `notifications`, `profile`, `settings`. Each has `domain` (and `data` / `presentation` where implemented).

## Django

```
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
```

Fill `DJANGO_SECRET_KEY`, Postgres, and optional `FOOTBALL_API_KEY` / `OPENAI_API_KEY` / `FIREBASE_CREDENTIALS_FILE` in `.env` only.

```
python manage.py migrate
python manage.py test
python manage.py runserver
```

Canonical API prefix: `/api/v1/`. Legacy `/api/` aliases remain until clients fully migrate.

## Boundaries

- API-Football and OpenAI are called only from Django.
- Predictions (`backend/predictions`) are probabilistic, not guarantees, and do not use the chatbot.
- The assistant (`backend/assistant`) must not train or overwrite the sklearn artifact.
- FCM is registered via `/api/v1/notifications/devices/`. Firebase is not a Flutter package yet (no google-services files in this repo).

See [docs/architecture.md](docs/architecture.md).
