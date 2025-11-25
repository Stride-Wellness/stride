from google.cloud.firestore_v1.client import Client as FirestoreClient
from firebase_admin import auth, firestore
from datetime import datetime
from typing import Any, Optional
import logging

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

logger = logging.getLogger(__name__)


def create_provider_user(
    db: FirestoreClient,
    request: CreateProviderRequest,
    created_by_uid: str,
) -> tuple[Optional[ProviderUser], Optional[str]]:
    """
    Create a new provider (Firebase Auth + Firestore)
    Returns (user, error_message)
    """
    logger.info(f"Creating provider user: {request.name} ({request.email})")

    # Validate provider roles
    if not request.provider_role:
        logger.error("Provider creation failed: no roles specified")
        return None, "Provider must have at least one role"

    # Validate role values
    valid_roles = [role.value for role in ProviderRole]
    for role in request.provider_role:
        if role not in valid_roles:
            logger.error(f"Invalid role specified: {role}")
            return None, f"Invalid role: {role}. Valid roles: {valid_roles}"

    # Create Firebase Auth user
    try:
        logger.debug(f"Creating Firebase Auth user for {request.email}")
        auth_user = auth.create_user(
            email=request.email,
            password=request.password,
            display_name=request.name,
        )
        logger.info(f"Firebase Auth user created: {auth_user.uid}")
    except auth.EmailAlreadyExistsError:
        logger.warning(f"Email already exists: {request.email}")
        return None, f"Email {request.email} already exists"
    except Exception as e:
        logger.error(f"Error creating auth user: {str(e)}", exc_info=True)
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
        logger.debug(f"Saving provider to Firestore: {auth_user.uid}")
        db.collection("users").document(auth_user.uid).set(provider_data)
        logger.info(f"Provider Firestore document created: {auth_user.uid}")
    except Exception as e:
        # Rollback: delete auth user if Firestore fails
        logger.error(
            f"Firestore save failed, rolling back Auth user: {str(e)}", exc_info=True
        )
        auth.delete_user(auth_user.uid)
        return None, f"Error creating Firestore document: {str(e)}"

    try:
        user = ProviderUser.from_dict(provider_data)
        logger.info(f"Provider user created successfully: {user.id}")
        return user, None
    except Exception as e:
        logger.error(f"Error parsing provider data: {str(e)}", exc_info=True)
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
    logger.info(f"Updating provider: {request.user_id}")

    # Check user exists and is provider
    user_ref = db.collection("users").document(request.user_id)
    user_doc = user_ref.get()

    if not user_doc.exists:
        logger.warning(f"Provider not found: {request.user_id}")
        return None, f"User {request.user_id} not found"

    user_data = user_doc.to_dict()

    if (user_data or {}).get("type") != "provider":
        logger.error(f"User {request.user_id} is not a provider")
        return None, f"User {request.user_id} is not an provider"

    # Build update data
    update_data: dict[str, Any] = {
        "updatedAt": datetime.now(),
        "updatedBy": updated_by_uid,
    }

    if request.name:
        update_data["name"] = request.name
        logger.debug(f"Updating provider name to: {request.name}")
        # Update Auth display name too
        try:
            auth.update_user(request.user_id, display_name=request.name)
        except Exception as e:
            logger.warning(f"Could not update auth display name: {e}")

    if request.status:
        update_data["status"] = request.status
        logger.debug(f"Updating provider status to: {request.status}")

    if request.provider_role:
        # Validate roles
        valid_roles = [role.value for role in ProviderRole]
        for role in request.provider_role:
            if role not in valid_roles:
                logger.error(f"Invalid role in update: {role}")
                return None, f"Invalid role: {role}"
        update_data["providerRole"] = request.provider_role
        logger.debug(f"Updating provider roles to: {request.provider_role}")

    if request.profile:
        update_data["profile"] = request.profile
        logger.debug("Updating provider profile")

    # Update Firestore
    logger.debug(f"Saving provider updates to Firestore: {request.user_id}")
    user_ref.update(update_data)

    # Get updated user data
    updated_doc = user_ref.get()
    updated_dict = updated_doc.to_dict()
    if updated_dict:
        updated_dict["id"] = updated_doc.id
        try:
            user = ProviderUser.from_dict(updated_dict)
            logger.info(f"Provider updated successfully: {request.user_id}")
            return user, None
        except Exception as e:
            logger.error(
                f"Error parsing updated provider data: {str(e)}", exc_info=True
            )
            return None, f"Error parsing updated user data: {str(e)}"

    logger.error(f"Could not retrieve updated provider data: {request.user_id}")
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
    logger.info(f"Creating client user: {request.name} ({request.email})")

    # Create Firebase Auth user
    try:
        logger.debug(f"Creating Firebase Auth user for {request.email}")
        auth_user = auth.create_user(
            email=request.email,
            password=request.password,
            display_name=request.name,
        )
        logger.info(f"Firebase Auth user created: {auth_user.uid}")
    except auth.EmailAlreadyExistsError:
        logger.warning(f"Email already exists: {request.email}")
        return None, f"Email {request.email} already exists"
    except Exception as e:
        logger.error(f"Error creating auth user: {str(e)}", exc_info=True)
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
        logger.debug(f"Added phone to client profile")
    if request.date_of_birth:
        client_data["profile"]["dateOfBirth"] = request.date_of_birth
        logger.debug(f"Added date of birth to client profile")

    try:
        logger.debug(f"Saving client to Firestore: {auth_user.uid}")
        db.collection("users").document(auth_user.uid).set(client_data)
        logger.info(f"Client Firestore document created: {auth_user.uid}")
    except Exception as e:
        # Rollback: delete auth user if Firestore fails
        logger.error(
            f"Firestore save failed, rolling back Auth user: {str(e)}", exc_info=True
        )
        auth.delete_user(auth_user.uid)
        return None, f"Error creating Firestore document: {str(e)}"

    try:
        user = ClientUser.from_dict(client_data)
        logger.info(f"Client user created successfully: {user.id}")
        return user, None
    except Exception as e:
        logger.error(f"Error parsing client data: {str(e)}", exc_info=True)
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
    logger.info(f"Updating client: {request.user_id}")

    # Check user exists and is client
    user_ref = db.collection("users").document(request.user_id)
    user_doc = user_ref.get()

    if not user_doc.exists:
        logger.warning(f"Client not found: {request.user_id}")
        return None, f"User {request.user_id} not found"

    user_data = user_doc.to_dict()
    if (user_data or {}).get("type") != "client":
        logger.error(f"User {request.user_id} is not a client")
        return None, f"User {request.user_id} is not a client"

    # Build update data
    update_data: dict[str, Any] = {
        "updatedAt": datetime.now(),
        "updatedBy": updated_by_uid,
    }

    if request.name:
        update_data["name"] = request.name
        logger.debug(f"Updating client name to: {request.name}")
        # Update Auth display name too
        try:
            auth.update_user(request.user_id, display_name=request.name)
        except Exception as e:
            logger.warning(f"Could not update auth display name: {e}")

    if request.status:
        update_data["status"] = request.status
        logger.debug(f"Updating client status to: {request.status}")

    if request.profile:
        update_data["profile"] = request.profile
        logger.debug("Updating client profile")

    # Update Firestore
    logger.debug(f"Saving client updates to Firestore: {request.user_id}")
    user_ref.update(update_data)

    # Get updated user data
    updated_doc = user_ref.get()
    updated_dict = updated_doc.to_dict()
    if updated_dict:
        updated_dict["id"] = updated_doc.id
        try:
            user = ClientUser.from_dict(updated_dict)
            logger.info(f"Client updated successfully: {request.user_id}")
            return user, None
        except Exception as e:
            logger.error(f"Error parsing updated client data: {str(e)}", exc_info=True)
            return None, f"Error parsing updated user data: {str(e)}"

    logger.error(f"Could not retrieve updated client data: {request.user_id}")
    return None, "Could not retrieve updated user data"


def get_users_list(
    db: FirestoreClient, request: GetUsersRequest
) -> tuple[list[User], Optional[str]]:
    """
    Get users (providers and clients) with Auth metadata
    Returns (users_list, error_message)
    """
    logger.info(
        f"Fetching users list with filters: type={request.user_type}, status={request.status}, limit={request.limit}"
    )

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
            logger.warning(f"Could not get auth metadata for {doc.id}: {e}")
            user_dict["lastSignIn"] = None

        try:
            user = user_from_dict(user_dict)
            users_list.append(user)
        except Exception as e:
            logger.warning(f"Could not parse user {doc.id}: {e}")
            continue

    logger.info(f"Successfully fetched {len(users_list)} users")
    return users_list, None


def get_user_by_id_data(
    db: FirestoreClient, user_id: str
) -> tuple[Optional[User], Optional[str]]:
    """
    Get single user by ID with Auth metadata
    Returns (user, error_message)
    """
    logger.debug(f"Fetching user by ID: {user_id}")

    # Get from Firestore
    user_doc = db.collection("users").document(user_id).get()

    if not user_doc.exists:
        logger.warning(f"User not found: {user_id}")
        return None, f"User {user_id} not found"

    user_dict = user_doc.to_dict()
    if not user_dict:
        logger.warning(f"User data is empty: {user_id}")
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
        logger.warning(f"Could not get auth metadata for {user_id}: {e}")
        user_dict["lastSignIn"] = None

    try:
        user = user_from_dict(user_dict)
        logger.info(f"Successfully fetched user: {user_id}")
        return user, None
    except Exception as e:
        logger.error(f"Error parsing user data: {str(e)}", exc_info=True)
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
    logger.info(f"Deleting user: {request.user_id}, hard_delete={request.hard_delete}")

    # Check user exists
    user_ref = db.collection("users").document(request.user_id)
    user_doc = user_ref.get()

    if not user_doc.exists:
        logger.warning(f"User not found: {request.user_id}")
        return None, f"User {request.user_id} not found"

    user_dict = user_doc.to_dict()
    if not user_dict:
        logger.warning(f"User data is empty: {request.user_id}")
        return None, f"User {request.user_id} data is empty"

    user_dict["id"] = user_doc.id

    try:
        user = user_from_dict(user_dict)
    except Exception as e:
        logger.error(f"Error parsing user data: {str(e)}", exc_info=True)
        return None, f"Error parsing user data: {str(e)}"

    if request.hard_delete:
        logger.info(f"Hard deleting user {request.user_id}")
        # Hard delete: Remove from Auth and Firestore
        try:
            auth.delete_user(request.user_id)
            logger.debug(f"Deleted from Firebase Auth: {request.user_id}")
        except Exception as e:
            logger.warning(f"Could not delete auth user: {e}")

        user_ref.delete()
        logger.info(f"User permanently deleted: {request.user_id}")
    else:
        logger.info(f"Soft deleting user {request.user_id}")
        # Soft delete: Mark as deleted in Firestore
        user_ref.update(
            {
                "status": "deleted",
                "deletedAt": datetime.now(),
                "deletedBy": deleted_by_uid,
            }
        )
        logger.info(f"User soft deleted: {request.user_id}")

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
