from shared.config import settings


async def get_system_status() -> dict[str, str]:
    """MCP tool returning minimal system status to prove FastMCP works."""
    return {
        "status": "healthy",
        "service": "FastMCP Server",
        "environment": settings.APP_ENV,
        "qdrant_url": settings.QDRANT_URL,
    }
