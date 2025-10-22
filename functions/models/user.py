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

class EmployeeRole(str, Enum):
    PSW = 'psw'
    LW = 'lw'
    ADMIN = 'admin'
    MANAGER = 'manager'

class UserType(str, Enum):
    EMPLOYEE = 'employee'
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


class EmployeeProfile(BaseModel):
    """Employee profile (flexible dict)"""
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
    last_login_at: Optional[datetime] = None
    deleted_at: Optional[datetime] = None


class EmployeeUser(BaseUser):
    """Employee user model"""
    type: Literal['employee'] = 'employee'
    employee_role: list[EmployeeRole] = Field(default_factory=list)
    profile: EmployeeProfile = Field(default_factory=EmployeeProfile)

    def has_role(self, role: EmployeeRole) -> bool:
        """Check if employee has specific role"""
        return role in self.employee_role

    def is_manager(self) -> bool:
        """Check if employee is manager"""
        return EmployeeRole.MANAGER in self.employee_role

    def to_dict(self) -> dict[str, Any]:
        """Convert to Firestore-compatible dict with camelCase keys"""
        return self.model_dump(by_alias=True, exclude_none=True)

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> 'EmployeeUser':
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

User = Union[EmployeeUser, ClientUser]


def is_employee(user: User) -> bool:
    """Check if user is employee"""
    return isinstance(user, EmployeeUser)


def is_client(user: User) -> bool:
    """Check if user is client"""
    return isinstance(user, ClientUser)


def user_from_dict(data: dict[str, Any]) -> User:
    """Create user from Firestore dict (auto-detect type)"""
    user_type = data.get('type')
    if user_type == 'employee':
        return EmployeeUser.model_validate(data)
    elif user_type == 'client':
        return ClientUser.model_validate(data)
    else:
        raise ValueError(f'Unknown user type: {user_type}')

# ============================================================================
# Request Models
# ============================================================================


class CreateEmployeeRequest(BaseModel):
    """Request to create a new employee"""
    email: str
    password: str
    name: str
    organization_id: str
    division_id: str
    employee_role: list[str]  # Required for employees


class CreateClientRequest(BaseModel):
    """Request to create a new client"""
    email: str
    password: str
    name: str
    organization_id: str
    division_id: str
    phone: Optional[str] = None
    date_of_birth: Optional[str] = None


class UpdateEmployeeRequest(BaseModel):
    """Request to update employee data"""
    user_id: str
    name: Optional[str] = None
    status: Optional[str] = None
    employee_role: Optional[list[str]] = None
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

