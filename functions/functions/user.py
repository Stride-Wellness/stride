from google.cloud.firestore_v1.client import Client as FirestoreClient
from firebase_admin import auth, firestore
from datetime import datetime
from typing import Any, Optional
from models.user import (
    ClientUser,
    CreateClientRequest,
    CreateProviderRequest,
    DeleteUserRequest,
    ProviderRole,
    GetUsersRequest,
    ProviderUser,
    UpdateClientRequest,
    UpdateProviderRequest,
    User,
    user_from_dict,  # Assuming you have a User base model
)


def create_provider_user(
    db: FirestoreClient,
    request: CreateProviderRequest,
    created_by_uid: str,
) -> tuple[Optional[ProviderUser], Optional[str]]:
    """
    Create a new provider (Firebase Auth + Firestore)
    Returns (user, error_message)
    """
    # Validate provider roles
    if not request.provider_role:
        return None, "Provider must have at least one role"

    # Validate role values
    valid_roles = [role.value for role in ProviderRole]
    for role in request.provider_role:
        if role not in valid_roles:
            return None, f"Invalid role: {role}. Valid roles: {valid_roles}"

    # Create Firebase Auth user
    try:
        auth_user = auth.create_user(
            email=request.email,
            password=request.password,
            display_name=request.name,
        )
    except auth.EmailAlreadyExistsError:
        return None, f"Email {request.email} already exists"
    except Exception as e:
        return None, f"Error creating auth user: {str(e)}"

    # Create Firestore provider document
    now = datetime.now()
    provider_data = {
        "id": auth_user.uid,
        "email": request.email,
        "name": request.name,
        "type": "provider",
        "organizationId": request.organization_id,
        "divisionId": request.division_id,
        "providerRole": request.provider_role,
        "status": "active",
        "profile": {},
        "createdAt": now,
        "updatedAt": now,
        "createdBy": created_by_uid,
    }

    try:
        db.collection("users").document(auth_user.uid).set(provider_data)
    except Exception as e:
        # Rollback: delete auth user if Firestore fails
        auth.delete_user(auth_user.uid)
        return None, f"Error creating Firestore document: {str(e)}"

    try:
        user = ProviderUser.from_dict(provider_data)
        return user, None
    except Exception as e:
        return None, f"Error parsing user data: {str(e)}"


def update_provider_user(
    db: FirestoreClient,
    request: UpdateProviderRequest,
    updated_by_uid: str,
) -> tuple[Optional[ProviderUser], Optional[str]]:
    """
    Update provider data in Firestore
    Returns (updated_user, error_message)
    """
    # Check user exists and is provider
    user_ref = db.collection("users").document(request.user_id)
    user_doc = user_ref.get()

    if not user_doc.exists:
        return None, f"User {request.user_id} not found"

    user_data = user_doc.to_dict()

    if (user_data or {}).get("type") != "provider":
        return None, f"User {request.user_id} is not an provider"

    # Build update data
    update_data: dict[str, Any] = {
        "updatedAt": datetime.now(),
        "updatedBy": updated_by_uid,
    }

    if request.name:
        update_data["name"] = request.name
        # Update Auth display name too
        try:
            auth.update_user(request.user_id, display_name=request.name)
        except Exception as e:
            print(f"Warning: Could not update auth display name: {e}")

    if request.status:
        update_data["status"] = request.status

    if request.provider_role:
        # Validate roles
        valid_roles = [role.value for role in ProviderRole]
        for role in request.provider_role:
            if role not in valid_roles:
                return None, f"Invalid role: {role}"
        update_data["providerRole"] = request.provider_role

    if request.profile:
        update_data["profile"] = request.profile

    # Update Firestore
    user_ref.update(update_data)
    
    # Get updated user data
    updated_doc = user_ref.get()
    updated_dict = updated_doc.to_dict()
    if updated_dict:
        updated_dict["id"] = updated_doc.id
        try:
            user = ProviderUser.from_dict(updated_dict)
            return user, None
        except Exception as e:
            return None, f"Error parsing updated user data: {str(e)}"
    
    return None, "Could not retrieve updated user data"


def create_client_user(
    db: FirestoreClient,
    request: CreateClientRequest,
    created_by_uid: str,
) -> tuple[Optional[ClientUser], Optional[str]]:
    """
    Create a new client (Firebase Auth + Firestore)
    Returns (user, error_message)
    """
    # Create Firebase Auth user
    try:
        auth_user = auth.create_user(
            email=request.email,
            password=request.password,
            display_name=request.name,
        )
    except auth.EmailAlreadyExistsError:
        return None, f"Email {request.email} already exists"
    except Exception as e:
        return None, f"Error creating auth user: {str(e)}"

    # Create Firestore client document
    now = datetime.now()
    client_data: dict[str, Any] = {
        "id": auth_user.uid,
        "email": request.email,
        "name": request.name,
        "type": "client",
        "organizationId": request.organization_id,
        "divisionId": request.division_id,
        "status": "active",
        "profile": {},
        "createdAt": now,
        "updatedAt": now,
        "createdBy": created_by_uid,
    }

    # Add optional profile fields
    if request.phone:
        client_data["profile"]["phone"] = request.phone
    if request.date_of_birth:
        client_data["profile"]["dateOfBirth"] = request.date_of_birth

    try:
        db.collection("users").document(auth_user.uid).set(client_data)
    except Exception as e:
        # Rollback: delete auth user if Firestore fails
        auth.delete_user(auth_user.uid)
        return None, f"Error creating Firestore document: {str(e)}"

    try:
        user = ClientUser.from_dict(client_data)
        return user, None
    except Exception as e:
        return None, f"Error parsing user data: {str(e)}"


def update_client_user(
    db: FirestoreClient,
    request: UpdateClientRequest,
    updated_by_uid: str,
) -> tuple[Optional[ClientUser], Optional[str]]:
    """
    Update client data in Firestore
    Returns (updated_user, error_message)
    """
    # Check user exists and is client
    user_ref = db.collection("users").document(request.user_id)
    user_doc = user_ref.get()

    if not user_doc.exists:
        return None, f"User {request.user_id} not found"

    user_data = user_doc.to_dict()
    if (user_data or {}).get("type") != "client":
        return None, f"User {request.user_id} is not a client"

    # Build update data
    update_data: dict[str, Any] = {
        "updatedAt": datetime.now(),
        "updatedBy": updated_by_uid,
    }

    if request.name:
        update_data["name"] = request.name
        # Update Auth display name too
        try:
            auth.update_user(request.user_id, display_name=request.name)
        except Exception as e:
            print(f"Warning: Could not update auth display name: {e}")

    if request.status:
        update_data["status"] = request.status

    if request.profile:
        update_data["profile"] = request.profile

    # Update Firestore
    user_ref.update(update_data)
    
    # Get updated user data
    updated_doc = user_ref.get()
    updated_dict = updated_doc.to_dict()
    if updated_dict:
        updated_dict["id"] = updated_doc.id
        try:
            user = ClientUser.from_dict(updated_dict)
            return user, None
        except Exception as e:
            return None, f"Error parsing updated user data: {str(e)}"
    
    return None, "Could not retrieve updated user data"


def get_users_list(
    db: FirestoreClient, request: GetUsersRequest
) -> tuple[list[User], Optional[str]]:
    """
    Get users (providers and clients) with Auth metadata
    Returns (users_list, error_message)
    """
    # Build Firestore query
    users_ref = db.collection("users")

    # Filter by specific IDs
    if request.user_ids:
        if len(request.user_ids) > 10:
            return [], "Cannot filter by more than 10 user IDs at once"
        query = users_ref.where("id", "in", request.user_ids)
    else:
        query = users_ref.order_by(
            "createdAt", direction=firestore.firestore.Query.DESCENDING
        ).limit(request.limit)

        # Apply filters
        if request.organization_id:
            query = query.where("organizationId", "==", request.organization_id)

        if request.division_id:
            query = query.where("divisionId", "==", request.division_id)

        if request.user_type:
            query = query.where("type", "==", request.user_type.value)

        if request.status:
            query = query.where("status", "==", request.status.value)
        elif not request.include_deleted:
            # Exclude deleted users by default
            query = query.where("status", "!=", "deleted")

    # Execute query
    docs = query.stream()
    users_list = []

    for doc in docs:
        user_dict = doc.to_dict()
        if not user_dict:
            continue

        user_dict["id"] = doc.id

        # Get Auth metadata (lastSignIn)
        try:
            auth_user = auth.get_user(doc.id)
            last_sign_in = None
            if auth_user.user_metadata.last_sign_in_timestamp:
                last_sign_in = datetime.fromtimestamp(
                    auth_user.user_metadata.last_sign_in_timestamp / 1000
                )

            user_dict["lastSignIn"] = last_sign_in
        except Exception as e:
            print(f"Warning: Could not get auth metadata for {doc.id}: {e}")
            user_dict["lastSignIn"] = None

        try:
            user = user_from_dict(user_dict)
            users_list.append(user)
        except Exception as e:
            print(f"Warning: Could not parse user {doc.id}: {e}")
            continue

    return users_list, None


def get_user_by_id_data(
    db: FirestoreClient, user_id: str
) -> tuple[Optional[User], Optional[str]]:
    """
    Get single user by ID with Auth metadata
    Returns (user, error_message)
    """
    # Get from Firestore
    user_doc = db.collection("users").document(user_id).get()

    if not user_doc.exists:
        return None, f"User {user_id} not found"

    user_dict = user_doc.to_dict()
    if not user_dict:
        return None, f"User {user_id} data is empty"

    user_dict["id"] = user_doc.id

    # Get Auth metadata
    try:
        auth_user = auth.get_user(user_id)
        last_sign_in = None
        if auth_user.user_metadata.last_sign_in_timestamp:
            last_sign_in = datetime.fromtimestamp(
                auth_user.user_metadata.last_sign_in_timestamp / 1000
            )

        user_dict["lastSignIn"] = last_sign_in
    except Exception as e:
        print(f"Warning: Could not get auth metadata for {user_id}: {e}")
        user_dict["lastSignIn"] = None

    try:
        user = user_from_dict(user_dict)
        return user, None
    except Exception as e:
        return None, f"Error parsing user data: {str(e)}"


def get_user_statistics(
    db: FirestoreClient, organization_id: Optional[str] = None
) -> dict[str, int]:
    """
    Get user statistics (counts by type, status, etc.)
    Returns stats dictionary
    """
    # Build base query
    users_ref = db.collection("users")
    if organization_id:
        query = users_ref.where("organizationId", "==", organization_id)
    else:
        query = users_ref

    # Get all users
    users = list(query.stream())

    # Calculate stats
    stats = {
        "total": len(users),
        "providers": 0,
        "clients": 0,
        "active": 0,
        "inactive": 0,
        "pending": 0,
        "deleted": 0,
    }

    for user_doc in users:
        user_data = user_doc.to_dict()
        if not user_data:
            continue

        user_type = user_data.get("type")
        status = user_data.get("status")

        if user_type == "provider":
            stats["providers"] += 1
        elif user_type == "client":
            stats["clients"] += 1

        if status == "active":
            stats["active"] += 1
        elif status == "inactive":
            stats["inactive"] += 1
        elif status == "pending":
            stats["pending"] += 1
        elif status == "deleted":
            stats["deleted"] += 1

    return stats


def delete_user_account(
    db: FirestoreClient,
    request: DeleteUserRequest,
    deleted_by_uid: str,
) -> tuple[Optional[User], Optional[str]]:
    """
    Delete user (soft delete by default, hard delete removes from Auth)
    Returns (deleted_user, error_message)
    """
    # Check user exists
    user_ref = db.collection("users").document(request.user_id)
    user_doc = user_ref.get()

    if not user_doc.exists:
        return None, f"User {request.user_id} not found"

    user_dict = user_doc.to_dict()
    if not user_dict:
        return None, f"User {request.user_id} data is empty"
    
    user_dict["id"] = user_doc.id
    
    try:
        user = user_from_dict(user_dict)
    except Exception as e:
        return None, f"Error parsing user data: {str(e)}"

    if request.hard_delete:
        # Hard delete: Remove from Auth and Firestore
        try:
            auth.delete_user(request.user_id)
        except Exception as e:
            print(f"Warning: Could not delete auth user: {e}")

        user_ref.delete()
    else:
        # Soft delete: Mark as deleted in Firestore
        user_ref.update(
            {
                "status": "deleted",
                "deletedAt": datetime.now(),
                "deletedBy": deleted_by_uid,
            }
        )

    return user, None


def reset_user_password_link(user_id: str) -> tuple[str, Optional[str]]:
    """
    Generate password reset link for user
    Returns (reset_link, error_message)
    """
    # Get user email
    try:
        auth_user = auth.get_user(user_id)
    except auth.UserNotFoundError:
        return "", f"User {user_id} not found in Auth"

    # Generate password reset link
    try:
        reset_link = auth.generate_password_reset_link(auth_user.email)
        return reset_link, None
    except Exception as e:
        return "", f"Error generating reset link: {str(e)}"


def update_user_email_address(
    db: FirestoreClient,
    user_id: str,
    new_email: str,
    updated_by_uid: str,
) -> Optional[str]:
    """
    Update user email (updates both Auth and Firestore)
    Returns error_message or None on success
    """
    # Update Auth
    try:
        auth.update_user(user_id, email=new_email)
    except auth.EmailAlreadyExistsError:
        return f"Email {new_email} already exists"
    except auth.UserNotFoundError:
        return f"User {user_id} not found"

    # Update Firestore
    db.collection("users").document(user_id).update(
        {"email": new_email, "updatedAt": datetime.now(), "updatedBy": updated_by_uid}
    )

    return None

