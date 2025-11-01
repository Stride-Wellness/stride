from enum import Enum
from pydantic import BaseModel, Field, ConfigDict, field_validator
from datetime import datetime
from typing import Any, Optional
from .utils import to_camel


class Assessment(BaseModel):
    """Admin user model"""
    model_config = ConfigDict(
        alias_generator=to_camel,
        populate_by_name=True,  # Allow both camelCase and snake_case
    )

    id: str
    name: str
    answers: dict[str, str]
    questions: dict[str, str]
    timestamp: datetime
    user_id: str

    def to_dict(self) -> dict[str, Any]:
        """Convert to Firestore-compatible dict with camelCase keys"""
        return self.model_dump(by_alias=True)

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> 'Assessment':
        """Create from Firestore dict"""
        return cls.model_validate(data)
