from pathlib import Path

from pydantic import model_validator
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
    PORT: int = 8888
    MCP_PORT: int = 8889



    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@localhost:5433/luna_ai"
    REDIS_URL: str = "redis://localhost:6380/0"
    QDRANT_URL: str = "http://localhost:6333"

    @model_validator(mode="after")
    def _apply_os_environment_overrides(self) -> "BaseConfig":
        """Force explicit OS environment variables (e.g. from Docker Compose) to override .env file."""
        import os
        if "DATABASE_URL" in os.environ:
            self.DATABASE_URL = os.environ["DATABASE_URL"]
        if "REDIS_URL" in os.environ:
            self.REDIS_URL = os.environ["REDIS_URL"]
        if "QDRANT_URL" in os.environ:
            self.QDRANT_URL = os.environ["QDRANT_URL"]
        return self

    # LLM Settings (openai | gemini | ollama | mock)
    LLM_PROVIDER: str = "openai"
    LLM_API_KEY: str = ""
    LLM_MODEL: str = "gpt-4o"
    GEMINI_API_KEY: str = ""
    GEMINI_MODEL: str = "gemini-1.5-flash"
    DEEPSEEK_MODEL: str = "deepseek-chat"
    OLLAMA_BASE_URL: str = "http://100.82.167.100:11434"

    OLLAMA_MODEL: str = "qwen3:1.7B"

    # STT Settings (whisper | openai | mock)
    STT_PROVIDER: str = "whisper"
    STT_API_KEY: str = ""

    # TTS Settings (elevenlabs | openai | edge_tts | mock)
    TTS_PROVIDER: str = "elevenlabs"
    TTS_API_KEY: str = ""
    TTS_VOICE_ID: str = "21m00Tcm4TlvDq8ikWAM"  # Default ElevenLabs voice ID (Rachel)
    TTS_MODEL: str = "eleven_monolingual_v1"
    EDGE_TTS_VOICE: str = "id-ID-GadisNeural"




settings = BaseConfig()
