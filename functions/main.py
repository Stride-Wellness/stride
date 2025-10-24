from firebase_functions import https_fn, options
from firebase_functions.options import set_global_options
from firebase_admin import initialize_app, auth, firestore
from pydantic import BaseModel, ValidationError
from datetime import datetime
from typing import Any, Literal, Optional
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
_db = None

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


def verify_admin(
    context: https_fn.CallableRequest,
) -> tuple[Admin | None, Optional[str]]:
    """Verify that the calling user is an admin"""

    db = get_db()

    if not context.auth:
        return None, "User must be authenticated"

    try:
        # Get calling user from Firestore
        user_doc = db.collection('admins').document(context.auth.uid).get()

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
                message=error or "User is not authorized"
            )

        # Validate request
        try:
            request = CreateProviderRequest.model_validate(req.data)
        except ValidationError as e:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message=f"Invalid request: {str(e)}"
            )

        # Validate provider roles
        if not request.provider_role:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message="Provider must have at least one role",
            )

        # Validate role values
        valid_roles = [role.value for role in ProviderRole]
        for role in request.provider_role:
            if role not in valid_roles:
                raise https_fn.HttpsError(
                    code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                    message=f"Invalid role: {role}. Valid roles: {valid_roles}"
                )

        # Create Firebase Auth user
        try:
            auth_user = auth.create_user(
                email=request.email,
                password=request.password,
                display_name=request.name
            )
        except auth.EmailAlreadyExistsError:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.ALREADY_EXISTS,
                message=f"Email {request.email} already exists"
            )
        except Exception as e:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INTERNAL,
                message=f"Error creating auth user: {str(e)}"
            )

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
            "createdBy": req.auth.uid,
        }

        try:
            db.collection("users").document(auth_user.uid).set(provider_data)
        except Exception as e:
            # Rollback: delete auth user if Firestore fails
            auth.delete_user(auth_user.uid)
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INTERNAL,
                message=f"Error creating Firestore document: {str(e)}"
            )

        return {
            "success": True,
            "userId": auth_user.uid,
            "message": f"Provider {request.name} created successfully",
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        print(f"Error in create_provider: {str(e)}")
        print(traceback.format_exc())
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Internal error: {str(e)}"
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
                message=error or "User is not authorized"
            )

        # Validate request
        try:
            request = UpdateProviderRequest.model_validate(req.data)
        except ValidationError as e:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message=f"Invalid request: {str(e)}"
            )

        # Check user exists and is provider
        user_ref = db.collection('users').document(request.user_id)
        user_doc = user_ref.get()

        if not user_doc.exists:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.NOT_FOUND,
                message=f"User {request.user_id} not found"
            )

        user_data = user_doc.to_dict()

        if (user_data or {}).get("type") != "provider":
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message=f"User {request.user_id} is not an provider",
            )

        # Build update data
        update_data: dict[str, Any] = {
            'updatedAt': datetime.now(),
            'updatedBy': req.auth.uid,
        }

        if request.name:
            update_data['name'] = request.name
            # Update Auth display name too
            try:
                auth.update_user(request.user_id, display_name=request.name)
            except Exception as e:
                print(f"Warning: Could not update auth display name: {e}")

        if request.status:
            update_data['status'] = request.status

        if request.provider_role:
            # Validate roles
            valid_roles = [role.value for role in ProviderRole]
            for role in request.provider_role:
                if role not in valid_roles:
                    raise https_fn.HttpsError(
                        code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                        message=f"Invalid role: {role}"
                    )
            update_data["providerRole"] = request.provider_role

        if request.profile:
            update_data['profile'] = request.profile

        # Update Firestore
        user_ref.update(update_data)

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
            message=f"Internal error: {str(e)}"
        )


@https_fn.on_call(cors=cors_options)
def delete_provider(req: https_fn.CallableRequest) -> dict:
    """
    Delete provider (soft delete by default, hard delete removes from Auth)
    Only admins can call this
    """

    db = get_db()

    try:
        # Verify admin
        admin, error = verify_admin(req)
        if req.auth is None or admin is None or not admin.can_modify():
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message=error or "User is not authorized"
            )

        # Validate request
        try:
            request = DeleteUserRequest.model_validate(req.data)
        except ValidationError as e:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message=f"Invalid request: {str(e)}"
            )

        # Check user exists and is provider
        user_ref = db.collection('users').document(request.user_id)
        user_doc = user_ref.get()

        if not user_doc.exists:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.NOT_FOUND,
                message=f"User {request.user_id} not found"
            )

        user_data = user_doc.to_dict()
        if (user_data or {}).get("type") != "provider":
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message=f"User {request.user_id} is not an provider",
            )

        if request.hard_delete:
            # Hard delete: Remove from Auth and Firestore
            try:
                auth.delete_user(request.user_id)
            except Exception as e:
                print(f"Warning: Could not delete auth user: {e}")

            user_ref.delete()
            message = f"Provider {request.user_id} permanently deleted"
        else:
            # Soft delete: Mark as deleted in Firestore
            user_ref.update({
                'status': 'deleted',
                'deletedAt': datetime.now(),
                'deletedBy': req.auth.uid
            })
            message = f"Provider {request.user_id} soft deleted"

        return {"success": True, "message": message}

    except https_fn.HttpsError:
        raise
    except Exception as e:
        print(f"Error in delete_provider: {str(e)}")
        print(traceback.format_exc())
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Internal error: {str(e)}"
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
                message=error or "User is not authorized"
            )

        # Validate request
        try:
            request = CreateClientRequest.model_validate(req.data)
        except ValidationError as e:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message=f"Invalid request: {str(e)}"
            )

        # Create Firebase Auth user
        try:
            auth_user = auth.create_user(
                email=request.email,
                password=request.password,
                display_name=request.name
            )
        except auth.EmailAlreadyExistsError:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.ALREADY_EXISTS,
                message=f"Email {request.email} already exists"
            )
        except Exception as e:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INTERNAL,
                message=f"Error creating auth user: {str(e)}"
            )

        # Create Firestore client document
        now = datetime.now()
        client_data: dict[str, Any] = {
            'id': auth_user.uid,
            'email': request.email,
            'name': request.name,
            'type': 'client',
            'organizationId': request.organization_id,
            'divisionId': request.division_id,
            'status': 'active',
            'profile': {},
            'createdAt': now,
            'updatedAt': now,
            'createdBy': req.auth.uid
        }

        # Add optional profile fields
        if request.phone:
            client_data['profile']['phone'] = request.phone
        if request.date_of_birth:
            client_data['profile']['dateOfBirth'] = request.date_of_birth

        try:
            db.collection('users').document(auth_user.uid).set(client_data)
        except Exception as e:
            # Rollback: delete auth user if Firestore fails
            auth.delete_user(auth_user.uid)
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INTERNAL,
                message=f"Error creating Firestore document: {str(e)}"
            )

        return {
            "success": True,
            "userId": auth_user.uid,
            "message": f"Client {request.name} created successfully",
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        print(f"Error in create_client: {str(e)}")
        print(traceback.format_exc())
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Internal error: {str(e)}"
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
                message=error or "User is not authorized"
            )

        # Validate request
        try:
            request = UpdateClientRequest.model_validate(req.data)
        except ValidationError as e:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message=f"Invalid request: {str(e)}"
            )

        # Check user exists and is client
        user_ref = db.collection('users').document(request.user_id)
        user_doc = user_ref.get()

        if not user_doc.exists:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.NOT_FOUND,
                message=f"User {request.user_id} not found"
            )

        user_data = user_doc.to_dict()
        if (user_data or {}).get('type') != 'client':
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message=f"User {request.user_id} is not a client"
            )

        # Build update data
        update_data: dict[str, Any] = {
            'updatedAt': datetime.now(),
            'updatedBy': req.auth.uid
        }

        if request.name:
            update_data['name'] = request.name
            # Update Auth display name too
            try:
                auth.update_user(request.user_id, display_name=request.name)
            except Exception as e:
                print(f"Warning: Could not update auth display name: {e}")

        if request.status:
            update_data['status'] = request.status

        if request.profile:
            update_data['profile'] = request.profile

        # Update Firestore
        user_ref.update(update_data)

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
            message=f"Internal error: {str(e)}"
        )


@https_fn.on_call(cors=cors_options)
def delete_client(req: https_fn.CallableRequest) -> dict:
    """
    Delete client (soft delete by default, hard delete removes from Auth)
    Only admins can call this
    """
    db = get_db()
    try:
        # Verify admin
        admin, error = verify_admin(req)
        if req.auth is None or admin is None or not admin.can_modify():
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message=error or "User is not authorized"
            )

        # Validate request
        try:
            request = DeleteUserRequest.model_validate(req.data)
        except ValidationError as e:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message=f"Invalid request: {str(e)}"
            )

        # Check user exists and is client
        user_ref = db.collection('users').document(request.user_id)
        user_doc = user_ref.get()

        if not user_doc.exists:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.NOT_FOUND,
                message=f"User {request.user_id} not found"
            )

        user_data = user_doc.to_dict()
        if (user_data or {}).get('type') != 'client':
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message=f"User {request.user_id} is not a client"
            )

        if request.hard_delete:
            # Hard delete: Remove from Auth and Firestore
            try:
                auth.delete_user(request.user_id)
            except Exception as e:
                print(f"Warning: Could not delete auth user: {e}")

            user_ref.delete()
            message = f'Client {request.user_id} permanently deleted'
        else:
            # Soft delete: Mark as deleted in Firestore
            user_ref.update({
                'status': 'deleted',
                'deletedAt': datetime.now(),
                'deletedBy': req.auth.uid
            })
            message = f'Client {request.user_id} soft deleted'

        return {"success": True, "message": message}

    except https_fn.HttpsError:
        raise
    except Exception as e:
        print(f"Error in delete_client: {str(e)}")
        print(traceback.format_exc())
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Internal error: {str(e)}",
        )

# ============================================================================
# General User Read Functions
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

        # Build Firestore query
        users_ref = db.collection("users")

        # Filter by specific IDs
        if request.user_ids:
            if len(request.user_ids) > 10:
                raise https_fn.HttpsError(
                    code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                    message="Cannot filter by more than 10 user IDs at once",
                )
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
        users_data = []

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
                    ).isoformat()

                user_dict["lastSignIn"] = last_sign_in
            except Exception as e:
                print(f"Warning: Could not get auth metadata for {doc.id}: {e}")
                user_dict["lastSignIn"] = None

            users_data.append(user_dict)

        return {"success": True, "users": users_data, "count": len(users_data)}

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

        # Get from Firestore
        user_doc = db.collection("users").document(user_id).get()

        if not user_doc.exists:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.NOT_FOUND,
                message=f"User {user_id} not found",
            )

        user_dict = user_doc.to_dict()
        if not user_dict:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.NOT_FOUND,
                message=f"User {user_id} data is empty",
            )

        user_dict["id"] = user_doc.id

        # Get Auth metadata
        try:
            auth_user = auth.get_user(user_id)
            last_sign_in = None
            if auth_user.user_metadata.last_sign_in_timestamp:
                last_sign_in = datetime.fromtimestamp(
                    auth_user.user_metadata.last_sign_in_timestamp / 1000
                ).isoformat()

            user_dict["lastSignIn"] = last_sign_in
        except Exception as e:
            print(f"Warning: Could not get auth metadata for {user_id}: {e}")
            user_dict["lastSignIn"] = None

        return {"success": True, "user": user_dict}

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

        # Only admins can create other admins with lower privilege
        if request.privilege.value <= admin.privilege.value:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message=f"Cannot create admin with equal or higher privilege. Your level: {admin.privilege.name}, Requested: {request.privilege.name}",
            )

        # Create Firebase Auth user
        try:
            auth_user = auth.create_user(
                email=request.email,
                password=request.password,
                display_name=request.name,
            )
        except auth.EmailAlreadyExistsError:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.ALREADY_EXISTS,
                message=f"Email {request.email} already exists",
            )
        except Exception as e:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INTERNAL,
                message=f"Error creating auth user: {str(e)}",
            )

        # Create Firestore admin document
        now = datetime.now()
        admin_data = {
            "id": auth_user.uid,
            "name": request.name,
            "privilege": request.privilege.value,
            "createdAt": now,
            "createdBy": req.auth.uid,
            "updatedAt": now,
        }

        try:
            db.collection("admins").document(auth_user.uid).set(admin_data)
        except Exception as e:
            # Rollback: delete auth user if Firestore fails
            auth.delete_user(auth_user.uid)
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INTERNAL,
                message=f"Error creating Firestore document: {str(e)}",
            )

        return {
            "success": True,
            "userId": auth_user.uid,
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

        # Check if there are any updates
        if not request.has_updates():
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message="No fields to update",
            )

        # Check target admin exists
        admin_ref = db.collection("admins").document(request.user_id)
        admin_doc = admin_ref.get()

        if not admin_doc.exists:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.NOT_FOUND,
                message=f"Admin {request.user_id} not found",
            )

        target_admin_dict = admin_doc.to_dict()
        if not target_admin_dict:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.NOT_FOUND,
                message=f"Admin {request.user_id} data is empty",
            )

        target_admin_dict["id"] = admin_doc.id
        target_admin = Admin.from_dict(target_admin_dict)

        # Cannot modify admins with equal or higher privilege
        if target_admin.privilege.value <= admin.privilege.value:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message=f"Cannot modify admin with equal or higher privilege. Target: {target_admin.privilege.name}, Your level: {admin.privilege.name}",
            )

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
            if request.privilege.value <= admin.privilege.value:
                raise https_fn.HttpsError(
                    code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                    message=f"Cannot set privilege equal to or higher than your own. Your level: {admin.privilege.name}, Requested: {request.privilege.name}",
                )

            update_data["privilege"] = request.privilege.value

        # Update Firestore
        admin_ref.update(update_data)

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

        # Cannot delete yourself
        if request.user_id == req.auth.uid:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message="Cannot delete yourself",
            )

        # Check target admin exists
        admin_ref = db.collection("admins").document(request.user_id)
        admin_doc = admin_ref.get()

        if not admin_doc.exists:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.NOT_FOUND,
                message=f"Admin {request.user_id} not found",
            )

        target_admin_dict = admin_doc.to_dict()
        if not target_admin_dict:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.NOT_FOUND,
                message=f"Admin {request.user_id} data is empty",
            )

        target_admin_dict["id"] = admin_doc.id
        target_admin = Admin.from_dict(target_admin_dict)

        # Cannot delete admins with equal or higher privilege
        if target_admin.privilege.value <= admin.privilege.value:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message=f"Cannot delete admin with equal or higher privilege. Target: {target_admin.privilege.name}, Your level: {admin.privilege.name}",
            )

        # Hard delete: Remove from Auth and Firestore
        try:
            auth.delete_user(request.user_id)
        except Exception as e:
            print(f"Warning: Could not delete auth user: {e}")

        admin_ref.delete()

        return {
            "success": True,
            "message": f"Admin {request.user_id} ({target_admin.name}) permanently deleted",
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

        # Build Firestore query
        admins_ref = db.collection("admins")

        # Filter by specific IDs
        if request.user_ids:
            # Firestore 'in' queries limited to 10 items
            if len(request.user_ids) > 10:
                raise https_fn.HttpsError(
                    code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                    message="Cannot filter by more than 10 user IDs at once",
                )
            query = admins_ref.where("id", "in", request.user_ids)
        else:
            query = admins_ref.order_by(
                "createdAt", direction=firestore.firestore.Query.DESCENDING
            ).limit(request.limit)

            # Filter by privilege level
            if request.privilege_level is not None:
                query = query.where("privilege", "==", request.privilege_level.value)

        # Execute query
        docs = query.stream()
        admins_data = []

        for doc in docs:
            admin_dict = doc.to_dict()
            if not admin_dict:
                continue

            admin_dict["id"] = doc.id

            # Get Auth metadata (lastSignIn)
            try:
                auth_user = auth.get_user(doc.id)
                # Parse lastSignInTime from Auth metadata
                last_sign_in = None
                if auth_user.user_metadata.last_sign_in_timestamp:
                    last_sign_in = datetime.fromtimestamp(
                        auth_user.user_metadata.last_sign_in_timestamp / 1000
                    ).isoformat()

                admin_dict["lastSignIn"] = last_sign_in
            except Exception as e:
                print(f"Warning: Could not get auth metadata for {doc.id}: {e}")
                admin_dict["lastSignIn"] = None

            admins_data.append(admin_dict)

        return {"success": True, "admins": admins_data, "count": len(admins_data)}

    except https_fn.HttpsError:
        raise
    except Exception as e:
        print(f"Error in get_admins: {str(e)}")
        print(traceback.format_exc())
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Internal error: {str(e)}"
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

        # Get from Firestore
        admin_doc = db.collection("admins").document(user_id).get()

        if not admin_doc.exists:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.NOT_FOUND,
                message=f"Admin {user_id} not found",
            )

        admin_dict = admin_doc.to_dict()
        if not admin_dict:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.NOT_FOUND,
                message=f"Admin {user_id} data is empty",
            )

        admin_dict["id"] = admin_doc.id

        # Get Auth metadata
        try:
            auth_user = auth.get_user(user_id)
            last_sign_in = None
            if auth_user.user_metadata.last_sign_in_timestamp:
                last_sign_in = datetime.fromtimestamp(
                    auth_user.user_metadata.last_sign_in_timestamp / 1000
                ).isoformat()

            admin_dict["lastSignIn"] = last_sign_in
        except Exception as e:
            print(f"Warning: Could not get auth metadata for {user_id}: {e}")
            admin_dict["lastSignIn"] = None

        return {"success": True, "admin": admin_dict}

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
                message=error or "User is not authorized"
            )

        user_id = req.data.get("userId")
        if not user_id:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message="userId is required"
            )

        # Get user email
        try:
            auth_user = auth.get_user(user_id)
        except auth.UserNotFoundError:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.NOT_FOUND,
                message=f"User {user_id} not found in Auth"
            )

        # Generate password reset link
        try:
            reset_link = auth.generate_password_reset_link(auth_user.email)
            # In production, send this via email
            return {
                'success': True,
                'message': f'Password reset link generated for {auth_user.email}',
                'resetLink': reset_link  # Remove in production!
            }
        except Exception as e:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INTERNAL,
                message=f"Error generating reset link: {str(e)}"
            )

    except https_fn.HttpsError:
        raise
    except Exception as e:
        print(f"Error in reset_user_password: {str(e)}")
        print(traceback.format_exc())
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Internal error: {str(e)}"
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
                message=error or "User is not authorized"
            )

        user_id = req.data.get("userId")
        new_email = req.data.get('newEmail')

        if not user_id or not new_email:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message="userId and newEmail are required"
            )

        # Update Auth
        try:
            auth.update_user(user_id, email=new_email)
        except auth.EmailAlreadyExistsError:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.ALREADY_EXISTS,
                message=f"Email {new_email} already exists"
            )
        except auth.UserNotFoundError:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.NOT_FOUND,
                message=f"User {user_id} not found"
            )

        # Update Firestore
        db.collection('users').document(user_id).update({
            'email': new_email,
            'updatedAt': datetime.now(),
            'updatedBy': req.auth.uid
        })

        return {"success": True, "message": f"Email updated to {new_email}"}

    except https_fn.HttpsError:
        raise
    except Exception as e:
        print(f"Error in update_user_email: {str(e)}")
        print(traceback.format_exc())
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Internal error: {str(e)}"
        )
