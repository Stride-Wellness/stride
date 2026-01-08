from google.cloud.firestore_v1.client import Client as FirestoreClient
from google.cloud.firestore_v1 import DocumentReference
from firebase_admin import auth, firestore
from datetime import datetime
from typing import Any, Optional, Iterable

from utils.logger import Logger
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
    user_from_dict,
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
    Logger.info(
        "Creating provider user",
        f"Creating provider {request.name} ({request.email}) created by {created_by_uid}",
        {
            "providerName": request.name,
            "providerEmail": request.email,
            "createdBy": created_by_uid,
        },
    )

    # Validate provider roles
    if not request.provider_role:
        Logger.error("Provider creation failed", "No roles specified for provider")
        return None, "Provider must have at least one role"

    # Validate role values
    valid_roles = [role.value for role in ProviderRole]
    for role in request.provider_role:
        if role not in valid_roles:
            Logger.error(
                "Invalid role specified",
                f"Role {role} is not valid. Valid roles: {valid_roles}",
                {"role": role, "validRoles": valid_roles},
            )
            return None, f"Invalid role: {role}. Valid roles: {valid_roles}"

    # Create Firebase Auth user
    try:
        Logger.debug(
            "Creating Firebase Auth user",
            f"Creating Firebase Auth user for {request.email}",
        )
        auth_user = auth.create_user(
            email=request.email,
            password=request.password,
            display_name=request.name,
        )
        Logger.info(
            "Firebase Auth user created",
            f"Firebase Auth user {auth_user.uid} created",
            {"userId": auth_user.uid},
        )
    except auth.EmailAlreadyExistsError:
        Logger.warning(
            "Email already exists",
            f"Email {request.email} already exists",
            {"email": request.email},
        )
        return None, f"Email {request.email} already exists"
    except Exception as e:
        Logger.error(
            "Error creating auth user",
            f"Error creating auth user: {str(e)}",
            {"error": str(e)},
        )
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
        Logger.debug(
            "Saving provider to Firestore",
            f"Saving provider {auth_user.uid} to Firestore",
        )
        db.collection("users").document(auth_user.uid).set(provider_data)
        Logger.info(
            "Provider Firestore document created",
            f"Provider Firestore document created for {auth_user.uid}",
            {"userId": auth_user.uid},
        )
    except Exception as e:
        Logger.error(
            "Firestore save failed, rolling back",
            f"Firestore save failed for {auth_user.uid}, rolling back Auth user: {str(e)}",
            {"userId": auth_user.uid, "error": str(e)},
        )
        auth.delete_user(auth_user.uid)
        return None, f"Error creating Firestore document: {str(e)}"

    try:
        user = ProviderUser.from_dict(provider_data)
        Logger.info(
            "Provider user created successfully",
            f"Provider user {user.id} created successfully",
            {"userId": user.id},
        )
        return user, None
    except Exception as e:
        Logger.error(
            "Error parsing provider data",
            f"Error parsing provider data: {str(e)}",
            {"error": str(e)},
        )
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
    Logger.info(
        "Updating provider",
        f"Updating provider {request.user_id} by {updated_by_uid}",
        {"userId": request.user_id, "updatedBy": updated_by_uid},
    )

    # Check user exists and is provider
    user_ref = db.collection("users").document(request.user_id)
    user_doc = user_ref.get()

    if not user_doc.exists:
        Logger.warning(
            "Provider not found",
            f"Provider {request.user_id} not found",
            {"userId": request.user_id},
        )
        return None, f"User {request.user_id} not found"

    user_data = user_doc.to_dict()

    if (user_data or {}).get("type") != "provider":
        Logger.error(
            "User is not a provider",
            f"User {request.user_id} is not a provider",
            {"userId": request.user_id},
        )
        return None, f"User {request.user_id} is not an provider"

    # Build update data
    update_data: dict[str, Any] = {
        "updatedAt": datetime.now(),
        "updatedBy": updated_by_uid,
    }

    if request.name:
        update_data["name"] = request.name
        Logger.debug(
            "Updating provider name",
            f"Updating provider name to {request.name}",
            {"name": request.name},
        )
        # Update Auth display name too
        try:
            auth.update_user(request.user_id, display_name=request.name)
        except Exception as e:
            Logger.warning(
                "Auth display name update failed",
                f"Could not update auth display name: {e}",
            )

    if request.status:
        update_data["status"] = request.status
        Logger.debug(
            "Updating provider status",
            f"Updating provider status to {request.status}",
            {"status": request.status},
        )

    if request.provider_role:
        # Validate roles
        valid_roles = [role.value for role in ProviderRole]
        for role in request.provider_role:
            if role not in valid_roles:
                Logger.error(
                    "Invalid role in update",
                    f"Invalid role {role} in update",
                    {"role": role},
                )
                return None, f"Invalid role: {role}"
        update_data["providerRole"] = request.provider_role
        Logger.debug(
            "Updating provider roles",
            f"Updating provider roles to {request.provider_role}",
            {"roles": request.provider_role},
        )

    if request.profile:
        update_data["profile"] = request.profile
        Logger.debug("Updating provider profile", "Updating provider profile")

    # Update Firestore
    Logger.debug(
        "Saving provider updates to Firestore",
        f"Saving provider {request.user_id} updates to Firestore",
    )
    user_ref.update(update_data)

    # Get updated user data
    updated_doc = user_ref.get()
    updated_dict = updated_doc.to_dict()
    if updated_dict:
        updated_dict["id"] = updated_doc.id
        try:
            user = ProviderUser.from_dict(updated_dict)
            Logger.info(
                "Provider updated successfully",
                f"Provider {request.user_id} updated successfully",
                {"userId": request.user_id},
            )
            return user, None
        except Exception as e:
            Logger.error(
                "Error parsing updated provider data",
                f"Error parsing updated provider data: {str(e)}",
                {"userId": request.user_id, "error": str(e)},
            )
            return None, f"Error parsing updated user data: {str(e)}"

    Logger.error(
        "Could not retrieve updated provider data",
        f"Could not retrieve updated provider data for {request.user_id}",
        {"userId": request.user_id},
    )
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
    Logger.info(
        "Creating client user",
        f"Creating client user: {request.name} ({request.email})",
        {
            "clientName": request.name,
            "clientEmail": request.email,
            "createdBy": created_by_uid,
        },
    )

    # Create Firebase Auth user
    try:
        Logger.debug(
            "Creating Firebase Auth user",
            f"Creating Firebase Auth user for {request.email}",
        )
        auth_user = auth.create_user(
            email=request.email,
            password=request.password,
            display_name=request.name,
        )
        Logger.info(
            "Firebase Auth user created",
            f"Firebase Auth user created: {auth_user.uid}",
            {"userId": auth_user.uid},
        )
    except auth.EmailAlreadyExistsError:
        Logger.warning(
            "Email already exists",
            f"Email already exists: {request.email}",
            {"email": request.email},
        )
        return None, f"Email {request.email} already exists"
    except Exception as e:
        Logger.error(
            "Error creating auth user",
            f"Error creating auth user: {str(e)}",
            {"error": str(e)},
        )
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
        Logger.debug("Added phone to profile", "Added phone to client profile")
    if request.date_of_birth:
        client_data["profile"]["dateOfBirth"] = request.date_of_birth
        Logger.debug(
            "Added date of birth to profile", "Added date of birth to client profile"
        )

    try:
        Logger.debug(
            "Saving client to Firestore", f"Saving client to Firestore: {auth_user.uid}"
        )
        db.collection("users").document(auth_user.uid).set(client_data)
        Logger.info(
            "Client Firestore document created",
            f"Client Firestore document created: {auth_user.uid}",
            {"userId": auth_user.uid},
        )
    except Exception as e:
        # Rollback: delete auth user if Firestore fails
        Logger.error(
            "Firestore save failed, rolling back",
            f"Firestore save failed, rolling back Auth user: {str(e)}",
            {"userId": auth_user.uid, "error": str(e)},
        )
        auth.delete_user(auth_user.uid)
        return None, f"Error creating Firestore document: {str(e)}"

    try:
        user = ClientUser.from_dict(client_data)
        Logger.info(
            "Client user created successfully",
            f"Client user created successfully: {user.id}",
            {"userId": user.id},
        )
        return user, None
    except Exception as e:
        Logger.error(
            "Error parsing client data",
            f"Error parsing client data: {str(e)}",
            {"error": str(e)},
        )
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
    Logger.info(
        "Updating client",
        f"Updating client: {request.user_id}",
        {"userId": request.user_id, "updatedBy": updated_by_uid},
    )

    # Check user exists and is client
    user_ref = db.collection("users").document(request.user_id)
    user_doc = user_ref.get()

    if not user_doc.exists:
        Logger.warning(
            "Client not found",
            f"Client not found: {request.user_id}",
            {"userId": request.user_id},
        )
        return None, f"User {request.user_id} not found"

    user_data = user_doc.to_dict()
    if (user_data or {}).get("type") != "client":
        Logger.error(
            "User is not a client",
            f"User {request.user_id} is not a client",
            {"userId": request.user_id},
        )
        return None, f"User {request.user_id} is not a client"

    # Build update data
    update_data: dict[str, Any] = {
        "updatedAt": datetime.now(),
        "updatedBy": updated_by_uid,
    }

    if request.name:
        update_data["name"] = request.name
        Logger.debug(
            "Updating client name",
            f"Updating client name to: {request.name}",
            {"name": request.name},
        )
        # Update Auth display name too
        try:
            auth.update_user(request.user_id, display_name=request.name)
        except Exception as e:
            Logger.warning(
                "Auth display name update failed",
                f"Could not update auth display name: {e}",
            )

    if request.status:
        update_data["status"] = request.status
        Logger.debug(
            "Updating client status", f"Updating client status to: {request.status}"
        )

    if request.profile:
        update_data["profile"] = request.profile
        Logger.debug("Updating client profile", "Updating client profile data")

    # Update Firestore
    Logger.debug(
        "Saving client updates to Firestore",
        f"Saving client updates to Firestore: {request.user_id}",
    )
    user_ref.update(update_data)

    # Get updated user data
    updated_doc = user_ref.get()
    updated_dict = updated_doc.to_dict()
    if updated_dict:
        updated_dict["id"] = updated_doc.id
        try:
            user = ClientUser.from_dict(updated_dict)
            Logger.info(
                "Client updated successfully",
                f"Client updated successfully: {request.user_id}",
                {"userId": request.user_id},
            )
            return user, None
        except Exception as e:
            Logger.error(
                "Error parsing updated client data",
                f"Error parsing updated client data: {str(e)}",
                {"error": str(e)},
            )
            return None, f"Error parsing updated user data: {str(e)}"

    Logger.error(
        "Could not retrieve updated client data",
        f"Could not retrieve updated client data: {request.user_id}",
    )
    return None, "Could not retrieve updated user data"


def get_users_list(
    db: FirestoreClient, request: GetUsersRequest
) -> tuple[list[User], Optional[str]]:
    """
    Get users (providers and clients) with Auth metadata
    Returns (users_list, error_message)
    """
    Logger.info(
        "Fetching users list",
        "Fetching users list with filters",
        {
            "userType": request.user_type.value if request.user_type else None,
            "status": request.status.value if request.status else None,
            "limit": request.limit,
            "organizationId": request.organization_id,
        },
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
            Logger.warning(
                "Could not get auth metadata",
                f"Could not get auth metadata for {doc.id}",
                {"userId": doc.id, "error": str(e)},
            )
            user_dict["lastSignIn"] = None

        try:
            user = user_from_dict(user_dict)
            users_list.append(user)
        except Exception as e:
            Logger.warning(
                "Could not parse user",
                f"Could not parse user {doc.id}",
                {"userId": doc.id, "error": str(e)},
            )
            continue

    Logger.info(
        "Successfully fetched users",
        f"Successfully fetched {len(users_list)} users",
        {"count": len(users_list)},
    )
    return users_list, None


def get_user_by_id_data(
    db: FirestoreClient, user_id: str
) -> tuple[Optional[User], Optional[str]]:
    """
    Get single user by ID with Auth metadata
    Returns (user, error_message)
    """
    Logger.debug("Fetching user by ID", f"Fetching user {user_id}", {"userId": user_id})

    # Get from Firestore
    user_doc = db.collection("users").document(user_id).get()

    if not user_doc.exists:
        Logger.warning(
            "User not found", f"User {user_id} not found", {"userId": user_id}
        )
        return None, f"User {user_id} not found"

    user_dict = user_doc.to_dict()
    if not user_dict:
        Logger.warning(
            "User data is empty",
            f"User data is empty for {user_id}",
            {"userId": user_id},
        )
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
        Logger.warning(
            "Could not get auth metadata",
            f"Could not get auth metadata for {user_id}",
            {"userId": user_id, "error": str(e)},
        )
        user_dict["lastSignIn"] = None

    try:
        user = user_from_dict(user_dict)
        Logger.info(
            "Successfully fetched user",
            f"Successfully fetched user {user_id}",
            {"userId": user_id},
        )
        return user, None
    except Exception as e:
        Logger.error(
            "Error parsing user data",
            f"Error parsing user data for {user_id}",
            {"userId": user_id, "error": str(e)},
        )
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


def _delete_collection_batch(refs: Iterable[DocumentReference]) -> None:
    """Delete a batch of document references."""
    batch = firestore.client().batch()
    count = 0
    for doc_ref in refs:
        batch.delete(doc_ref)
        count += 1
        # Firestore batches are limited to 500 operations
        if count == 450:
            batch.commit()
            batch = firestore.client().batch()
            count = 0

    if count:
        batch.commit()


def _delete_user_subcollections(db: FirestoreClient, user_ref: DocumentReference) -> None:
    """Delete known subcollections for a user (e.g., quiz_results)."""
    try:
        quiz_results_ref = user_ref.collection("quiz_results")
        quiz_results = list(quiz_results_ref.stream())
        if quiz_results:
            _delete_collection_batch(doc.reference for doc in quiz_results)
            Logger.debug(
                "Deleted quiz_results subcollection",
                f"Deleted {len(quiz_results)} quiz_results for {user_ref.id}",
                {"userId": user_ref.id},
            )
    except Exception as e:
        Logger.warning(
            "Failed to delete subcollections",
            f"Could not delete subcollections for {user_ref.id}: {e}",
            {"userId": user_ref.id, "error": str(e)},
        )


def delete_user_account(
    db: FirestoreClient,
    request: DeleteUserRequest,
    deleted_by_uid: str,
) -> tuple[Optional[User], Optional[str]]:
    """
    Delete user (soft delete by default, hard delete removes from Auth)
    Returns (deleted_user, error_message)
    """
    Logger.info(
        "Deleting user",
        f"Deleting user {request.user_id} (hard={request.hard_delete})",
        {
            "userId": request.user_id,
            "hardDelete": request.hard_delete,
            "deletedBy": deleted_by_uid,
        },
    )

    # Check user exists
    user_ref = db.collection("users").document(request.user_id)
    user_doc = user_ref.get()

    if not user_doc.exists:
        Logger.warning(
            "User not found",
            f"User {request.user_id} not found",
            {"userId": request.user_id},
        )
        return None, f"User {request.user_id} not found"

    user_dict = user_doc.to_dict()
    if not user_dict:
        Logger.warning(
            "User data is empty",
            f"User data is empty for {request.user_id}",
            {"userId": request.user_id},
        )
        return None, f"User {request.user_id} data is empty"

    user_dict["id"] = user_doc.id

    try:
        user = user_from_dict(user_dict)
    except Exception as e:
        Logger.error(
            "Error parsing user data",
            f"Error parsing user data: {str(e)}",
            {"error": str(e)},
        )
        return None, f"Error parsing user data: {str(e)}"

    if request.hard_delete:
        Logger.info(
            "Hard deleting user",
            f"Hard deleting user {request.user_id}",
            {"userId": request.user_id},
        )
        # Hard delete: Remove from Auth and Firestore
        try:
            auth.delete_user(request.user_id)
            Logger.debug(
                "Deleted from Firebase Auth",
                f"Deleted user {request.user_id} from Firebase Auth",
                {"userId": request.user_id},
            )
        except Exception as e:
            Logger.warning(
                "Could not delete auth user",
                f"Could not delete auth user {request.user_id}",
                {"userId": request.user_id, "error": str(e)},
            )

        # Remove known subcollections (e.g., quiz_results) so the document fully disappears
        _delete_user_subcollections(db, user_ref)

        user_ref.delete()
        Logger.info(
            "User permanently deleted",
            f"User {request.user_id} permanently deleted",
            {"userId": request.user_id},
        )
    else:
        Logger.info(
            "Soft deleting user",
            f"Soft deleting user {request.user_id}",
            {"userId": request.user_id},
        )
        user_ref.update(
            {
                "status": "deleted",
                "deletedAt": datetime.now(),
                "deletedBy": deleted_by_uid,
            }
        )
        Logger.info(
            "User soft deleted",
            f"User {request.user_id} soft deleted",
            {"userId": request.user_id},
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
