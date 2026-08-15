import pytest
from app.tools.status import get_system_status


@pytest.mark.asyncio
async def test_get_system_status():
    result = await get_system_status()
    assert result["status"] == "healthy"
    assert result["service"] == "FastMCP Server"
