# FootGPT AI — Football endpoints

All football routes are served by the Django backend. Flutter must call **this API**, never API-Football directly. The provider key is read from `backend/.env` (`FOOTBALL_API_KEY`) and is sent only as `x-apisports-key` (or RapidAPI headers) from the server.

**Auth:** `Authorization: Bearer <access_token>`

**Base path:** `/api/football/`

**Pagination:** list endpoints return `count`, `page`, `page_size`, `num_pages`, `results`. Provider paging is echoed as `provider_paging`. Scores and stats are copied from API-Football; missing values are `null`.

Cache (in-process, to cut provider calls):

| Data | TTL |
| --- | --- |
| Live fixtures | 15s |
| Fixture lists | 5m |
| Fixture detail / match stats | 1m |
| Standings | 30m |
| Team / player statistics | 1h |
| Players | 6h |
| Teams / H2H | 12h / 6h |

Rate limits from API-Football are returned as **429** with optional `Retry-After`. A missing key returns **503**. Upstream failures return **502**.

---

## GET `/api/football/fixtures/`

Scheduled or finished fixtures. Requires at least one of: `date`, `league`+`season`, `team`, `live`, `next`, `last`, `id`.

| Query | Notes |
| --- | --- |
| `date` | `YYYY-MM-DD` |
| `league`, `season` | e.g. `39` and `2024` |
| `team` | API-Football team id |
| `status` | `NS`, `FT`, `1H`, … |
| `next`, `last` | 1–50 |
| `from_date`, `to_date` | `YYYY-MM-DD` |
| `timezone` | default `UTC` |
| `page`, `page_size` | `page_size` max 50 |

## GET `/api/football/fixtures/live/`

Live matches. Query: `live=all` (default) or hyphen-separated league ids (`39-140`), plus pagination.

## GET `/api/football/fixtures/{fixture_id}/`

One fixture plus team statistics. Stats that API-Football omitted stay `null`.

## GET `/api/football/teams/`

Filters: `id`, `search`, `country`, or `league`+`season`.

## GET `/api/football/teams/{team_id}/`

## GET `/api/football/teams/{team_id}/statistics/`

Required: `league`, `season`.

## GET `/api/football/players/`

Required: `season` plus `id`, `team`, `league`, or `search`. Uses API-Football’s own `page`.

## GET `/api/football/players/{player_id}/statistics/`

Required: `season`.

## GET `/api/football/standings/`

Required: `league`, `season`. Optional: `team`.

## GET `/api/football/head-to-head/`

Required: `home`, `away` (team ids). Optional: `last`, `league`, `season`, pagination.

Interactive docs: `/api/docs/` (Swagger) and `/api/redoc/`.

---

## Sample responses

These samples follow the **real API-Football object shape**. `goals` are `null` because the fixture status is `NS` (not started). The backend does not fill in scores.

### Live / fixture list item

```json
{
  "count": 1,
  "page": 1,
  "page_size": 20,
  "num_pages": 1,
  "provider_paging": { "current": 1, "total": 1 },
  "provider_errors": {},
  "results": [
    {
      "id": 1035606,
      "date": "2024-05-19T15:00:00+00:00",
      "status": { "long": "Not Started", "short": "NS", "elapsed": null, "extra": null },
      "league": { "id": 39, "name": "Premier League", "country": "England", "season": 2023 },
      "teams": {
        "home": { "id": 42, "name": "Arsenal", "logo": "https://media.api-sports.io/football/teams/42.png" },
        "away": { "id": 33, "name": "Manchester United", "logo": "https://media.api-sports.io/football/teams/33.png" }
      },
      "goals": { "home": null, "away": null },
      "score": {
        "halftime": { "home": null, "away": null },
        "fulltime": { "home": null, "away": null }
      }
    }
  ]
}
```

### Fixture detail statistics (missing values stay null)

```json
{
  "results": {
    "id": 1035606,
    "statistics": [
      {
        "team": { "id": 42, "name": "Arsenal" },
        "statistics": {
          "shots_on_goal": null,
          "total_shots": null,
          "ball_possession": null,
          "expected_goals": null
        }
      }
    ]
  },
  "provider_errors": {}
}
```

### Standings row

```json
{
  "results": [
    {
      "league": { "id": 39, "name": "Premier League", "season": 2024 },
      "standings": [
        [
          {
            "rank": 1,
            "team": { "id": 50, "name": "Manchester City" },
            "points": 91,
            "goals_diff": 62,
            "form": "WWWWW",
            "played": 38,
            "win": 28,
            "draw": 7,
            "lose": 3
          }
        ]
      ]
    }
  ]
}
```

Standings figures in this sample are illustrative of the **field names** API-Football returns. Live tables always come from the provider after you set `FOOTBALL_API_KEY`.
