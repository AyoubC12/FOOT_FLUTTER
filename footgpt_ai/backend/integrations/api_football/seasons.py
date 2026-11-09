from datetime import date

FIRST_YEAR = 2009
LAST_YEAR = 2026  # 2026-2027


def season_label(year: int) -> str:
    return f"{year}-{year + 1}"


def season_years() -> list[int]:
    return list(range(FIRST_YEAR, LAST_YEAR + 1))


def is_season_current(year: int, today: date | None = None) -> bool:
    today = today or date.today()
    current = today.year if today.month >= 8 else today.year - 1
    return year == current


def is_season_complete(year: int, today: date | None = None) -> bool:
    today = today or date.today()
    return year < (today.year if today.month >= 8 else today.year - 1)
