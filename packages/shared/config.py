from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

ROOT_DIR = Path(__file__).resolve().parents[2]


class BaseConfig(BaseSettings):
    """Base application environment configuration."""

    model_config = SettingsConfigDict(
        env_file=(str(ROOT_DIR / ".env"), ".env"),
        env_file_encoding="utf-8",
        extra="ignore",
    )

    APP_ENV: str = "development"
    LOG_LEVEL: str = "INFO"

    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/luna_ai"
    REDIS_URL: str = "redis://localhost:6379/0"
    QDRANT_URL: str = "http://localhost:6333"

    # LLM Settings (openai | gemini | mock)
    LLM_PROVIDER: str = "openai"
    LLM_API_KEY: str = ""
    LLM_MODEL: str = "gpt-4o"
    GEMINI_API_KEY: str = ""
    GEMINI_MODEL: str = "gemini-1.5-flash"

    # STT Settings (whisper | openai | mock)
    STT_PROVIDER: str = "whisper"
    STT_API_KEY: str = ""

    # TTS Settings (elevenlabs | openai | mock)
    TTS_PROVIDER: str = "elevenlabs"
    TTS_API_KEY: str = ""
    TTS_VOICE_ID: str = "21m00Tcm4TlvDq8ikWAM"  # Default ElevenLabs voice ID (Rachel)
    TTS_MODEL: str = "eleven_monolingual_v1"


settings = BaseConfig()
