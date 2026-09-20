import logging
from typing import Any
import uuid

from fastapi import APIRouter, Depends, Header, HTTPException, Query, status
from pydantic import BaseModel, EmailStr
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_access_token,
    decode_refresh_token,
    hash_password,
    verify_password,
)
from app.db.session import get_db_session
from app.models.user import User

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/auth", tags=["Auth"])


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class RegisterRequest(BaseModel):
    name: str
    email: EmailStr
    password: str


class RefreshRequest(BaseModel):
    refresh_token: str


@router.get("/check-email")
async def check_email(
    email: str = Query(..., description="Email address to check"),
    db: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """Check if an email address is available for registration."""
    clean_email = email.strip().lower()
    if not clean_email or "@" not in clean_email or "." not in clean_email:
        return {
            "available": False,
            "email": clean_email,
            "message": "Format email tidak valid",
        }

    query = select(User).where(User.email == clean_email)
    res = await db.execute(query)
    existing = res.scalar_one_or_none()

    if existing:
        return {
            "available": False,
            "email": clean_email,
            "message": "Email sudah terdaftar",
        }

    return {
        "available": True,
        "email": clean_email,
        "message": "Email tersedia",
    }


@router.post("/login")
async def login(payload: LoginRequest, db: AsyncSession = Depends(get_db_session)) -> dict[str, Any]:
    clean_email = payload.email.strip().lower()
    query = select(User).where(User.email == clean_email)
    res = await db.execute(query)
    user = res.scalar_one_or_none()

    if not user or not verify_password(payload.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email atau kata sandi tidak valid",
        )

    display_name = user.display_name or user.username or "User Luna"
    access_token = create_access_token(user_id=str(user.id), email=user.email, name=display_name)
    refresh_token = create_refresh_token(user_id=str(user.id), email=user.email)

    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "user": {
            "id": str(user.id),
            "name": display_name,
            "email": user.email,
        },
    }


@router.post("/register")
async def register(payload: RegisterRequest, db: AsyncSession = Depends(get_db_session)) -> dict[str, Any]:
    clean_email = payload.email.strip().lower()
    query = select(User).where(User.email == clean_email)
    res = await db.execute(query)
    existing = res.scalar_one_or_none()

    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email sudah terdaftar",
        )

    clean_name = payload.name.strip()
    user = User(
        email=clean_email,
        username=clean_name,
        display_name=clean_name,
        password_hash=hash_password(payload.password),
        is_active=True,
        is_verified=True,
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)

    display_name = user.display_name or clean_name
    access_token = create_access_token(user_id=str(user.id), email=user.email, name=display_name)
    refresh_token = create_refresh_token(user_id=str(user.id), email=user.email)

    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "user": {
            "id": str(user.id),
            "name": display_name,
            "email": user.email,
        },
    }


@router.post("/refresh")
async def refresh_token(payload: RefreshRequest, db: AsyncSession = Depends(get_db_session)) -> dict[str, Any]:
    decoded = decode_refresh_token(payload.refresh_token)
    if not decoded or "sub" not in decoded:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Refresh token tidak valid atau telah kedaluwarsa",
        )

    try:
        u_uuid = uuid.UUID(decoded["sub"])
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Format user ID token tidak valid",
        )

    query = select(User).where(User.id == u_uuid)
    res = await db.execute(query)
    user = res.scalar_one_or_none()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User tidak ditemukan atau tidak aktif",
        )

    display_name = user.display_name or user.username or "User Luna"
    new_access_token = create_access_token(user_id=str(user.id), email=user.email, name=display_name)
    new_refresh_token = create_refresh_token(user_id=str(user.id), email=user.email)

    return {
        "access_token": new_access_token,
        "refresh_token": new_refresh_token,
        "token_type": "bearer",
        "user": {
            "id": str(user.id),
            "name": display_name,
            "email": user.email,
        },
    }


@router.get("/me")
async def get_me(
    authorization: str | None = Header(None),
    db: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    if not authorization or not authorization.startswith("Bearer "):
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
            detail="Pengguna tidak ditemukan atau telah dihapus",
        )

    return {
        "id": str(user.id),
        "name": user.display_name or user.username or "User Luna",
        "email": user.email,
    }


@router.post("/logout")
async def logout() -> dict[str, str]:
    return {"message": "Logged out successfully"}
