from app.tasks.emotion_task import detect_voice_emotion_task
from app.tasks.risk_task import assess_risk_task
from app.tasks.symptom_task import extract_symptom_task
from app.tasks.summarization import extract_memory_task, summarize_conversation_task
from arq.connections import RedisSettings
from shared.config import settings


def parse_redis_settings(url: str) -> RedisSettings:
    """Helper to convert redis URL to ARQ RedisSettings."""
    from urllib.parse import urlparse
    parsed = urlparse(url)
    return RedisSettings(
        host=parsed.hostname or "localhost",
        port=parsed.port or 6379,
        database=int(parsed.path.lstrip("/") or 0),
    )


class WorkerSettings:
    functions = [
        summarize_conversation_task,
        extract_memory_task,
        detect_voice_emotion_task,
        extract_symptom_task,
        assess_risk_task,
    ]
    redis_settings = parse_redis_settings(settings.REDIS_URL)
    max_jobs = 10



