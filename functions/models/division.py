from pydantic import BaseModel, Field, ConfigDict
from datetime import datetime
from typing import Optional, Any
from enum import Enum
from .user import UserStatus 


def to_camel(string: str) -> str:
    """Convert snake_case to camelCase"""
    components = string.split('_')
    return components[0] + ''.join(x.title() for x in components[1:])


class DivisionType(str, Enum):
    RETIREMENT_HOME = 'retirement_home'
    HOMECARE_PROVIDER = 'homecare_provider'


class DivisionSettings(BaseModel):
    """Division settings (flexible dict)"""
    model_config = ConfigDict(
        alias_generator=to_camel,
        populate_by_name=True,
        extra='allow',  # Allow additional fields beyond the defined ones
    )

    # Add any common settings here, or leave empty for fully flexible dict
    # Example: default_language: Optional[str] = None


class Division(BaseModel):
    """Division/location model"""
    model_config = ConfigDict(
        alias_generator=to_camel,
        populate_by_name=True,
        use_enum_values=True,
    )

    id: str
    organization_id: str
    name: str
    division_type: DivisionType
    settings: DivisionSettings = Field(default_factory=DivisionSettings)
    status: UserStatus
    created_at: datetime
    updated_at: datetime
    manager_id: Optional[str] = None
    deleted_at: Optional[datetime] = None

    def is_active(self) -> bool:
        """Check if division is active"""
        return self.status == UserStatus.ACTIVE and not self.deleted_at

    def to_dict(self) -> dict[str, Any]:
        """Convert to Firestore-compatible dict with camelCase keys"""
        return self.model_dump(by_alias=True, exclude_none=True)

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> 'Division':
        """Create from Firestore dict"""
        return cls.model_validate(data)