import pytest
from httpx import ASGITransport, AsyncClient

from app.db.session import engine
from app.main import app


@pytest.fixture(autouse=True)
async def dispose_engine():
    await engine.dispose()
    yield
    await engine.dispose()


@pytest.mark.asyncio
async def test_auth_login_and_me():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        login_res = await client.post("/api/v1/auth/login", json={"email": "samsul@gmail.com", "password": "password123"})
        assert login_res.status_code == 200
        data = login_res.json()
        assert "access_token" in data
        assert data["user"]["email"] == "samsul@gmail.com"

        me_res = await client.get("/api/v1/auth/me")
        assert me_res.status_code == 200
        assert me_res.json()["email"] == "samsul@gmail.com"


@pytest.mark.asyncio
async def test_emergency_contacts_crud():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        res = await client.get("/api/v1/users/emergency-contacts")
        assert res.status_code == 200
        contacts = res.json()
        assert isinstance(contacts, list)
        assert len(contacts) >= 1

        add_res = await client.post(
            "/api/v1/users/emergency-contacts",
            json={"name": "Kakak Test", "relationship": "Saudara", "phone_number": "0812-9999-8888", "is_primary": False},
        )
        assert add_res.status_code == 200
        new_contact = add_res.json()
        assert new_contact["name"] == "Kakak Test"

        del_res = await client.delete(f"/api/v1/users/emergency-contacts/{new_contact['id']}")
        assert del_res.status_code == 200


@pytest.mark.asyncio
async def test_diaries_crud():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        res = await client.get("/api/v1/diaries")
        assert res.status_code == 200
        diaries = res.json()
        assert isinstance(diaries, list)
        assert len(diaries) >= 1

        today_res = await client.get("/api/v1/diaries/today")
        assert today_res.status_code == 200
        today_diary = today_res.json()
        assert "title" in today_diary
        assert "summary" in today_diary
        assert "id" in today_diary

        gen_res = await client.post("/api/v1/diaries/generate")
        assert gen_res.status_code == 200
        gen_diary = gen_res.json()
        assert "title" in gen_diary
        assert "summary" in gen_diary
        assert "importantEvents" in gen_diary
        # Verify single today's diary upsert constraint (ID must match)
        assert gen_diary["id"] == today_diary["id"]

        create_res = await client.post("/api/v1/diaries", json={"content": "Catatan tes malam hari.", "mood_tag": "Tenang"})
        assert create_res.status_code == 200
        new_diary = create_res.json()
        assert new_diary["moodTag"] == "Tenang"

        del_res = await client.delete(f"/api/v1/diaries/{new_diary['id']}")
        assert del_res.status_code == 200


@pytest.mark.asyncio
async def test_analytics_monitoring():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        res_today = await client.get("/api/v1/analytics/monitoring?period=today")
        assert res_today.status_code == 200
        data_today = res_today.json()
        assert data_today["periodKey"] == "today"
        assert "emotionalCenter" in data_today

        res_week = await client.get("/api/v1/analytics/monitoring?period=week")
        assert res_week.status_code == 200
        data_week = res_week.json()
        assert data_week["periodKey"] == "week"


@pytest.mark.asyncio
async def test_recommendations():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        res = await client.get("/api/v1/recommendations")
        assert res.status_code == 200
        recs = res.json()
        assert isinstance(recs, list)
        assert len(recs) >= 1

        rec_id = recs[0]["id"]
        comp_res = await client.post(f"/api/v1/recommendations/{rec_id}/complete")
        assert comp_res.status_code == 200


@pytest.mark.asyncio
async def test_conversations():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        res = await client.get("/api/v1/conversations")
        assert res.status_code == 200
        convs = res.json()
        assert isinstance(convs, list)
        assert len(convs) >= 1

        conv_id = convs[0]["id"]
        msg_res = await client.post(f"/api/v1/conversations/{conv_id}/messages", json={"content": "Halo dari unit test"})
        assert msg_res.status_code == 200
        msg = msg_res.json()
        assert msg["text"] == "Halo dari unit test"

        today_res = await client.get("/api/v1/conversations/today")
        assert today_res.status_code == 200
        today_data = today_res.json()
        assert "items" in today_data
        for item in today_data["items"]:
            assert "is_title_generating" in item
            assert isinstance(item["is_title_generating"], bool)

        today_msgs_res = await client.get("/api/v1/conversations/today/messages?page=1&limit=10")
        assert today_msgs_res.status_code == 200
        today_msgs_data = today_msgs_res.json()
        assert "items" in today_msgs_data
        assert "total_items" in today_msgs_data
        assert "page" in today_msgs_data
        assert today_msgs_data["limit"] == 10
