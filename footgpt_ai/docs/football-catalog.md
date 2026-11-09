# Real football catalog

Provider: API-Football via Django only. Flutter never receives `FOOTBALL_API_KEY`.

## Coverage

Season labels are `YYYY-(YYYY+1)` from **2009-2010** to **2026-2027**. A season is **not** marked complete while it is the current campaign (August–July).

Default competitions (API-Football league ids): 39, 140, 78, 135, 61, 2, 3, 848, 200, 307, 88, 94. Extra competitions are extra `Competition` rows.

Historical depth depends on the API-Football plan. `GET /competitions/{id}/seasons/` reports `availability: not_synced` until a sync or live fetch stores coverage. Missing stats stay `null` and are listed in `missing_fields`.

## Sync (quota-aware)

```
python manage.py seed_competitions
python manage.py sync_football_catalog --league 39 --season 2024 --standings --team-stats
```

`--media` downloads crests to `media/football/teams/{external_id}.jpg` (Pillow JPEG, no resize distortion).

## Endpoints

See `docs/api.md`. Live proxy routes still work. Catalog extras:

- `GET /api/v1/football/competitions/`
- `GET /api/v1/football/competitions/{id}/seasons/`
- `GET /api/v1/football/catalog/teams/`
- `GET /api/v1/football/teams/{id}/seasons/`
- `GET /api/v1/football/teams/{id}/squad/`
- `GET /api/v1/football/players/{id}/`
- `GET /api/v1/football/players/{id}/seasons/`
- `GET /api/v1/football/players/{id}/transfers/`
- `GET /api/v1/football/teams/compare/?left=&right=&season=`
