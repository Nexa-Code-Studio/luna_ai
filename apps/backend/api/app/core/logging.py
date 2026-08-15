import logging
import sys

from shared.config import settings


def setup_logging() -> None:
    """Setup structured logging for FastAPI service."""
    logging.basicConfig(
        level=settings.LOG_LEVEL,
        format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
        handlers=[logging.StreamHandler(sys.stdout)],
    )
