from pydantic import BaseModel, EmailStr, Field, field_validator, ConfigDict
from datetime import datetime
from typing import Optional, Union, Any, Literal
from enum import Enum


def to_camel(string: str) -> str:
    """Convert snake_case to camelCase"""
    components = string.split('_')
    return components[0] + ''.join(x.title() for x in components[1:])


# ============================================================================
# Enums
# ============================================================================


class ProviderRole(str, Enum):
    PSW = 'psw'
    LW = 'lw'
    ADMIN = 'admin'
    MANAGER = 'manager'


class UserType(str, Enum):
    EMPLOYEE = "provider"
    CLIENT = 'client'

class UserStatus(str, Enum):
    ACTIVE = 'active'
    INACTIVE = 'inactive'
    PENDING = 'pending'
    DELETED = 'deleted'

class MobilityType(str, Enum):
    INDEPENDENT = 'independent'
    CANE = 'cane'
    WALKER = 'walker'
    WHEELCHAIR = 'wheelchair'


# ============================================================================
# Profile Models
# ============================================================================

class EmergencyContact(BaseModel):
    """Emergency contact information"""
    model_config = ConfigDict(
        alias_generator=to_camel,
        populate_by_name=True,
    )

    name: str
    phone: str
    relationship: str


class MedicalInfo(BaseModel):
    """Medical information"""
    model_config = ConfigDict(
        alias_generator=to_camel,
        populate_by_name=True,
        use_enum_values=True,
        extra='allow',  # Allow extra fields
    )

    conditions: list[str] = Field(default_factory=list)
    medications: list[str] = Field(default_factory=list)
    mobility: MobilityType = MobilityType.INDEPENDENT
    notes: str = ""


class ProviderProfile(BaseModel):
    """Provider profile (flexible dict)"""

    model_config = ConfigDict(
        alias_generator=to_camel,
        populate_by_name=True,
        extra='allow',  # Allow any additional fields
    )

    # Add common fields here if needed
    # Example: certification: Optional[str] = None


class ClientProfile(BaseModel):
    """Client profile"""
    model_config = ConfigDict(
        alias_generator=to_camel,
        populate_by_name=True,
        extra='allow',  # Allow extra fields
    )

    phone: Optional[str] = None
    date_of_birth: Optional[str] = None  # Could use date type if you want validation
    emergency_contact: Optional[EmergencyContact] = None
    medical_info: Optional[MedicalInfo] = None


# ============================================================================
# User Models
# ============================================================================

class BaseUser(BaseModel):
    """Base user model"""
    model_config = ConfigDict(
        alias_generator=to_camel,
        populate_by_name=True,
        use_enum_values=True,
    )

    id: str
    email: EmailStr  # ✅ Validates email format
    name: str
    organization_id: str
    division_id: str
    status: UserStatus
    created_at: datetime
    updated_at: datetime
    last_sign_in: datetime | None


class ProviderUser(BaseUser):
    """Provider user model"""

    type: Literal["provider"] = "provider"
    provider_role: list[ProviderRole] = Field(default_factory=list)
    profile: ProviderProfile = Field(default_factory=ProviderProfile)

    def has_role(self, role: ProviderRole) -> bool:
        """Check if provider has specific role"""
        return role in self.provider_role

    def is_manager(self) -> bool:
        """Check if provider is manager"""
        return ProviderRole.MANAGER in self.provider_role

    def to_dict(self) -> dict[str, Any]:
        """Convert to Firestore-compatible dict with camelCase keys"""
        return self.model_dump(by_alias=True, exclude_none=True)

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "ProviderUser":
        """Create from Firestore dict"""
        return cls.model_validate(data)


class ClientUser(BaseUser):
    """Client user model"""
    type: Literal['client'] = 'client'
    profile: ClientProfile = Field(default_factory=ClientProfile)

    def to_dict(self) -> dict[str, Any]:
        """Convert to Firestore-compatible dict with camelCase keys"""
        return self.model_dump(by_alias=True, exclude_none=True)

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> 'ClientUser':
        """Create from Firestore dict"""
        return cls.model_validate(data)


# ============================================================================
# Type Aliases & Helper Functions
# ============================================================================

User = Union[ProviderUser, ClientUser]


def is_provider(user: User) -> bool:
    """Check if user is provider"""
    return isinstance(user, ProviderUser)


def is_client(user: User) -> bool:
    """Check if user is client"""
    return isinstance(user, ClientUser)


def user_from_dict(data: dict[str, Any]) -> User:
    """Create user from Firestore dict (auto-detect type)"""
    user_type = data.get('type')
    if user_type == "provider":
        return ProviderUser.model_validate(data)
    elif user_type == 'client':
        return ClientUser.model_validate(data)
    else:
        raise ValueError(f'Unknown user type: {user_type}')

# ============================================================================
# Request Models
# ============================================================================


class GetUsersRequest(BaseModel):
    """Request model for getting users"""

    model_config = ConfigDict(
        alias_generator=to_camel,
        populate_by_name=True,
    )

    limit: int = Field(default=100, ge=1, le=1000)
    user_ids: Optional[list[str]] = None
    organization_id: Optional[str] = None
    division_id: Optional[str] = None
    user_type: Optional[UserType] = None
    status: Optional[UserStatus] = None
    include_deleted: bool = False


class CreateProviderRequest(BaseModel):
    """Request to create a new provider"""

    email: str
    password: str
    name: str
    organization_id: str
    division_id: str
    provider_role: list[str]  # Required for providers


class CreateClientRequest(BaseModel):
    """Request to create a new client"""
    email: str
    password: str
    name: str
    organization_id: str
    division_id: str
    phone: Optional[str] = None
    date_of_birth: Optional[str] = None


class UpdateProviderRequest(BaseModel):
    """Request to update provider data"""

    user_id: str
    name: Optional[str] = None
    status: Optional[str] = None
    provider_role: Optional[list[str]] = None
    profile: Optional[dict] = None


class UpdateClientRequest(BaseModel):
    """Request to update client data"""
    user_id: str
    name: Optional[str] = None
    status: Optional[str] = None
    profile: Optional[dict] = None


class DeleteUserRequest(BaseModel):
    """Request to delete a user"""
    user_id: str
    hard_delete: bool = False  # True = delete from Auth, False = soft delete
