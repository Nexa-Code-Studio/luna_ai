import pytest
from httpx import ASGITransport, AsyncClient

from app.db.session import engine
from app.main import app


@pytest.fixture(autouse=True)
async def dispose_engine():
    await engine.dispose()
    yield
    await engine.dispose()


@pytest.fixture
async def auth_headers():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        login_res = await client.post("/api/v1/auth/login", json={"email": "samsul@gmail.com", "password": "password123"})
        token = login_res.json()["access_token"]
        return {"Authorization": f"Bearer {token}"}


@pytest.mark.asyncio
async def test_auth_login_and_me(auth_headers):
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        login_res = await client.post("/api/v1/auth/login", json={"email": "samsul@gmail.com", "password": "password123"})
        assert login_res.status_code == 200
        data = login_res.json()
        assert "access_token" in data
        assert data["user"]["email"] == "samsul@gmail.com"

        me_res = await client.get("/api/v1/auth/me", headers=auth_headers)
        assert me_res.status_code == 200
        assert me_res.json()["email"] == "samsul@gmail.com"


@pytest.mark.asyncio
async def test_emergency_contacts_crud(auth_headers):
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        res = await client.get("/api/v1/users/emergency-contacts", headers=auth_headers)
        assert res.status_code == 200
        contacts = res.json()
        assert isinstance(contacts, list)
        assert len(contacts) >= 1

        add_res = await client.post(
            "/api/v1/users/emergency-contacts",
            json={"name": "Kakak Test", "relationship": "Saudara", "phone_number": "0812-9999-8888", "is_primary": False},
            headers=auth_headers,
        )
        assert add_res.status_code == 200
        new_contact = add_res.json()
        assert new_contact["name"] == "Kakak Test"

        del_res = await client.delete(f"/api/v1/users/emergency-contacts/{new_contact['id']}", headers=auth_headers)
        assert del_res.status_code == 200


@pytest.mark.asyncio
async def test_diaries_crud(auth_headers):
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        res = await client.get("/api/v1/diaries", headers=auth_headers)
        assert res.status_code == 200
        diaries = res.json()
        assert isinstance(diaries, list)
        assert len(diaries) >= 1

        today_res = await client.get("/api/v1/diaries/today", headers=auth_headers)
        assert today_res.status_code == 200
        today_diary = today_res.json()
        assert "title" in today_diary
        assert "summary" in today_diary
        assert "id" in today_diary

        gen_res = await client.post("/api/v1/diaries/generate", headers=auth_headers)
        assert gen_res.status_code == 200
        gen_diary = gen_res.json()
        assert "title" in gen_diary
        assert "summary" in gen_diary
        assert "importantEvents" in gen_diary
        # Verify single today's diary upsert constraint (ID must match)
        assert gen_diary["id"] == today_diary["id"]

        create_res = await client.post("/api/v1/diaries", json={"content": "Catatan tes malam hari.", "mood_tag": "Tenang"}, headers=auth_headers)
        assert create_res.status_code == 200
        new_diary = create_res.json()
        assert new_diary["moodTag"] == "Tenang"

        del_res = await client.delete(f"/api/v1/diaries/{new_diary['id']}", headers=auth_headers)
        assert del_res.status_code == 200


@pytest.mark.asyncio
async def test_analytics_monitoring(auth_headers):
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        res_today = await client.get("/api/v1/analytics/monitoring?period=today", headers=auth_headers)
        assert res_today.status_code == 200
        data_today = res_today.json()
        assert data_today["periodKey"] == "today"
        assert "emotionalCenter" in data_today

        res_week = await client.get("/api/v1/analytics/monitoring?period=week", headers=auth_headers)
        assert res_week.status_code == 200
        data_week = res_week.json()
        assert data_week["periodKey"] == "week"

        res_month = await client.get("/api/v1/analytics/monitoring?period=month", headers=auth_headers)
        assert res_month.status_code == 200
        data_month = res_month.json()
        assert data_month["periodKey"] == "month"
        assert len(data_month["xLabels"]) == 4
        assert len(data_month["chartData"]) == 4


@pytest.mark.asyncio
async def test_recommendations(auth_headers):
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        # 1. Test GET /recommendations catalog
        res = await client.get("/api/v1/recommendations", headers=auth_headers)
        assert res.status_code == 200
        recs = res.json()
        assert isinstance(recs, list)
        assert len(recs) >= 1

        # 2. Test GET /recommendations/today
        today_res = await client.get("/api/v1/recommendations/today", headers=auth_headers)
        assert today_res.status_code == 200
        today_data = today_res.json()
        assert "targetCondition" in today_data
        assert "conditionLabel" in today_data
        assert "todayActivity" in today_data
        today_act = today_data["todayActivity"]
        assert "title" in today_act
        assert "instructions" in today_act

        # 3. Mark completed
        rec_id = today_act["id"]
        comp_res = await client.post(f"/api/v1/recommendations/{rec_id}/complete", headers=auth_headers)
        assert comp_res.status_code == 200
        comp_data = comp_res.json()
        assert comp_data["isCompleted"] is True


@pytest.mark.asyncio
async def test_conversations():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        login_res = await client.post("/api/v1/auth/login", json={"email": "samsul@gmail.com", "password": "password123"})
        assert login_res.status_code == 200
        token = login_res.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        res = await client.get("/api/v1/conversations", headers=headers)
        assert res.status_code == 200
        convs_data = res.json()
        assert "items" in convs_data
        assert "pagination" in convs_data
        assert convs_data["pagination"]["page"] == 1
        assert convs_data["pagination"]["limit"] == 10
        convs = convs_data["items"]
        assert isinstance(convs, list)
        assert len(convs) >= 1
        assert "duration" in convs[0]
        assert "dominant_emotion" in convs[0]
        assert "dominant_emoji" in convs[0]
        assert "summary" in convs[0]

        conv_id = convs[0]["id"]
        msg_res = await client.post(f"/api/v1/conversations/{conv_id}/messages", json={"content": "Halo dari unit test"}, headers=headers)
        assert msg_res.status_code == 200
        msg = msg_res.json()
        assert msg["text"] == "Halo dari unit test"

        today_res = await client.get("/api/v1/conversations/today", headers=headers)
        assert today_res.status_code == 200
        today_data = today_res.json()
        assert "items" in today_data
        for item in today_data["items"]:
            assert "is_title_generating" in item
            assert isinstance(item["is_title_generating"], bool)

        today_msgs_res = await client.get("/api/v1/conversations/today/messages?page=1&limit=10", headers=headers)
        assert today_msgs_res.status_code == 200
        today_msgs_data = today_msgs_res.json()
        assert "items" in today_msgs_data
        assert "total_items" in today_msgs_data
        assert "page" in today_msgs_data
        assert today_msgs_data["limit"] == 10

        # Test summary SSE streaming endpoint
        stream_res = await client.get(f"/api/v1/conversations/{conv_id}/summary/stream", headers=headers)
        assert stream_res.status_code == 200
        assert "text/event-stream" in stream_res.headers.get("content-type", "")
        stream_content = stream_res.text
        assert "data:" in stream_content
        assert "done" in stream_content

