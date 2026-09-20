from datetime import UTC, datetime, timedelta
import hashlib
import hmac
import logging
import os
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


PBKDF2_ALGORITHM = "sha256"
PBKDF2_ITERATIONS = 100_000


def hash_password(password: str) -> str:
    """Hash password using standard PBKDF2-HMAC-SHA256 with a secure random 16-byte salt."""
    salt = os.urandom(16)
    key = hashlib.pbkdf2_hmac(
        PBKDF2_ALGORITHM,
        password.encode("utf-8"),
        salt,
        PBKDF2_ITERATIONS,
    )
    return f"pbkdf2_sha256${PBKDF2_ITERATIONS}${salt.hex()}${key.hex()}"


def verify_password(plain_password: str, hashed_password: str | None) -> bool:
    """Verify plain password against PBKDF2-SHA256 hash or legacy plain text (fallback)."""
    if not hashed_password or not plain_password:
        return False

    if hashed_password.startswith("pbkdf2_sha256$"):
        parts = hashed_password.split("$")
        if len(parts) != 4:
            return False
        try:
            iterations = int(parts[1])
            salt = bytes.fromhex(parts[2])
            expected_key = bytes.fromhex(parts[3])
            key = hashlib.pbkdf2_hmac(
                PBKDF2_ALGORITHM,
                plain_password.encode("utf-8"),
                salt,
                iterations,
            )
            return hmac.compare_digest(key, expected_key)
        except Exception as e:
            logger.warning(f"Error during password hash verification: {e}")
            return False

    # Safe backward-compatible check for legacy unhashed passwords
    return hmac.compare_digest(plain_password, hashed_password)


async def get_current_user(
    authorization: str | None = None,
    db: Any = None,
) -> Any:
    """Strictly authenticate current user from Bearer JWT access token."""
    import uuid
    from fastapi import Depends, Header, HTTPException, status
    from sqlalchemy import select
    from sqlalchemy.ext.asyncio import AsyncSession
    from app.db.session import get_db_session
    from app.models.user import User

    # When used with FastAPI Depends(), parameters can be resolved dynamically
    if authorization is None or db is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Header Authorization Bearer diperlukan",
        )

    if not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Header Authorization Bearer diperlukan",
        )

    token = authorization.split("Bearer ")[1].strip()
    decoded = decode_access_token(token)
    if not decoded or "sub" not in decoded:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token akses tidak valid atau telah kedaluwarsa",
        )

    try:
        u_uuid = uuid.UUID(decoded["sub"])
    except (ValueError, TypeError):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Format user ID dalam token tidak valid",
        )

    query_jwt = select(User).where(User.id == u_uuid)
    res_jwt = await db.execute(query_jwt)
    user = res_jwt.scalar_one_or_none()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Pengguna tidak ditemukan atau telah dinonaktifkan",
        )

    return user


