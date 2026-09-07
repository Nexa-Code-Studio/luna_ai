import logging
from typing import Any
import uuid

from fastapi import APIRouter, Depends, Header, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import decode_access_token
from app.db.session import get_db_session
from app.models.user import EmergencyContact, User

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/users", tags=["Users"])


class CreateEmergencyContactRequest(BaseModel):
    name: str
    relationship: str
    phone_number: str
    is_primary: bool = False


class UpdateEmergencyContactRequest(BaseModel):
    name: str | None = None
    relationship: str | None = None
    phone_number: str | None = None
    is_primary: bool | None = None


async def _get_current_user(
    authorization: str | None = Header(None),
    db: AsyncSession = Depends(get_db_session),
) -> User:
    if authorization and authorization.startswith("Bearer "):
        token = authorization.split("Bearer ")[1].strip()
        decoded = decode_access_token(token)
        if decoded and "sub" in decoded:
            try:
                u_uuid = uuid.UUID(decoded["sub"])
                query_jwt = select(User).where(User.id == u_uuid)
                res_jwt = await db.execute(query_jwt)
                user = res_jwt.scalar_one_or_none()
                if user:
                    return user
            except (ValueError, Exception):
                pass

    # Fallback to default user (dev/local mode)
    query = select(User).where(User.email == "user.luna@gmail.com")
    res = await db.execute(query)
    user = res.scalar_one_or_none()
    if not user:
        query_any = select(User)
        res_any = await db.execute(query_any)
        user = res_any.scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


@router.get("/emergency-contacts")
async def get_emergency_contacts(
    user: User = Depends(_get_current_user),
    db: AsyncSession = Depends(get_db_session),
) -> list[dict[str, Any]]:
    query = select(EmergencyContact).where(EmergencyContact.user_id == user.id)
    res = await db.execute(query)
    contacts = res.scalars().all()

    return [
        {
            "id": str(c.id),
            "name": c.name,
            "relationship": c.relationship,
            "phone": c.phone_number,
            "isPrimary": c.is_primary,
        }
        for c in contacts
    ]


@router.post("/emergency-contacts")
async def create_emergency_contact(
    payload: CreateEmergencyContactRequest,
    user: User = Depends(_get_current_user),
    db: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    # If new contact is primary, unset others
    if payload.is_primary:
        existing_q = select(EmergencyContact).where(
            EmergencyContact.user_id == user.id,
            EmergencyContact.is_primary == True,  # noqa: E712
        )
        existing_res = await db.execute(existing_q)
        for c in existing_res.scalars().all():
            c.is_primary = False

    contact = EmergencyContact(
        user_id=user.id,
        name=payload.name,
        relationship=payload.relationship,
        phone_number=payload.phone_number,
        is_primary=payload.is_primary,
    )
    db.add(contact)
    await db.commit()
    await db.refresh(contact)

    return {
        "id": str(contact.id),
        "name": contact.name,
        "relationship": contact.relationship,
        "phone": contact.phone_number,
        "isPrimary": contact.is_primary,
    }


@router.put("/emergency-contacts/{contact_id}")
async def update_emergency_contact(
    contact_id: str,
    payload: UpdateEmergencyContactRequest,
    user: User = Depends(_get_current_user),
    db: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    try:
        c_uuid = uuid.UUID(contact_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid contact ID")

    query = select(EmergencyContact).where(
        EmergencyContact.id == c_uuid,
        EmergencyContact.user_id == user.id,  # ensure ownership
    )
    res = await db.execute(query)
    contact = res.scalar_one_or_none()

    if not contact:
        raise HTTPException(status_code=404, detail="Contact not found")

    if payload.name is not None:
        contact.name = payload.name
    if payload.relationship is not None:
        contact.relationship = payload.relationship
    if payload.phone_number is not None:
        contact.phone_number = payload.phone_number
    if payload.is_primary is not None:
        if payload.is_primary:
            # Unset other primary contacts
            existing_q = select(EmergencyContact).where(
                EmergencyContact.user_id == user.id,
                EmergencyContact.is_primary == True,  # noqa: E712
            )
            existing_res = await db.execute(existing_q)
            for c in existing_res.scalars().all():
                c.is_primary = False
        contact.is_primary = payload.is_primary

    await db.commit()
    await db.refresh(contact)

    return {
        "id": str(contact.id),
        "name": contact.name,
        "relationship": contact.relationship,
        "phone": contact.phone_number,
        "isPrimary": contact.is_primary,
    }


@router.delete("/emergency-contacts/{contact_id}")
async def delete_emergency_contact(
    contact_id: str,
    user: User = Depends(_get_current_user),
    db: AsyncSession = Depends(get_db_session),
) -> dict[str, str]:
    try:
        c_uuid = uuid.UUID(contact_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid contact ID")

    query = select(EmergencyContact).where(
        EmergencyContact.id == c_uuid,
        EmergencyContact.user_id == user.id,
    )
    res = await db.execute(query)
    contact = res.scalar_one_or_none()

    if not contact:
        raise HTTPException(status_code=404, detail="Contact not found")

    await db.delete(contact)
    await db.commit()
    return {"message": "Contact deleted successfully"}
