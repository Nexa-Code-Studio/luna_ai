from datetime import datetime, timedelta, UTC
import logging
from typing import Any

import jwt

from shared.config import settings

logger = logging.getLogger(__name__)

JWT_SECRET_KEY = getattr(settings, "JWT_SECRET_KEY", "luna-ai-secret-jwt-key-2026")
JWT_ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_DAYS = 1
REFRESH_TOKEN_EXPIRE_DAYS = 30


def create_access_token(user_id: str, email: str, name: str) -> str:
    """Generate signed JWT access token containing user identity claims."""
    now = datetime.now(UTC)
    expire = now + timedelta(days=ACCESS_TOKEN_EXPIRE_DAYS)
    payload = {
        "sub": str(user_id),
        "email": email,
        "name": name,
        "type": "access",
        "iat": int(now.timestamp()),
        "exp": int(expire.timestamp()),
    }
    return jwt.encode(payload, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)


def create_refresh_token(user_id: str, email: str) -> str:
    """Generate signed JWT refresh token for renewing access tokens."""
    now = datetime.now(UTC)
    expire = now + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)
    payload = {
        "sub": str(user_id),
        "email": email,
        "type": "refresh",
        "iat": int(now.timestamp()),
        "exp": int(expire.timestamp()),
    }
    return jwt.encode(payload, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)


def decode_access_token(token: str) -> dict[str, Any] | None:
    """Decode and validate JWT access token."""
    try:
        payload = jwt.decode(token, JWT_SECRET_KEY, algorithms=[JWT_ALGORITHM])
        token_type = payload.get("type", "access")
        if token_type != "access":
            logger.warning(f"Invalid token type for access token: {token_type}")
            return None
        return payload
    except jwt.PyJWTError as e:
        logger.warning(f"Failed to decode JWT access token: {e}")
        return None


def decode_refresh_token(token: str) -> dict[str, Any] | None:
    """Decode and validate JWT refresh token."""
    try:
        payload = jwt.decode(token, JWT_SECRET_KEY, algorithms=[JWT_ALGORITHM])
        if payload.get("type") != "refresh":
            logger.warning("Invalid token type for refresh token")
            return None
        return payload
    except jwt.PyJWTError as e:
        logger.warning(f"Failed to decode JWT refresh token: {e}")
        return None
