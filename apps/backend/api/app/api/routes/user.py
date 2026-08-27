import logging
from typing import Any
import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db_session
from app.models.user import EmergencyContact, User

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/users", tags=["Users"])


class CreateEmergencyContactRequest(BaseModel):
    name: str
    relationship: str
    phone_number: str
    is_primary: bool = False


async def _get_default_user(db: AsyncSession) -> User:
    query = select(User).where(User.email == "user.luna@gmail.com")
    res = await db.execute(query)
    user = res.scalar_one_or_none()
    if not user:
        query_any = select(User)
        res_any = await db.execute(query_any)
        user = res_any.scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="Default user not found")
    return user


@router.get("/emergency-contacts")
async def get_emergency_contacts(db: AsyncSession = Depends(get_db_session)) -> list[dict[str, Any]]:
    user = await _get_default_user(db)
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
    payload: CreateEmergencyContactRequest, db: AsyncSession = Depends(get_db_session)
) -> dict[str, Any]:
    user = await _get_default_user(db)
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


@router.delete("/emergency-contacts/{contact_id}")
async def delete_emergency_contact(contact_id: str, db: AsyncSession = Depends(get_db_session)) -> dict[str, str]:
    try:
        c_uuid = uuid.UUID(contact_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid contact ID")

    query = select(EmergencyContact).where(EmergencyContact.id == c_uuid)
    res = await db.execute(query)
    contact = res.scalar_one_or_none()

    if not contact:
        raise HTTPException(status_code=404, detail="Contact not found")

    await db.delete(contact)
    await db.commit()
    return {"message": "Contact deleted successfully"}
