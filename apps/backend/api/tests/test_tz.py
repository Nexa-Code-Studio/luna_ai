from datetime import date, datetime, timezone
import pytest
from app.core.tz import WIB, get_wib_day_range_utc, get_wib_now, get_wib_today, to_wib


def test_wib_timezone_properties():
    now_wib = get_wib_now()
    assert now_wib.tzinfo == WIB
    # WIB offset is +07:00 (25200 seconds)
    assert now_wib.utcoffset().total_seconds() == 7 * 3600


def test_get_wib_today():
    today = get_wib_today()
    assert isinstance(today, date)
    assert today == get_wib_now().date()


def test_to_wib_conversion():
    # Test naive UTC datetime
    naive_utc = datetime(2026, 9, 1, 0, 0, 0)
    wib_dt = to_wib(naive_utc)
    assert wib_dt is not None
    assert wib_dt.hour == 7
    assert wib_dt.day == 1
    assert wib_dt.tzinfo == WIB

    # Test aware UTC datetime
    aware_utc = datetime(2026, 8, 31, 20, 0, 0, tzinfo=timezone.utc)
    wib_dt2 = to_wib(aware_utc)
    assert wib_dt2 is not None
    assert wib_dt2.day == 1
    assert wib_dt2.month == 9
    assert wib_dt2.hour == 3


def test_get_wib_day_range_utc():
    target_date = date(2026, 9, 1)
    start_utc, end_utc = get_wib_day_range_utc(target_date)

    # 2026-09-01 00:00:00 WIB is 2026-08-31 17:00:00 UTC
    assert start_utc.year == 2026
    assert start_utc.month == 8
    assert start_utc.day == 31
    assert start_utc.hour == 17
    assert start_utc.minute == 0
    assert start_utc.second == 0

    # 2026-09-01 23:59:59.999999 WIB is 2026-09-01 16:59:59.999999 UTC
    assert end_utc.year == 2026
    assert end_utc.month == 9
    assert end_utc.day == 1
    assert end_utc.hour == 16
    assert end_utc.minute == 59
