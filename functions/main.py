import re
from firebase_functions import https_fn
from firebase_functions.options import set_global_options
from firebase_admin import initialize_app, auth, firestore
from pydantic import BaseModel, ValidationError
from datetime import datetime
from typing import Any, Literal, Optional
import traceback

from models.admin import Admin
from models.user import CreateClientRequest, CreateEmployeeRequest, DeleteUserRequest, EmployeeRole, UpdateClientRequest, UpdateEmployeeRequest

set_global_options(max_instances=10)
initialize_app()
db = firestore.client()

# ============================================================================
# Helper Functions
# ============================================================================

def verify_admin(context: https_fn.CallableRequest) -> tuple[Admin|None, Optional[str]]:
    """Verify that the calling user is an admin"""
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

        user_data = Admin.from_dict(user_dict)

        return user_data, None
        
    except Exception as e:
        return None, f"Error verifying admin: {str(e)}"


# ============================================================================
# Employee CRUD Functions
# ============================================================================

@https_fn.on_call()
def create_employee(req: https_fn.CallableRequest) -> dict:
    """
    Create a new employee (Firebase Auth + Firestore)
    Only admins can call this
    """
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
            request = CreateEmployeeRequest.model_validate(req.data)
        except ValidationError as e:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message=f"Invalid request: {str(e)}"
            )
        
        # Validate employee roles
        if not request.employee_role:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message="Employee must have at least one role"
            )
        
        # Validate role values
        valid_roles = [role.value for role in EmployeeRole]
        for role in request.employee_role:
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
        
        # Create Firestore employee document
        now = datetime.now()
        employee_data = {
            'id': auth_user.uid,
            'email': request.email,
            'name': request.name,
            'type': 'employee',
            'organizationId': request.organization_id,
            'divisionId': request.division_id,
            'employeeRole': request.employee_role,
            'status': 'active',
            'profile': {},
            'createdAt': now,
            'updatedAt': now,
            'createdBy': req.auth.uid
        }
        
        try:
            db.collection('users').document(auth_user.uid).set(employee_data)
        except Exception as e:
            # Rollback: delete auth user if Firestore fails
            auth.delete_user(auth_user.uid)
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INTERNAL,
                message=f"Error creating Firestore document: {str(e)}"
            )
        
        return {
            'success': True,
            'userId': auth_user.uid,
            'message': f'Employee {request.name} created successfully'
        }
        
    except https_fn.HttpsError:
        raise
    except Exception as e:
        print(f"Error in create_employee: {str(e)}")
        print(traceback.format_exc())
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Internal error: {str(e)}"
        )


@https_fn.on_call()
def update_employee(req: https_fn.CallableRequest) -> dict:
    """
    Update employee data in Firestore
    Only admins can call this
    """
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
            request = UpdateEmployeeRequest.model_validate(req.data)
        except ValidationError as e:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message=f"Invalid request: {str(e)}"
            )
        
        # Check user exists and is employee
        user_ref = db.collection('users').document(request.user_id)
        user_doc = user_ref.get()
        
        if not user_doc.exists:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.NOT_FOUND,
                message=f"User {request.user_id} not found"
            )
        
        user_data = user_doc.to_dict()

        if (user_data or {}).get('type') != 'employee':
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message=f"User {request.user_id} is not an employee"
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
        
        if request.employee_role:
            # Validate roles
            valid_roles = [role.value for role in EmployeeRole]
            for role in request.employee_role:
                if role not in valid_roles:
                    raise https_fn.HttpsError(
                        code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                        message=f"Invalid role: {role}"
                    )
            update_data['employeeRole'] = request.employee_role
        
        if request.profile:
            update_data['profile'] = request.profile
        
        # Update Firestore
        user_ref.update(update_data)
        
        return {
            'success': True,
            'message': f'Employee {request.user_id} updated successfully'
        }
        
    except https_fn.HttpsError:
        raise
    except Exception as e:
        print(f"Error in update_employee: {str(e)}")
        print(traceback.format_exc())
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Internal error: {str(e)}"
        )


@https_fn.on_call()
def delete_employee(req: https_fn.CallableRequest) -> dict:
    """
    Delete employee (soft delete by default, hard delete removes from Auth)
    Only admins can call this
    """
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
        
        # Check user exists and is employee
        user_ref = db.collection('users').document(request.user_id)
        user_doc = user_ref.get()
        
        if not user_doc.exists:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.NOT_FOUND,
                message=f"User {request.user_id} not found"
            )
        
        user_data = user_doc.to_dict()
        if (user_data or {}).get('type') != 'employee':
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message=f"User {request.user_id} is not an employee"
            )
        
        if request.hard_delete:
            # Hard delete: Remove from Auth and Firestore
            try:
                auth.delete_user(request.user_id)
            except Exception as e:
                print(f"Warning: Could not delete auth user: {e}")
            
            user_ref.delete()
            message = f'Employee {request.user_id} permanently deleted'
        else:
            # Soft delete: Mark as deleted in Firestore
            user_ref.update({
                'status': 'deleted',
                'deletedAt': datetime.now(),
                'deletedBy': req.auth.uid
            })
            message = f'Employee {request.user_id} soft deleted'
        
        return {
            'success': True,
            'message': message
        }
        
    except https_fn.HttpsError:
        raise
    except Exception as e:
        print(f"Error in delete_employee: {str(e)}")
        print(traceback.format_exc())
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Internal error: {str(e)}"
        )


# ============================================================================
# Client CRUD Functions
# ============================================================================

@https_fn.on_call()
def create_client(req: https_fn.CallableRequest) -> dict:
    """
    Create a new client (Firebase Auth + Firestore)
    Only admins can call this
    """
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
            'success': True,
            'userId': auth_user.uid,
            'message': f'Client {request.name} created successfully'
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


@https_fn.on_call()
def update_client(req: https_fn.CallableRequest) -> dict:
    """
    Update client data in Firestore
    Only admins can call this
    """
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
            'success': True,
            'message': f'Client {request.user_id} updated successfully'
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


@https_fn.on_call()
def delete_client(req: https_fn.CallableRequest) -> dict:
    """
    Delete client (soft delete by default, hard delete removes from Auth)
    Only admins can call this
    """
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
        
        return {
            'success': True,
            'message': message
        }
        
    except https_fn.HttpsError:
        raise
    except Exception as e:
        print(f"Error in delete_client: {str(e)}")
        print(traceback.format_exc())
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Internal error: {str(e)}"
        )


# ============================================================================
# Shared User Functions
# ============================================================================

@https_fn.on_call()
def reset_user_password(req: https_fn.CallableRequest) -> dict:
    """
    Reset user password (sends password reset email)
    Only admins can call this
    Works for both employees and clients
    """
    try:
        # Verify admin
        admin, error = verify_admin(req)
        if admin is None or not admin.can_modify():
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message=error or "User is not authorized"
            )
        
        user_id = req.data.get('userId')
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


@https_fn.on_call()
def update_user_email(req: https_fn.CallableRequest) -> dict:
    """
    Update user email (updates both Auth and Firestore)
    Only admins can call this
    Works for both employees and clients
    """
    try:
        # Verify admin
        admin, error = verify_admin(req)
        if req.auth is None or admin is None or not admin.can_modify():
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message=error or "User is not authorized"
            )
        
        user_id = req.data.get('userId')
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
        
        return {
            'success': True,
            'message': f'Email updated to {new_email}'
        }
        
    except https_fn.HttpsError:
        raise
    except Exception as e:
        print(f"Error in update_user_email: {str(e)}")
        print(traceback.format_exc())
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Internal error: {str(e)}"
        )

