from datetime import date, datetime, time, timezone
from zoneinfo import ZoneInfo

# Waktu Indonesia Barat (WIB) is UTC+7
WIB = ZoneInfo("Asia/Jakarta")


def get_wib_now() -> datetime:
    """Get current datetime localized to WIB (Asia/Jakarta)."""
    return datetime.now(WIB)


def get_wib_today() -> date:
    """Get current date in WIB (Asia/Jakarta)."""
    return datetime.now(WIB).date()


def to_wib(dt: datetime | None) -> datetime | None:
    """Convert a UTC or naive datetime to WIB datetime."""
    if dt is None:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(WIB)


def get_wib_day_range_utc(target_date: date | None = None) -> tuple[datetime, datetime]:
    """
    Get the start and end of a WIB day converted to UTC datetimes.
    Useful for querying PostgreSQL `DateTime(timezone=True)` columns for a specific WIB date.
    """
    if target_date is None:
        target_date = get_wib_today()
    start_wib = datetime.combine(target_date, time.min, tzinfo=WIB)
    end_wib = datetime.combine(target_date, time.max, tzinfo=WIB)
    return start_wib.astimezone(timezone.utc), end_wib.astimezone(timezone.utc)
