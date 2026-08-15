from pydantic import BaseModel


class HealthCheckResponse(BaseModel):
    status: str
    app: str
    environment: str
    database: str
    redis: str
    qdrant: str
