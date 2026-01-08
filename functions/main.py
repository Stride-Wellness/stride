import os
from firebase_functions import https_fn, options
from firebase_functions.options import set_global_options
from google.cloud.firestore_v1.client import Client as FirestoreClient
from firebase_admin import initialize_app, auth, firestore
from openai import OpenAI
from pydantic import BaseModel, ValidationError
from datetime import datetime
from typing import Any, Literal, Optional
from dotenv import load_dotenv
import traceback

from utils.logger import Logger

from models.admin import (
    Admin,
    CreateAdminRequest,
    GetAdminsRequest,
    UpdateAdminRequest,
    DeleteAdminRequest,
    AdminPrivilegeLevel,
)


from models.admin import Admin
from models.exercise import CreateExerciseRequest
from models.user import (
    CreateClientRequest,
    CreateProviderRequest,
    DeleteUserRequest,
    ProviderRole,
    GetUsersRequest,
    UpdateClientRequest,
    UpdateProviderRequest,
)

# Configure logging for Google Cloud Functions


set_global_options(
    max_instances=10,
)
initialize_app()
_db: FirestoreClient | None = None
_openai: OpenAI | None = None

# Configure CORS for your admin dashboard
# Allow localhost (any port) plus hosted domains for the admin dashboard.
cors_options = options.CorsOptions(
    cors_origins=[
        "*"
    ],  # Cloud Functions on_call already validate auth; allow any origin for dev ports
    cors_methods=["GET", "POST", "OPTIONS"],
)


# ============================================================================
# Helper Functions
# ============================================================================


def get_db():
    """Initialize Firestore DB if not already initialized"""
    global _db
    if _db is None:
        Logger.info("Initializing Firestore client", "Initializing Firestore client")
        _db = firestore.client()
        Logger.info("Firestore client initialized", "Firestore client initialized successfully")
    return _db


def get_openai():
    """Initialize OpenAI client if not already initialized"""
    global _openai
    if _openai is None:
        Logger.info("Initializing OpenAI client", "Initializing OpenAI client")
        load_dotenv()  # Load .env file
        api_key = os.environ.get("OPENAI_API_KEY")
        if not api_key:
            Logger.error("OPENAI_API_KEY not found", "OPENAI_API_KEY not found in environment variables")
        else:
            Logger.info("OpenAI API key found", "OpenAI API key found in environment variables")
        _openai = OpenAI(api_key=api_key)
        Logger.info("OpenAI client initialized", "OpenAI client initialized successfully")
    return _openai


def verify_admin(
    context: https_fn.CallableRequest,
) -> tuple[Admin | None, Optional[str]]:
    """Verify that the calling user is an admin"""

    Logger.info("Verifying admin access", "Verifying admin access for request")
    db = get_db()

    if not context.auth:
        Logger.warning("Authentication required", "User not authenticated but authentication required")
        return None, "User must be authenticated"

    try:
        user_uid = context.auth.uid
        Logger.info("Checking admin status", f"Checking admin status for user {user_uid}", {"userId": user_uid})

        # Get calling user from Firestore
        user_doc = db.collection("admins").document(user_uid).get()

        if not user_doc.exists:
            Logger.warning("User not found", f"User {user_uid} not found in admins collection", {"userId": user_uid})
            return None, "User not found"

        user_dict = user_doc.to_dict()

        if not user_dict:
            Logger.error("User document empty", f"User {user_uid} document exists but data is empty", {"userId": user_uid})
            return None, "User data is empty"

        user_dict["id"] = user_doc.id  # Ensure ID is set
        user_data = Admin.from_dict(user_dict)

        Logger.info(
            "Admin verified",
            f"Admin {user_uid} verified with privilege {user_data.privilege.name}",
            {"userId": user_uid, "privilege": user_data.privilege.name},
        )
        return user_data, None

    except Exception as e:
        Logger.error(
            "Error verifying admin",
            f"Error verifying admin: {str(e)}",
            {
                "userId": context.auth.uid if context.auth else None,
                "error": str(e),
                "traceback": traceback.format_exc(),
            },
        )
        return None, f"Error verifying admin: {str(e)}"


# ============================================================================
# Provider CRUD Functions
# ============================================================================


from functions.admin import (
    create_admin_user,
    update_admin_user,
    delete_admin_user,
    get_admins_list,
    get_admin_by_id_data,
)
from functions.user import (
    create_provider_user,
    update_provider_user,
    create_client_user,
    update_client_user,
    get_users_list,
    get_user_by_id_data,
    get_user_statistics,
    delete_user_account,
    reset_user_password_link,
    update_user_email_address,
)
from functions.exercise import generate_exercise_plan_with_ai


@https_fn.on_call(cors=cors_options)
def create_provider(req: https_fn.CallableRequest) -> dict:
    """
    Create a new provider (Firebase Auth + Firestore)
    Only admins can call this
    """
    Logger.info("Function called", "create_provider function called")
    db = get_db()
    try:
        # Verify admin
        admin, error = verify_admin(req)

        if req.auth is None or admin is None or not admin.can_modify():
            Logger.warning(
                "Unauthorized attempt",
                "Unauthorized create_provider attempt",
                {
                    "hasAuth": req.auth is not None,
                    "hasAdmin": admin is not None,
                    "error": error,
                },
            )
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message=error or "User is not authorized",
            )

        # Validate request
        try:
            request = CreateProviderRequest.model_validate(req.data)
            Logger.info(
                "Creating provider",
                f"Creating provider {request.name} ({request.email})",
                {"providerName": request.name, "providerEmail": request.email},
            )
        except ValidationError as e:
            Logger.error("Invalid request", f"Invalid create_provider request: {str(e)}", {"error": str(e)})
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message=f"Invalid request: {str(e)}",
            )

        # Use extracted function
        user, error = create_provider_user(db, request, req.auth.uid)
        if error or user is None:
            Logger.error("Failed to create provider", f"Failed to create provider: {error}", {"error": error})
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INTERNAL,
                message=error or "Failed to create provider",
            )

        Logger.info("Provider created", f"Provider created successfully: {user.id}", {"userId": user.id})
        return {
            "success": True,
            "userId": user.id,
            "message": f"Provider {request.name} created successfully",
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        Logger.error(
            "Unexpected error",
            f"Unexpected error in create_provider: {str(e)}",
            {"error": str(e), "traceback": traceback.format_exc()},
        )
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Internal error: {str(e)}",
        )


@https_fn.on_call(cors=cors_options)
def update_provider(req: https_fn.CallableRequest) -> dict:
    """
    Update provider data in Firestore
    Only admins can call this
    """
    Logger.info("Function called", "update_provider function called")
    db = get_db()

    try:
        # Verify admin
        admin, error = verify_admin(req)
        if req.auth is None or admin is None or not admin.can_modify():
            Logger.warning("Unauthorized attempt", "Unauthorized update_provider attempt")
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message=error or "User is not authorized",
            )

        # Validate request
        try:
            request = UpdateProviderRequest.model_validate(req.data)
            Logger.info("Updating provider", f"Updating provider {request.user_id}", {"userId": request.user_id})
        except ValidationError as e:
            Logger.error("Invalid request", f"Invalid update_provider request: {str(e)}", {"error": str(e)})
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message=f"Invalid request: {str(e)}",
            )

        # Use extracted function
        user, error = update_provider_user(db, request, req.auth.uid)
        if error or user is None:
            Logger.error(
                "Failed to update provider",
                f"Failed to update provider {request.user_id}: {error}",
                {"userId": request.user_id, "error": error}
            )
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INTERNAL,
                message=error or "Failed to update provider",
            )

        Logger.info("Provider updated", f"Provider {request.user_id} updated successfully", {"userId": request.user_id})
        return {
            "success": True,
            "message": f"Provider {request.user_id} updated successfully",
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        Logger.error("Unexpected error", f"Unexpected error in update_provider: {str(e)}", {"error": str(e)})
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Internal error: {str(e)}",
        )


@https_fn.on_call(cors=cors_options)
def create_client(req: https_fn.CallableRequest) -> dict:
    """
    Create a new client (Firebase Auth + Firestore)
    Only admins can call this
    """
    Logger.info("Function called", "create_client function called")
    db = get_db()

    try:
        # Verify admin
        admin, error = verify_admin(req)
        if req.auth is None or admin is None or not admin.can_modify():
            Logger.warning("Unauthorized attempt", "Unauthorized create_client attempt")
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message=error or "User is not authorized",
            )

        # Validate request
        try:
            request = CreateClientRequest.model_validate(req.data)
            Logger.info(
                "Creating client",
                f"Creating client {request.name} ({request.email})",
                {"clientName": request.name, "clientEmail": request.email},
            )
        except ValidationError as e:
            Logger.error("Invalid request", f"Invalid create_client request: {str(e)}", {"error": str(e)})
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message=f"Invalid request: {str(e)}",
            )

        # Use extracted function
        user, error = create_client_user(db, request, req.auth.uid)
        if error or user is None:
            Logger.error("Failed to create client", f"Failed to create client: {error}", {"error": error})
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INTERNAL,
                message=error or "Failed to create client",
            )

        Logger.info("Client created", f"Client created successfully: {user.id}", {"userId": user.id})
        return {
            "success": True,
            "userId": user.id,
            "message": f"Client {request.name} created successfully",
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        Logger.error("Unexpected error", f"Unexpected error in create_client: {str(e)}", {"error": str(e)})
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Internal error: {str(e)}",
        )


@https_fn.on_call(cors=cors_options)
def update_client(req: https_fn.CallableRequest) -> dict:
    """
    Update client data in Firestore
    Only admins can call this
    """
    Logger.info("Function called", "update_client function called")
    db = get_db()
    try:
        # Verify admin
        admin, error = verify_admin(req)
        if req.auth is None or admin is None or not admin.can_modify():
            Logger.warning("Unauthorized attempt", "Unauthorized update_client attempt")
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message=error or "User is not authorized",
            )

        # Validate request
        try:
            request = UpdateClientRequest.model_validate(req.data)
            Logger.info("Updating client", f"Updating client {request.user_id}", {"userId": request.user_id})
        except ValidationError as e:
            Logger.error("Invalid request", f"Invalid update_client request: {str(e)}", {"error": str(e)})
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message=f"Invalid request: {str(e)}",
            )

        # Use extracted function
        user, error = update_client_user(db, request, req.auth.uid)
        if error or user is None:
            Logger.error(
                "Failed to update client",
                f"Failed to update client {request.user_id}: {error}",
                {"userId": request.user_id, "error": error}
            )
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INTERNAL,
                message=error or "Failed to update client",
            )

        Logger.info("Client updated", f"Client {request.user_id} updated successfully", {"userId": request.user_id})
        return {
            "success": True,
            "message": f"Client {request.user_id} updated successfully",
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        Logger.error("Unexpected error", f"Unexpected error in update_client: {str(e)}", {"error": str(e)})
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Internal error: {str(e)}",
        )


@https_fn.on_call(cors=cors_options)
def get_users(req: https_fn.CallableRequest) -> dict:
    """
    Get users (providers and clients) with Auth metadata
    Only admins can call this
    Supports filtering by IDs, organization, division, type, status, and limit
    """
    Logger.info("Function called", "get_users function called")
    db = get_db()

    try:
        # Verify admin
        admin, error = verify_admin(req)
        if req.auth is None or admin is None:
            Logger.warning("Unauthorized attempt", "Unauthorized get_users attempt")
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message=error or "User is not authorized",
            )

        # Validate request
        try:
            request = GetUsersRequest.model_validate(req.data or {})
            Logger.info(
                "Fetching users",
                f"Fetching users with filters: type={request.user_type.value if request.user_type else 'all'}, status={request.status.value if request.status else 'all'}, limit={request.limit}",
                {
                    "userType": request.user_type.value if request.user_type else None,
                    "status": request.status.value if request.status else None,
                    "limit": request.limit,
                },
            )
        except ValidationError as e:
            Logger.error("Invalid request", f"Invalid get_users request: {str(e)}", {"error": str(e)})
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message=f"Invalid request: {str(e)}",
            )

        # Use extracted function
        users, error = get_users_list(db, request)
        if error:
            Logger.error("Failed to fetch users", f"Failed to fetch users: {error}", {"error": error})
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INTERNAL,
                message=error,
            )

        Logger.info("Users fetched", f"Successfully fetched {len(users)} users", {"count": len(users)})
        return {
            "success": True,
            "users": [user.to_dict() for user in users],
            "count": len(users),
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        Logger.error("Unexpected error", f"Unexpected error in get_users: {str(e)}", {"error": str(e)})
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Internal error: {str(e)}",
        )


@https_fn.on_call(cors=cors_options)
def get_user_by_id(req: https_fn.CallableRequest) -> dict:
    """
    Get single user by ID with Auth metadata
    Only admins can call this
    Works for both providers and clients
    """
    Logger.info("Function called", "get_user_by_id function called")
    db = get_db()

    try:
        # Verify admin
        admin, error = verify_admin(req)
        if req.auth is None or admin is None:
            Logger.warning("Unauthorized attempt", "Unauthorized get_user_by_id attempt")
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message=error or "User is not authorized",
            )

        user_id = req.data.get("userId")
        if not user_id:
            Logger.error("Missing userId", "get_user_by_id called without userId")
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message="userId is required",
            )

        Logger.info("Fetching user", f"Fetching user {user_id}", {"userId": user_id})

        # Use extracted function
        user, error = get_user_by_id_data(db, user_id)
        if error or user is None:
            Logger.warning("User not found", f"User {user_id} not found: {error}", {"userId": user_id, "error": error})
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.NOT_FOUND,
                message=error or "User not found",
            )

        Logger.info("User fetched", f"Successfully fetched user {user_id}", {"userId": user_id})
        return {"success": True, "user": user.to_dict()}

    except https_fn.HttpsError:
        raise
    except Exception as e:
        Logger.error("Unexpected error", f"Unexpected error in get_user_by_id: {str(e)}", {"error": str(e)})
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Internal error: {str(e)}",
        )


@https_fn.on_call(cors=cors_options)
def get_user_stats(req: https_fn.CallableRequest) -> dict:
    """
    Get user statistics (counts by type, status, etc.)
    Only admins can call this
    """
    Logger.info("Function called", "get_user_stats function called")
    db = get_db()

    try:
        # Verify admin
        admin, error = verify_admin(req)
        if req.auth is None or admin is None:
            Logger.warning("Unauthorized attempt", "Unauthorized get_user_stats attempt")
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message=error or "User is not authorized",
            )

        organization_id = req.data.get("organizationId")
        Logger.info("Fetching user stats", f"Fetching user stats for organization: {organization_id or 'all'}", {"organizationId": organization_id or "all"})

        # Use extracted function
        stats = get_user_statistics(db, organization_id)

        Logger.info("User stats calculated", f"User stats calculated successfully", {"stats": stats})
        return {"success": True, "stats": stats}

    except https_fn.HttpsError:
        raise
    except Exception as e:
        Logger.error("Unexpected error", f"Unexpected error in get_user_stats: {str(e)}", {"error": str(e)})
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Internal error: {str(e)}",
        )


@https_fn.on_call(cors=cors_options)
def delete_user(req: https_fn.CallableRequest) -> dict:
    """
    Delete user (soft delete by default, hard delete removes from Auth)
    Only admins can call this
    """
    Logger.info("Function called", "delete_user function called")
    db = get_db()
    try:
        # Verify admin
        admin, error = verify_admin(req)
        if req.auth is None or admin is None or not admin.can_modify():
            Logger.warning("Unauthorized attempt", "Unauthorized delete_user attempt")
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message=error or "User is not authorized",
            )

        # Validate request
        try:
            request = DeleteUserRequest.model_validate(req.data)
            Logger.info(
                "Deleting user",
                f"Deleting user {request.user_id} (hard={request.hard_delete})",
                {"userId": request.user_id, "hardDelete": request.hard_delete},
            )
        except ValidationError as e:
            Logger.error("Invalid request", f"Invalid delete_user request: {str(e)}", {"error": str(e)})
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message=f"Invalid request: {str(e)}",
            )

        # Use extracted function
        user, error = delete_user_account(db, request, req.auth.uid)
        if error or user is None:
            Logger.error(
                "Failed to delete user",
                f"Failed to delete user {request.user_id}: {error}",
                {"userId": request.user_id, "error": error}
            )
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.NOT_FOUND,
                message=error or "User not found",
            )

        message = (
            f"User {request.user_id} permanently deleted"
            if request.hard_delete
            else f"User {request.user_id} soft deleted"
        )
        Logger.info(
            "User deleted",
            message,
            {"userId": request.user_id, "hardDelete": request.hard_delete},
        )

        return {"success": True, "message": message}

    except https_fn.HttpsError:
        raise
    except Exception as e:
        Logger.error("Unexpected error", f"Unexpected error in delete_user: {str(e)}", {"error": str(e)})
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Internal error: {str(e)}",
        )


@https_fn.on_call(cors=cors_options)
def create_admin(req: https_fn.CallableRequest) -> dict:
    """
    Create a new admin (Firebase Auth + Firestore)
    Only admins with sufficient privilege can call this
    Cannot create admins with equal or higher privilege than yourself
    """
    Logger.info("Function called", "create_admin function called")
    db = get_db()

    try:
        # Verify admin
        admin, error = verify_admin(req)
        if req.auth is None or admin is None or not admin.can_modify():
            Logger.warning("Unauthorized attempt", "Unauthorized create_admin attempt")
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message=error or "User is not authorized",
            )

        # Validate request data
        try:
            request = CreateAdminRequest.model_validate(req.data)
            Logger.info(
                "Creating admin",
                f"Creating admin {request.name} with privilege {request.privilege.name}",
                {"adminName": request.name, "privilege": request.privilege.name},
            )
        except ValidationError as e:
            Logger.error("Invalid request", f"Invalid create_admin request: {str(e)}", {"error": str(e)})
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message=f"Invalid request: {str(e)}",
            )

        # Use extracted function
        new_admin, error = create_admin_user(db, request, req.auth.uid, admin)
        if error or new_admin is None:
            Logger.error("Failed to create admin", f"Failed to create admin: {error}", {"error": error})
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message=error or "Failed to create admin",
            )

        Logger.info("Admin created", f"Admin {new_admin.id} created successfully", {"userId": new_admin.id})
        return {
            "success": True,
            "userId": new_admin.id,
            "message": f"Admin {request.name} created successfully with privilege level {request.privilege.name}",
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        Logger.error("Unexpected error", f"Unexpected error in create_admin: {str(e)}", {"error": str(e)})
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Internal error: {str(e)}",
        )


@https_fn.on_call(cors=cors_options)
def update_admin(req: https_fn.CallableRequest) -> dict:
    """
    Update admin data in Firestore
    Only admins can call this
    Cannot modify admins with equal or higher privilege
    Cannot elevate privilege to or above your own level
    """
    Logger.info("Function called", "update_admin function called")
    db = get_db()

    try:
        # Verify admin
        admin, error = verify_admin(req)
        if req.auth is None or admin is None or not admin.can_modify():
            Logger.warning("Unauthorized attempt", "Unauthorized update_admin attempt")
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message=error or "User is not authorized",
            )

        # Validate request
        try:
            request = UpdateAdminRequest.model_validate(req.data)
            Logger.info("Updating admin", f"Updating admin {request.user_id}", {"userId": request.user_id})
        except ValidationError as e:
            Logger.error("Invalid request", f"Invalid update_admin request: {str(e)}", {"error": str(e)})
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message=f"Invalid request: {str(e)}",
            )

        # Use extracted function
        updated_admin, error = update_admin_user(db, request, admin)
        if error or updated_admin is None:
            Logger.error(
                "Failed to update admin",
                f"Failed to update admin {request.user_id}: {error}",
                {"userId": request.user_id, "error": error}
            )
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message=error or "Failed to update admin",
            )

        Logger.info("Admin updated", f"Admin {request.user_id} updated successfully", {"userId": request.user_id})
        return {
            "success": True,
            "message": f"Admin {request.user_id} updated successfully",
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        Logger.error("Unexpected error", f"Unexpected error in update_admin: {str(e)}", {"error": str(e)})
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Internal error: {str(e)}",
        )


@https_fn.on_call(cors=cors_options)
def delete_admin(req: https_fn.CallableRequest) -> dict:
    """
    Delete admin (hard delete - removes from Auth and Firestore)
    Only admins with sufficient privilege can delete other admins
    Cannot delete yourself
    Cannot delete admins with equal or higher privilege
    """
    Logger.info("Function called", "delete_admin function called")
    db = get_db()

    try:
        # Verify admin
        admin, error = verify_admin(req)
        if req.auth is None or admin is None or not admin.can_modify():
            Logger.warning("Unauthorized attempt", "Unauthorized delete_admin attempt")
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message=error or "User is not authorized",
            )

        # Validate request
        try:
            request = DeleteAdminRequest.model_validate(req.data)
            Logger.info("Deleting admin", f"Deleting admin {request.user_id}", {"userId": request.user_id})
        except ValidationError as e:
            Logger.error("Invalid request", f"Invalid delete_admin request: {str(e)}", {"error": str(e)})
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message=f"Invalid request: {str(e)}",
            )

        # Use extracted function
        deleted_admin, error = delete_admin_user(
            db, request.user_id, req.auth.uid, admin
        )
        if error or deleted_admin is None:
            Logger.error(
                "Failed to delete admin",
                f"Failed to delete admin {request.user_id}: {error}",
                {"userId": request.user_id, "error": error}
            )
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message=error or "Failed to delete admin",
            )

        Logger.info(
            "Admin deleted",
            f"Admin {request.user_id} ({deleted_admin.name}) permanently deleted",
            {"userId": request.user_id, "adminName": deleted_admin.name},
        )
        return {
            "success": True,
            "message": f"Admin {request.user_id} ({deleted_admin.name}) permanently deleted",
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        Logger.error("Unexpected error", f"Unexpected error in delete_admin: {str(e)}", {"error": str(e)})
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Internal error: {str(e)}",
        )


@https_fn.on_call(cors=cors_options)
def get_admins(req: https_fn.CallableRequest) -> dict:
    """
    Get admin users with Auth metadata (lastSignIn, etc.)
    Only admins can call this
    Supports filtering by IDs, privilege level, and limit
    """
    Logger.info("Function called", "get_admins function called")
    db = get_db()

    try:
        # Verify admin
        admin, error = verify_admin(req)
        if req.auth is None or admin is None:
            Logger.warning("Unauthorized attempt", "Unauthorized get_admins attempt")
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message=error or "User is not authorized",
            )

        # Validate request
        try:
            request = GetAdminsRequest.model_validate(req.data or {})
            Logger.info(
                "Fetching admins",
                f"Fetching admins with filters: privilege={request.privilege_level.name if request.privilege_level else 'all'}, limit={request.limit}",
                {
                    "privilegeLevel": (
                        request.privilege_level.name
                        if request.privilege_level
                        else None
                    ),
                    "limit": request.limit,
                },
            )
        except ValidationError as e:
            Logger.error("Invalid request", f"Invalid get_admins request: {str(e)}", {"error": str(e)})
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message=f"Invalid request: {str(e)}",
            )

        # Use extracted function
        admins, error = get_admins_list(db, request)
        if error:
            Logger.error("Failed to fetch admins", f"Failed to fetch admins: {error}", {"error": error})
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INTERNAL,
                message=error,
            )

        Logger.info("Admins fetched", f"Successfully fetched {len(admins)} admins", {"count": len(admins)})
        return {
            "success": True,
            "admins": [admin.to_dict() for admin in admins],
            "count": len(admins),
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        Logger.error("Unexpected error", f"Unexpected error in get_admins: {str(e)}", {"error": str(e)})
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Internal error: {str(e)}",
        )


@https_fn.on_call(cors=cors_options)
def get_admin_by_id(req: https_fn.CallableRequest) -> dict:
    """
    Get single admin by ID with Auth metadata
    Only admins can call this
    """
    Logger.info("Function called", "get_admin_by_id function called")
    db = get_db()

    try:
        # Verify admin
        admin, error = verify_admin(req)
        if req.auth is None or admin is None:
            Logger.warning("Unauthorized attempt", "Unauthorized get_admin_by_id attempt")
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message=error or "User is not authorized",
            )

        user_id = req.data.get("userId")
        if not user_id:
            Logger.error("Missing userId", "get_admin_by_id called without userId")
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message="userId is required",
            )

        Logger.info("Fetching admin", f"Fetching admin {user_id}", {"userId": user_id})

        # Use extracted function
        target_admin, error = get_admin_by_id_data(db, user_id)
        if error or target_admin is None:
            Logger.warning("Admin not found", f"Admin {user_id} not found: {error}", {"userId": user_id, "error": error})
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.NOT_FOUND,
                message=error or "Admin not found",
            )

        Logger.info("Admin fetched", f"Successfully fetched admin {user_id}", {"userId": user_id})
        return {"success": True, "admin": target_admin.to_dict()}

    except https_fn.HttpsError:
        raise
    except Exception as e:
        Logger.error("Unexpected error", f"Unexpected error in get_admin_by_id: {str(e)}", {"error": str(e)})
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Internal error: {str(e)}",
        )


@https_fn.on_call(cors=cors_options)
def reset_user_password(req: https_fn.CallableRequest) -> dict:
    """
    Reset user password (sends password reset email)
    Only admins can call this
    Works for both providers and clients
    """
    try:
        # Verify admin
        admin, error = verify_admin(req)
        if admin is None or not admin.can_modify():
            Logger.warning("Unauthorized attempt", "Unauthorized reset_user_password attempt")
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message=error or "User is not authorized",
            )

        user_id = req.data.get("userId")
        if not user_id:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message="userId is required",
            )

        # Use extracted function
        reset_link, error = reset_user_password_link(user_id)
        if error:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INTERNAL,
                message=error,
            )

        Logger.info("Password reset generated", f"Password reset link generated for user {user_id}", {"userId": user_id})

        return {
            "success": True,
            "message": f"Password reset link generated",
            "resetLink": reset_link,  # Remove in production!
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        Logger.error("Unexpected error", f"Unexpected error in reset_user_password: {str(e)}", {"error": str(e)})
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Internal error: {str(e)}",
        )


@https_fn.on_call(cors=cors_options)
def update_user_email(req: https_fn.CallableRequest) -> dict:
    """
    Update user email (updates both Auth and Firestore)
    Only admins can call this
    Works for both providers and clients
    """
    db = get_db()
    try:
        # Verify admin
        admin, error = verify_admin(req)
        if req.auth is None or admin is None or not admin.can_modify():
            Logger.warning("Unauthorized attempt", "Unauthorized update_user_email attempt")
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message=error or "User is not authorized",
            )

        user_id = req.data.get("userId")
        new_email = req.data.get("newEmail")

        if not user_id or not new_email:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message="userId and newEmail are required",
            )

        # Use extracted function
        error = update_user_email_address(db, user_id, new_email, req.auth.uid)
        if error:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INTERNAL,
                message=error,
            )

        Logger.info("User email updated", f"User {user_id} email updated to {new_email}", {"userId": user_id, "newEmail": new_email})

        return {"success": True, "message": f"Email updated to {new_email}"}

    except https_fn.HttpsError:
        raise
    except Exception as e:
        Logger.error("Unexpected error", f"Unexpected error in update_user_email: {str(e)}", {"error": str(e)})
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Internal error: {str(e)}",
        )


@https_fn.on_call(cors=cors_options)
def generate_exercise_plan(req: https_fn.CallableRequest) -> dict:
    """
    Generate exercise plan based on user input
    Only authenticated users can call this
    """
    Logger.info("Function called", "generate_exercise_plan function called")
    try:
        # Verify user is authenticated
        if req.auth is None:
            Logger.warning("Unauthenticated attempt", "Unauthenticated generate_exercise_plan attempt")
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
                message="User must be authenticated to generate exercise plan",
            )

        # Validate request
        try:
            request = CreateExerciseRequest.model_validate(req.data)
            Logger.info(
                "Generating exercise plan",
                f"Generating exercise plan for user {request.user_id}, assessment {request.assessment_id}",
                {"userId": request.user_id, "assessmentId": request.assessment_id},
            )
        except ValidationError as e:
            Logger.error("Invalid request", f"Invalid generate_exercise_plan request: {str(e)}", {"error": str(e)})
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message=f"Invalid request: {str(e)}",
            )

        db = get_db()
        openai = get_openai()

        # Use extracted function
        Logger.info("Calling AI", f"Calling AI to generate exercise plan for user {request.user_id}", {"userId": request.user_id})
        exercises, error = generate_exercise_plan_with_ai(
            openai,
            db,
            request.user_id,
            assessment_id=request.assessment_id,
            user_requests=request.user_requests,
        )
        if error:
            Logger.error("Failed to generate plan", f"Failed to generate exercise plan: {error}", {"error": error})
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INTERNAL,
                message=error,
            )

        Logger.info(
            "Saving exercises",
            f"Generated {len(exercises)} exercises, saving to Firestore",
            {"count": len(exercises)}
        )

        # Save exercises to Firestore
        saved_exercise_ids = []
        for exercise in exercises:
            try:
                db.collection("exercises").document(exercise.id).set(exercise.to_dict())
                saved_exercise_ids.append(exercise.id)
                Logger.debug("Saved exercise", f"Saved exercise {exercise.id}", {"exerciseId": exercise.id})
            except Exception as e:
                Logger.warning(
                    "Could not save exercise",
                    f"Could not save exercise {exercise.id}: {str(e)}",
                    {"exerciseId": exercise.id, "error": str(e)},
                )

        Logger.info("Exercises saved", f"Successfully saved {len(saved_exercise_ids)} exercises", {"count": len(saved_exercise_ids)})
        return {
            "success": True,
            "exercises": [ex.to_dict() for ex in exercises],
            "exerciseIds": saved_exercise_ids,
            "count": len(exercises),
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        Logger.error("Unexpected error", f"Unexpected error in generate_exercise_plan: {str(e)}", {"error": str(e)})
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Internal error: {str(e)}",
        )
