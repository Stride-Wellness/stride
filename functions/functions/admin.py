from google.cloud.firestore_v1.client import Client as FirestoreClient
from firebase_admin import auth
from datetime import datetime
from typing import Optional, Any
import logging
from models.admin import (
    Admin,
    CreateAdminRequest,
    GetAdminsRequest,
    UpdateAdminRequest,
    DeleteAdminRequest,
)

logger = logging.getLogger(__name__)


def create_admin_user(
    db: FirestoreClient,
    request: CreateAdminRequest,
    created_by_uid: str,
    created_by_admin: Admin,
) -> tuple[Optional[Admin], Optional[str]]:
    """
    Create a new admin user (Firebase Auth + Firestore)
    Returns (admin, error_message)
    """
    logger.info(
        f"Creating admin user: {request.name} ({request.email}), privilege: {request.privilege.name}"
    )

    # Check privilege level
    if request.privilege.value <= created_by_admin.privilege.value:
        logger.warning(
            f"Insufficient privilege to create admin. Creator: {created_by_admin.privilege.name}, Requested: {request.privilege.name}"
        )
        return None, f"Cannot create admin with equal or higher privilege. Your level: {created_by_admin.privilege.name}, Requested: {request.privilege.name}"

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

    # Create Firestore admin document
    now = datetime.now()
    admin_data = {
        "id": auth_user.uid,
        "name": request.name,
        "privilege": request.privilege.value,
        "createdAt": now,
        "createdBy": created_by_uid,
        "updatedAt": now,
    }

    try:
        db.collection("admins").document(auth_user.uid).set(admin_data)
    except Exception as e:
        # Rollback: delete auth user if Firestore fails
        auth.delete_user(auth_user.uid)
        return None, f"Error creating Firestore document: {str(e)}"

    logger.info(f"Admin created successfully: {auth_user.uid}")
    return Admin.from_dict(admin_data), None


def update_admin_user(
    db: FirestoreClient,
    request: UpdateAdminRequest,
    updated_by_admin: Admin,
) -> tuple[Optional[Admin], Optional[str]]:
    """
    Update admin data in Firestore
    Returns (updated_admin, error_message)
    """
    logger.info(f"Updating admin: {request.user_id}")

    # Check if there are any updates
    if not request.has_updates():
        return None, "No fields to update"

    # Check target admin exists
    admin_ref = db.collection("admins").document(request.user_id)
    admin_doc = admin_ref.get()

    if not admin_doc.exists:
        return None, f"Admin {request.user_id} not found"

    target_admin_dict = admin_doc.to_dict()
    if not target_admin_dict:
        return None, f"Admin {request.user_id} data is empty"

    target_admin_dict["id"] = admin_doc.id
    target_admin = Admin.from_dict(target_admin_dict)

    # Cannot modify admins with equal or higher privilege
    if target_admin.privilege.value <= updated_by_admin.privilege.value:
        return None, f"Cannot modify admin with equal or higher privilege. Target: {target_admin.privilege.name}, Your level: {updated_by_admin.privilege.name}"

    # Build update data
    update_data: dict[str, Any] = {"updatedAt": datetime.now()}

    # Update name
    if request.name:
        update_data["name"] = request.name
        # Update Auth display name too
        try:
            auth.update_user(request.user_id, display_name=request.name)
        except Exception as e:
            print(f"Warning: Could not update auth display name: {e}")

    # Update privilege (with permission check)
    if request.privilege is not None:
        # Cannot elevate privilege to or above own level
        if request.privilege.value <= updated_by_admin.privilege.value:
            return None, f"Cannot set privilege equal to or higher than your own. Your level: {updated_by_admin.privilege.name}, Requested: {request.privilege.name}"

        update_data["privilege"] = request.privilege.value

    # Update Firestore
    admin_ref.update(update_data)

    # Get updated admin data
    updated_doc = admin_ref.get()
    updated_dict = updated_doc.to_dict()
    if updated_dict:
        updated_dict["id"] = updated_doc.id
        logger.info(f"Admin updated successfully: {request.user_id}")
        return Admin.from_dict(updated_dict), None

    return None, "Could not retrieve updated admin data"


def delete_admin_user(
    db: FirestoreClient,
    user_id: str,
    deleted_by_uid: str,
    deleted_by_admin: Admin,
) -> tuple[Optional[Admin], Optional[str]]:
    """
    Delete admin (hard delete - removes from Auth and Firestore)
    Returns (deleted_admin, error_message)
    """
    logger.info(f"Deleting admin: {user_id}")

    # Cannot delete yourself
    if user_id == deleted_by_uid:
        logger.warning(f"Attempted to delete self: {user_id}")
        return None, "Cannot delete yourself"

    # Check target admin exists
    admin_ref = db.collection("admins").document(user_id)
    admin_doc = admin_ref.get()

    if not admin_doc.exists:
        return None, f"Admin {user_id} not found"

    target_admin_dict = admin_doc.to_dict()
    if not target_admin_dict:
        return None, f"Admin {user_id} data is empty"

    target_admin_dict["id"] = admin_doc.id
    target_admin = Admin.from_dict(target_admin_dict)

    # Cannot delete admins with equal or higher privilege
    if target_admin.privilege.value <= deleted_by_admin.privilege.value:
        return None, f"Cannot delete admin with equal or higher privilege. Target: {target_admin.privilege.name}, Your level: {deleted_by_admin.privilege.name}"

    # Hard delete: Remove from Auth and Firestore
    try:
        auth.delete_user(user_id)
    except Exception as e:
        print(f"Warning: Could not delete auth user: {e}")

    admin_ref.delete()
    logger.info(f"Admin permanently deleted: {user_id}")
    return target_admin, None


def get_admins_list(
    db: FirestoreClient, request: GetAdminsRequest
) -> tuple[list[Admin], Optional[str]]:
    """
    Get admin users with Auth metadata
    Returns (admins_list, error_message)
    """
    logger.info(
        f"Fetching admins list, privilege filter: {request.privilege_level}, limit: {request.limit}"
    )

    # Build Firestore query
    admins_ref = db.collection("admins")

    # Filter by specific IDs
    if request.user_ids:
        if len(request.user_ids) > 10:
            return [], "Cannot filter by more than 10 user IDs at once"
        query = admins_ref.where("id", "in", request.user_ids)
    else:
        from firebase_admin import firestore

        query = admins_ref.order_by(
            "createdAt", direction=firestore.firestore.Query.DESCENDING
        ).limit(request.limit)

        # Filter by privilege level
        if request.privilege_level is not None:
            query = query.where("privilege", "==", request.privilege_level.value)

    # Execute query
    docs = query.stream()
    admins_list = []

    for doc in docs:
        admin_dict = doc.to_dict()
        if not admin_dict:
            continue

        admin_dict["id"] = doc.id

        # Get Auth metadata (lastSignIn)
        try:
            auth_user = auth.get_user(doc.id)
            last_sign_in = None
            if auth_user.user_metadata.last_sign_in_timestamp:
                last_sign_in = datetime.fromtimestamp(
                    auth_user.user_metadata.last_sign_in_timestamp / 1000
                )

            admin_dict["lastSignIn"] = last_sign_in
        except Exception as e:
            print(f"Warning: Could not get auth metadata for {doc.id}: {e}")
            admin_dict["lastSignIn"] = None

        try:
            admin = Admin.from_dict(admin_dict)
            admins_list.append(admin)
        except Exception as e:
            print(f"Warning: Could not parse admin {doc.id}: {e}")
            continue

    logger.info(f"Successfully fetched {len(admins_list)} admins")
    return admins_list, None


def get_admin_by_id_data(
    db: FirestoreClient, user_id: str
) -> tuple[Optional[Admin], Optional[str]]:
    """
    Get single admin by ID with Auth metadata
    Returns (admin, error_message)
    """
    logger.debug(f"Fetching admin by ID: {user_id}")

    # Get from Firestore
    admin_doc = db.collection("admins").document(user_id).get()

    if not admin_doc.exists:
        return None, f"Admin {user_id} not found"

    admin_dict = admin_doc.to_dict()
    if not admin_dict:
        return None, f"Admin {user_id} data is empty"

    admin_dict["id"] = admin_doc.id

    # Get Auth metadata
    try:
        auth_user = auth.get_user(user_id)
        last_sign_in = None
        if auth_user.user_metadata.last_sign_in_timestamp:
            last_sign_in = datetime.fromtimestamp(
                auth_user.user_metadata.last_sign_in_timestamp / 1000
            )

        admin_dict["lastSignIn"] = last_sign_in
    except Exception as e:
        print(f"Warning: Could not get auth metadata for {user_id}: {e}")
        admin_dict["lastSignIn"] = None

    try:
        admin = Admin.from_dict(admin_dict)
        logger.debug(f"Successfully fetched admin: {user_id}")
        return admin, None
    except Exception as e:
        return None, f"Error parsing admin data: {str(e)}"
