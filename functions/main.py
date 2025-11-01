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

set_global_options(
    max_instances=10,
)
initialize_app()
_db: FirestoreClient | None = None
_openai: OpenAI | None = None

# Configure CORS for your admin dashboard
cors_options = options.CorsOptions(
    cors_origins=[
        "http://localhost:5173",  # Local development
        "http://localhost:4173",  # Preview build
        "https://admin.stridewellness.ca",  # Production (if using Firebase Hosting)
        "https://stride-c054b.firebaseapp.com",  # Production (if using Firebase Hosting)
        # Add your actual production domain here
    ],
    cors_methods=["GET", "POST", "OPTIONS"],
)


# ============================================================================
# Helper Functions
# ============================================================================


def get_db():
    """Initialize Firestore DB if not already initialized"""
    global _db
    if _db is None:
        _db = firestore.client()
    return _db


def get_openai():
    """Initialize OpenAI client if not already initialized"""
    global _openai
    if _openai is None:
        load_dotenv()  # Load .env file
        print(os.environ)
        api_key = os.environ.get("OPENAI_API_KEY")
        _openai = OpenAI(api_key=api_key)
    return _openai


def verify_admin(
    context: https_fn.CallableRequest,
) -> tuple[Admin | None, Optional[str]]:
    """Verify that the calling user is an admin"""

    db = get_db()

    if not context.auth:
        return None, "User must be authenticated"

    try:
        # Get calling user from Firestore
        user_doc = db.collection("admins").document(context.auth.uid).get()

        if not user_doc.exists:
            return None, "User not found"

        user_dict = user_doc.to_dict()

        if not user_dict:
            return None, "User data is empty"

        user_dict["id"] = user_doc.id  # Ensure ID is set
        user_data = Admin.from_dict(user_dict)

        return user_data, None

    except Exception as e:
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
    db = get_db()
    try:
        # Verify admin
        admin, error = verify_admin(req)

        if req.auth is None or admin is None or not admin.can_modify():
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message=error or "User is not authorized",
            )

        # Validate request
        try:
            request = CreateProviderRequest.model_validate(req.data)
        except ValidationError as e:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message=f"Invalid request: {str(e)}",
            )

        # Use extracted function
        user, error = create_provider_user(db, request, req.auth.uid)
        if error or user is None:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INTERNAL,
                message=error or "Failed to create provider",
            )

        return {
            "success": True,
            "userId": user.id,
            "message": f"Provider {request.name} created successfully",
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        print(f"Error in create_provider: {str(e)}")
        print(traceback.format_exc())
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

    db = get_db()

    try:
        # Verify admin
        admin, error = verify_admin(req)
        if req.auth is None or admin is None or not admin.can_modify():
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message=error or "User is not authorized",
            )

        # Validate request
        try:
            request = UpdateProviderRequest.model_validate(req.data)
        except ValidationError as e:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message=f"Invalid request: {str(e)}",
            )

        # Use extracted function
        user, error = update_provider_user(db, request, req.auth.uid)
        if error or user is None:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INTERNAL,
                message=error or "Failed to update provider",
            )

        return {
            "success": True,
            "message": f"Provider {request.user_id} updated successfully",
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        print(f"Error in update_provider: {str(e)}")
        print(traceback.format_exc())
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Internal error: {str(e)}",
        )


# ============================================================================
# Client CRUD Functions
# ============================================================================


@https_fn.on_call(cors=cors_options)
def create_client(req: https_fn.CallableRequest) -> dict:
    """
    Create a new client (Firebase Auth + Firestore)
    Only admins can call this
    """
    db = get_db()

    try:
        # Verify admin
        admin, error = verify_admin(req)
        if req.auth is None or admin is None or not admin.can_modify():
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message=error or "User is not authorized",
            )

        # Validate request
        try:
            request = CreateClientRequest.model_validate(req.data)
        except ValidationError as e:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message=f"Invalid request: {str(e)}",
            )

        # Use extracted function
        user, error = create_client_user(db, request, req.auth.uid)
        if error or user is None:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INTERNAL,
                message=error or "Failed to create client",
            )

        return {
            "success": True,
            "userId": user.id,
            "message": f"Client {request.name} created successfully",
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        print(f"Error in create_client: {str(e)}")
        print(traceback.format_exc())
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
    db = get_db()
    try:
        # Verify admin
        admin, error = verify_admin(req)
        if req.auth is None or admin is None or not admin.can_modify():
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message=error or "User is not authorized",
            )

        # Validate request
        try:
            request = UpdateClientRequest.model_validate(req.data)
        except ValidationError as e:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message=f"Invalid request: {str(e)}",
            )

        # Use extracted function
        user, error = update_client_user(db, request, req.auth.uid)
        if error or user is None:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INTERNAL,
                message=error or "Failed to update client",
            )

        return {
            "success": True,
            "message": f"Client {request.user_id} updated successfully",
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        print(f"Error in update_client: {str(e)}")
        print(traceback.format_exc())
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Internal error: {str(e)}",
        )


# ============================================================================
# General User CRUD Functions
# ============================================================================


@https_fn.on_call(cors=cors_options)
def get_users(req: https_fn.CallableRequest) -> dict:
    """
    Get users (providers and clients) with Auth metadata
    Only admins can call this
    Supports filtering by IDs, organization, division, type, status, and limit
    """
    db = get_db()

    try:
        # Verify admin
        admin, error = verify_admin(req)
        if req.auth is None or admin is None:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message=error or "User is not authorized",
            )

        # Validate request
        try:
            request = GetUsersRequest.model_validate(req.data or {})
        except ValidationError as e:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message=f"Invalid request: {str(e)}",
            )

        # Use extracted function
        users, error = get_users_list(db, request)
        if error:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INTERNAL,
                message=error,
            )

        return {
            "success": True,
            "users": [user.to_dict() for user in users],
            "count": len(users),
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        print(f"Error in get_users: {str(e)}")
        print(traceback.format_exc())
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
    db = get_db()

    try:
        # Verify admin
        admin, error = verify_admin(req)
        if req.auth is None or admin is None:
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
        user, error = get_user_by_id_data(db, user_id)
        if error or user is None:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.NOT_FOUND,
                message=error or "User not found",
            )

        return {"success": True, "user": user.to_dict()}

    except https_fn.HttpsError:
        raise
    except Exception as e:
        print(f"Error in get_user_by_id: {str(e)}")
        print(traceback.format_exc())
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
    db = get_db()

    try:
        # Verify admin
        admin, error = verify_admin(req)
        if req.auth is None or admin is None:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message=error or "User is not authorized",
            )

        organization_id = req.data.get("organizationId")

        # Use extracted function
        stats = get_user_statistics(db, organization_id)

        return {"success": True, "stats": stats}

    except https_fn.HttpsError:
        raise
    except Exception as e:
        print(f"Error in get_user_stats: {str(e)}")
        print(traceback.format_exc())
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
    db = get_db()
    try:
        # Verify admin
        admin, error = verify_admin(req)
        if req.auth is None or admin is None or not admin.can_modify():
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message=error or "User is not authorized",
            )

        # Validate request
        try:
            request = DeleteUserRequest.model_validate(req.data)
        except ValidationError as e:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message=f"Invalid request: {str(e)}",
            )

        # Use extracted function
        user, error = delete_user_account(db, request, req.auth.uid)
        if error or user is None:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.NOT_FOUND,
                message=error or "User not found",
            )

        message = (
            f"User {request.user_id} permanently deleted"
            if request.hard_delete
            else f"User {request.user_id} soft deleted"
        )

        return {"success": True, "message": message}

    except https_fn.HttpsError:
        raise
    except Exception as e:
        print(f"Error in delete_user: {str(e)}")
        print(traceback.format_exc())
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Internal error: {str(e)}",
        )


# ============================================================================
# Admin CRUD Functions
# ============================================================================


@https_fn.on_call(cors=cors_options)
def create_admin(req: https_fn.CallableRequest) -> dict:
    """
    Create a new admin (Firebase Auth + Firestore)
    Only admins with sufficient privilege can call this
    Cannot create admins with equal or higher privilege than yourself
    """
    db = get_db()

    try:
        # Verify admin
        admin, error = verify_admin(req)
        if req.auth is None or admin is None or not admin.can_modify():
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message=error or "User is not authorized",
            )

        # Validate request data
        try:
            request = CreateAdminRequest.model_validate(req.data)
        except ValidationError as e:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message=f"Invalid request: {str(e)}",
            )

        # Use extracted function
        new_admin, error = create_admin_user(db, request, req.auth.uid, admin)
        if error or new_admin is None:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message=error or "Failed to create admin",
            )

        return {
            "success": True,
            "userId": new_admin.id,
            "message": f"Admin {request.name} created successfully with privilege level {request.privilege.name}",
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        print(f"Error in create_admin: {str(e)}")
        print(traceback.format_exc())
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
    db = get_db()

    try:
        # Verify admin
        admin, error = verify_admin(req)
        if req.auth is None or admin is None or not admin.can_modify():
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message=error or "User is not authorized",
            )

        # Validate request
        try:
            request = UpdateAdminRequest.model_validate(req.data)
        except ValidationError as e:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message=f"Invalid request: {str(e)}",
            )

        # Use extracted function
        updated_admin, error = update_admin_user(db, request, admin)
        if error or updated_admin is None:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message=error or "Failed to update admin",
            )

        return {
            "success": True,
            "message": f"Admin {request.user_id} updated successfully",
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        print(f"Error in update_admin: {str(e)}")
        print(traceback.format_exc())
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
    db = get_db()

    try:
        # Verify admin
        admin, error = verify_admin(req)
        if req.auth is None or admin is None or not admin.can_modify():
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message=error or "User is not authorized",
            )

        # Validate request
        try:
            request = DeleteAdminRequest.model_validate(req.data)
        except ValidationError as e:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message=f"Invalid request: {str(e)}",
            )

        # Use extracted function
        deleted_admin, error = delete_admin_user(
            db, request.user_id, req.auth.uid, admin
        )
        if error or deleted_admin is None:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message=error or "Failed to delete admin",
            )

        return {
            "success": True,
            "message": f"Admin {request.user_id} ({deleted_admin.name}) permanently deleted",
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        print(f"Error in delete_admin: {str(e)}")
        print(traceback.format_exc())
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
    db = get_db()

    try:
        # Verify admin
        admin, error = verify_admin(req)
        if req.auth is None or admin is None:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message=error or "User is not authorized",
            )

        # Validate request
        try:
            request = GetAdminsRequest.model_validate(req.data or {})
        except ValidationError as e:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message=f"Invalid request: {str(e)}",
            )

        # Use extracted function
        admins, error = get_admins_list(db, request)
        if error:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INTERNAL,
                message=error,
            )

        return {
            "success": True,
            "admins": [admin.to_dict() for admin in admins],
            "count": len(admins),
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        print(f"Error in get_admins: {str(e)}")
        print(traceback.format_exc())
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
    db = get_db()

    try:
        # Verify admin
        admin, error = verify_admin(req)
        if req.auth is None or admin is None:
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
        target_admin, error = get_admin_by_id_data(db, user_id)
        if error or target_admin is None:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.NOT_FOUND,
                message=error or "Admin not found",
            )

        return {"success": True, "admin": target_admin.to_dict()}

    except https_fn.HttpsError:
        raise
    except Exception as e:
        print(f"Error in get_admin_by_id: {str(e)}")
        print(traceback.format_exc())
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Internal error: {str(e)}",
        )


# ============================================================================
# Shared User Functions
# ============================================================================


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

        return {
            "success": True,
            "message": f"Password reset link generated",
            "resetLink": reset_link,  # Remove in production!
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        print(f"Error in reset_user_password: {str(e)}")
        print(traceback.format_exc())
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

        return {"success": True, "message": f"Email updated to {new_email}"}

    except https_fn.HttpsError:
        raise
    except Exception as e:
        print(f"Error in update_user_email: {str(e)}")
        print(traceback.format_exc())
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Internal error: {str(e)}",
        )


# ============================================================================
# Exercise Functions
# ============================================================================

# these function will be used to generate excerise plans based on user input
# the ai will generate 3 excerise


@https_fn.on_call(cors=cors_options)
def generate_exercise_plan(req: https_fn.CallableRequest) -> dict:
    """
    Generate exercise plan based on user input
    Only authenticated users can call this
    """
    try:
        # Verify user is authenticated
        if req.auth is None:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
                message="User must be authenticated to generate exercise plan",
            )

        # Validate request
        try:
            request = CreateExerciseRequest.model_validate(req.data)
        except ValidationError as e:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message=f"Invalid request: {str(e)}",
            )

        db = get_db()
        openai = get_openai()

        # Use extracted function
        exercises, error = generate_exercise_plan_with_ai(
            openai,
            db,
            request.user_id,
            assessment_id=request.assessment_id,
            user_requests=request.user_requests,
        )
        if error:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INTERNAL,
                message=error,
            )

        # Save exercises to Firestore
        saved_exercise_ids = []
        for exercise in exercises:
            try:
                db.collection("exercises").document(exercise.id).set(exercise.to_dict())
                saved_exercise_ids.append(exercise.id)
            except Exception as e:
                print(f"Warning: Could not save exercise {exercise.id}: {e}")

        return {
            "success": True,
            "exercises": [ex.to_dict() for ex in exercises],
            "exerciseIds": saved_exercise_ids,
            "count": len(exercises),
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        print(f"Error in generate_exercise_plan: {str(e)}")
        print(traceback.format_exc())
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Internal error: {str(e)}",
        )
