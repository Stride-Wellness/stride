from enum import Enum
from pydantic import BaseModel, Field, ConfigDict
from datetime import datetime
from typing import Any


def to_camel(string: str) -> str:
    """Convert snake_case to camelCase"""
    components = string.split('_')
    return components[0] + ''.join(x.title() for x in components[1:])

class AdminPrivilegeLevel(int, Enum):
    """Admin privilege levels: 0=super admin, 1=admin, 2=moderator, 3=read-only"""
    SUPER_ADMIN = 0
    ADMIN = 1
    MODERATOR = 2
    READ_ONLY = 3

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