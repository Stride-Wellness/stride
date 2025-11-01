from pydantic import BaseModel, Field, field_validator, ConfigDict
from datetime import datetime
from typing import Optional, Any
from enum import Enum
from .utils import to_camel


class AssignmentStatus(str, Enum):
    ACTIVE = 'active'
    INACTIVE = 'inactive'
    COMPLETED = 'completed'


class AssignmentPermissions(BaseModel):
    """Assignment permissions model"""
    model_config = ConfigDict(
        alias_generator=to_camel,
        populate_by_name=True,
    )

    can_modify_exercises: bool = False
    can_view_medical_info: bool = False
    can_schedule_sessions: bool = False


class Assignment(BaseModel):
    """Client-provider assignment model"""
    model_config = ConfigDict(
        alias_generator=to_camel,
        populate_by_name=True,
        use_enum_values=True,  # Serialize enum as string value
    )

    id: str
    client_id: str
    provider_id: str
    division_id: str
    assigned_by: str
    status: AssignmentStatus
    permissions: AssignmentPermissions
    assigned_at: datetime
    created_at: datetime
    updated_at: datetime
    last_session_at: Optional[datetime] = None

    @field_validator('assigned_at', 'last_session_at', 'created_at')
    @classmethod
    def validate_not_future(cls, v: Optional[datetime]) -> Optional[datetime]:
        """Validate dates are not in the future"""
        if v and v > datetime.now():
            raise ValueError('Date cannot be in the future')
        return v

    def is_active(self) -> bool:
        """Check if assignment is active"""
        return self.status == AssignmentStatus.ACTIVE

    def to_dict(self) -> dict[str, Any]:
        """Convert to Firestore-compatible dict with camelCase keys"""
        return self.model_dump(by_alias=True, exclude_none=True)

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> 'Assignment':
        """Create from Firestore dict"""
        return cls.model_validate(data)
