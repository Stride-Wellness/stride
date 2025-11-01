from pydantic import BaseModel, Field, ConfigDict
from datetime import datetime
from typing import Optional, Any
from enum import Enum
from .user import UserStatus 
from .utils import to_camel


class ExerciseType(str, Enum):
    PHYSICAL = 'physical'
    STRETCHING = 'stretching'
    BALANCE = 'balance'
    STRENGTH = 'strength'
    CARDIO = 'cardio'
    MEMORY = 'memory'        # New: for memory games
    COGNITIVE = 'cognitive'  # New: for general cognitive activities
    PUZZLE = 'puzzle'        # New: for puzzles and problem-solving


class DifficultyLevel(str, Enum):
    BEGINNER = 'beginner'
    INTERMEDIATE = 'intermediate'
    ADVANCED = 'advanced'


class ExerciseInstruction(BaseModel):
    """Individual instruction step for an exercise"""
    model_config = ConfigDict(
        alias_generator=to_camel,
        populate_by_name=True,
    )
    
    step_number: int
    instruction: str
    image_url: Optional[str] = None


class ExerciseModification(BaseModel):
    """Modification for different ability levels"""
    model_config = ConfigDict(
        alias_generator=to_camel,
        populate_by_name=True,
    )
    
    level: str  # e.g., "easier", "harder", "seated"
    description: str


class ExerciseSafety(BaseModel):
    """Safety considerations and precautions"""
    model_config = ConfigDict(
        alias_generator=to_camel,
        populate_by_name=True,
    )
    
    contraindications: list[str] = Field(default_factory=list)
    warnings: list[str] = Field(default_factory=list)
    tips: list[str] = Field(default_factory=list)


class Exercise(BaseModel):
    """Exercise/activity model"""
    model_config = ConfigDict(
        alias_generator=to_camel,
        populate_by_name=True,
        use_enum_values=True,
    )

    id: str
    created_for: str  # User ID
    based_off: str  # Assessment ID or "initial_assessment"
    title: str
    description: str 
    exercise_type: ExerciseType
    difficulty: DifficultyLevel = DifficultyLevel.BEGINNER
    
    # Exercise details
    duration_minutes: Optional[int] = None
    repetitions: Optional[int] = None
    sets: Optional[int] = None
    rest_between_sets_seconds: Optional[int] = None
    
    # Instructions and modifications
    instructions: list[ExerciseInstruction] = Field(default_factory=list)
    modifications: list[ExerciseModification] = Field(default_factory=list)
    equipment_needed: list[str] = Field(default_factory=list)
    
    # Safety information
    safety: Optional[ExerciseSafety] = None
    
    # Target areas
    target_muscles: list[str] = Field(default_factory=list)
    benefits: list[str] = Field(default_factory=list)
    
    # Metadata
    created_at: datetime
    used_at: list[datetime] = Field(default_factory=list)
    notes: Optional[str] = None

    def to_dict(self) -> dict[str, Any]:
        """Convert to Firestore-compatible dict with camelCase keys"""
        data = self.model_dump(by_alias=True, exclude_none=True)
            # Convert datetime objects to ISO format strings
        if isinstance(data.get('createdAt'), datetime):
            data['createdAt'] = data['createdAt'].isoformat()
        if isinstance(data.get('usedAt'), list):
            data['usedAt'] = [dt.isoformat() if isinstance(dt, datetime) else dt for dt in data['usedAt']]
        return data

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> 'Exercise':
        """Create from Firestore dict"""
        return cls.model_validate(data)


class CreateExerciseRequest(BaseModel):
    """Request model for creating an exercise"""

    model_config = ConfigDict(
        alias_generator=to_camel,
        populate_by_name=True,
    )

    user_id: str
    user_requests: Optional[str] = None
    assessment_id: Optional[str] = None  # Which assessment to base it off