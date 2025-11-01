from enum import Enum
from pydantic import BaseModel, Field, ConfigDict, field_validator
from datetime import datetime
from typing import Any, Optional
from .utils import to_camel

class AdminPrivilegeLevel(int, Enum):
    """Admin privilege levels: 0=super admin, 1=admin, 2=moderator, 3=read-only"""
    SUPER_ADMIN = 0
    ADMIN = 1
    MODERATOR = 2
    READ_ONLY = 3
    DISABLED = 4

class Admin(BaseModel):
    """Admin user model"""
    model_config = ConfigDict(
        alias_generator=to_camel,
        populate_by_name=True,  # Allow both camelCase and snake_case
    )

    id: str
    name: str
    privilege: AdminPrivilegeLevel
    created_at: datetime
    created_by: str
    updated_at: datetime
    last_sign_in: datetime | None = None

    def is_super_admin(self) -> bool:
        """Check if user is super admin"""
        return self.privilege == AdminPrivilegeLevel.SUPER_ADMIN

    def is_admin(self) -> bool:
        """Check if user is admin or higher"""
        return self.privilege <= AdminPrivilegeLevel.ADMIN

    def can_modify(self) -> bool:
        """Check if user can modify data"""
        return self.privilege <= AdminPrivilegeLevel.MODERATOR

    def to_dict(self) -> dict[str, Any]:
        """Convert to Firestore-compatible dict with camelCase keys"""
        return self.model_dump(by_alias=True)

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> 'Admin':
        """Create from Firestore dict"""
        return cls.model_validate(data)


class GetAdminsRequest(BaseModel):
    """Request model for getting admins"""

    model_config = ConfigDict(
        alias_generator=to_camel,
        populate_by_name=True,
    )

    limit: int = Field(default=100, ge=1, le=1000)
    user_ids: Optional[list[str]] = None
    privilege_level: Optional[AdminPrivilegeLevel] = None


class CreateAdminRequest(BaseModel):
    """Request model for creating a new admin"""

    model_config = ConfigDict(
        alias_generator=to_camel,
        populate_by_name=True,
    )

    email: str = Field(..., description="Admin email address")
    password: str = Field(
        ..., min_length=6, description="Admin password (min 6 characters)"
    )
    name: str = Field(..., min_length=1, description="Admin full name")
    privilege: AdminPrivilegeLevel = Field(
        default=AdminPrivilegeLevel.READ_ONLY, description="Admin privilege level"
    )

    @field_validator("email")
    @classmethod
    def validate_email(cls, v: str) -> str:
        """Basic email validation"""
        v = v.strip().lower()
        if "@" not in v or "." not in v.split("@")[1]:
            raise ValueError("Invalid email format")
        return v

    @field_validator("name")
    @classmethod
    def validate_name(cls, v: str) -> str:
        """Validate name is not empty after stripping"""
        stripped = v.strip()
        if not stripped:
            raise ValueError("Name cannot be empty")
        return stripped


class UpdateAdminRequest(BaseModel):
    """Request model for updating an admin"""

    model_config = ConfigDict(
        alias_generator=to_camel,
        populate_by_name=True,
    )

    user_id: str = Field(..., description="Admin user ID to update")
    name: Optional[str] = Field(None, min_length=1, description="New admin name")
    privilege: Optional[AdminPrivilegeLevel] = Field(
        None, description="New privilege level"
    )

    @field_validator("name")
    @classmethod
    def validate_name(cls, v: Optional[str]) -> Optional[str]:
        """Validate name if provided"""
        if v is not None:
            stripped = v.strip()
            if not stripped:
                raise ValueError("Name cannot be empty")
            return stripped
        return v

    def has_updates(self) -> bool:
        """Check if there are any fields to update"""
        return self.name is not None or self.privilege is not None


class DeleteAdminRequest(BaseModel):
    """Request model for deleting an admin"""

    model_config = ConfigDict(
        alias_generator=to_camel,
        populate_by_name=True,
    )

    user_id: str = Field(..., description="Admin user ID to delete")
