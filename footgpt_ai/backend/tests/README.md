# Backend tests

App tests live next to the code:

- `accounts/tests.py`
- `football/tests.py`
- `predictions/` (engine tests)
- `assistant/tests.py`
- `tactics/tests.py`
- `favorites/tests.py`
- `notifications/tests.py`
- `administration/tests.py`

Run from `backend/`:

```
.venv\Scripts\python.exe manage.py test
```

SQLite is used when `test` is on the argv. PostgreSQL is for local/prod data.
