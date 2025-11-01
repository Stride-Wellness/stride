from pydantic import BaseModel, Field, field_validator, ConfigDict
from datetime import datetime
from typing import Any
from enum import Enum
from .utils import to_camel

class OrganizationStatus(str, Enum):
    ACTIVE = 'active'
    SUSPENDED = 'suspended'
    CANCELLED = 'cancelled'


class OrganizationSettings(BaseModel):
    """Organization settings (flexible dict)"""
    model_config = ConfigDict(
        alias_generator=to_camel,
        populate_by_name=True,
        extra='allow',  # Allow additional fields beyond the defined ones
    )

    # Add any common settings here, or leave empty for fully flexible dict
    # Example: default_timezone: Optional[str] = None


class Organization(BaseModel):
    """Organization model"""
    model_config = ConfigDict(
        alias_generator=to_camel,
        populate_by_name=True,
        use_enum_values=True,
    )

    id: str
    name: str
    total_seats: int = Field(ge=0, description="Total seats available")
    used_seats: int = Field(ge=0, description="Currently used seats")
    status: OrganizationStatus
    stripe_user_id: str
    settings: OrganizationSettings = Field(default_factory=OrganizationSettings)
    created_at: datetime
    updated_at: datetime

    @field_validator('used_seats')
    @classmethod
    def validate_seats(cls, v: int, info) -> int:
        """Validate used_seats <= total_seats"""
        total = info.data.get('total_seats', 0)
        if v > total:
            raise ValueError(f'Used seats ({v}) cannot exceed total seats ({total})')
        return v

    def has_available_seats(self) -> bool:
        """Check if organization has available seats"""
        return self.used_seats < self.total_seats

    def is_active(self) -> bool:
        """Check if organization is active"""
        return self.status == OrganizationStatus.ACTIVE

    def to_dict(self) -> dict[str, Any]:
        """Convert to Firestore-compatible dict with camelCase keys"""
        return self.model_dump(by_alias=True, exclude_none=True)

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> 'Organization':
        """Create from Firestore dict"""
        return cls.model_validate(data)
