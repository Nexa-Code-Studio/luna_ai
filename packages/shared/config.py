from pydantic_settings import BaseSettings, SettingsConfigDict


class BaseConfig(BaseSettings):
    """Base application environment configuration."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    APP_ENV: str = "development"
    LOG_LEVEL: str = "INFO"

    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/luna_ai"
    REDIS_URL: str = "redis://localhost:6379/0"
    QDRANT_URL: str = "http://localhost:6333"

    LLM_PROVIDER: str = "openai"
    LLM_API_KEY: str = ""

    STT_PROVIDER: str = "whisper"
    STT_API_KEY: str = ""

    TTS_PROVIDER: str = "elevenlabs"
    TTS_API_KEY: str = ""


settings = BaseConfig()
