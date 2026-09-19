import pytest
from httpx import ASGITransport, AsyncClient

from app.db.session import engine
from app.main import app
from app.services.dass_service import DASSService


@pytest.fixture(autouse=True)
async def dispose_engine():
    await engine.dispose()
    yield
    await engine.dispose()


def test_dass_scoring_calculation():
    """Unit test kalkulasi skor DASS-21 deterministik."""
    items = DASSService.generate_default_items()
    assert len(items) == 21

    # Atur skor untuk depresi (item 3, 5, 10, 13, 16, 17, 21): total 7 * 2 = 14 -> dikali 2 = 28 -> Extremely Severe
    for it in items:
        if it["scale"] == "depression":
            it["score"] = 2  # raw sum = 7 * 2 = 14, dikali 2 = 28
        elif it["scale"] == "anxiety":
            it["score"] = 1  # raw sum = 7 * 1 = 7, dikali 2 = 14 -> Moderate
        elif it["scale"] == "stress":
            it["score"] = 1  # raw sum = 7 * 1 = 7, dikali 2 = 14 -> Normal

    scores = DASSService.calculate_scores(items)
    assert scores["depression_score"] == 28
    assert scores["depression_severity"] == "Extremely Severe"
    assert scores["anxiety_score"] == 14
    assert scores["anxiety_severity"] == "Moderate"
    assert scores["stress_score"] == 14
    assert scores["stress_severity"] == "Normal"


@pytest.mark.asyncio
async def test_get_today_dass_endpoint():
    """Memastikan endpoint GET /api/v1/dass/today mengembalikan 21 butir resmi."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        res = await client.get("/api/v1/dass/today")
        assert res.status_code == 200
        data = res.json()
        assert "items" in data
        assert len(data["items"]) == 21
        assert "depression_score" in data
        assert "anxiety_score" in data
        assert "stress_score" in data
        assert data["items"][0]["item_id"] == 1


@pytest.mark.asyncio
async def test_update_today_dass_endpoint():
    """Memastikan user dapat mengedit butir DASS-21 dan sistem mere-kalkulasi skor subskala."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        # Update butir 1 (stress) ke skor 3, dan butir 3 (depression) ke skor 2
        update_payload = {
            "items": [
                {"item_id": 1, "score": 3},
                {"item_id": 3, "score": 2},
            ]
        }
        put_res = await client.put("/api/v1/dass/today", json=update_payload)
        assert put_res.status_code == 200
        updated_data = put_res.json()

        assert updated_data["verified_by_user"] is True
        assert updated_data["status"] == "verified"
        # Item 1 stress score = 3 * 2 = 6
        assert updated_data["stress_score"] >= 6
        # Item 3 depression score = 2 * 2 = 4
        assert updated_data["depression_score"] >= 4

        # Periksa bahwa item 1 berstatus is_user_edited = True
        item_1 = next(it for it in updated_data["items"] if it["item_id"] == 1)
        assert item_1["score"] == 3
        assert item_1["is_user_edited"] is True
