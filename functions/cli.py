import os
import requests
import json
import argparse
from typing import Optional
from getpass import getpass

# ============================================================================
# Configuration
# ============================================================================

# Update these with your Firebase project details
PROJECT_ID = "stride-c054b"  # Replace with your project ID
REGION = "us-central1"  # Default region, change if needed
TOKEN_FILE = os.path.relpath("./.stride_cli_token")

# Cloud Functions base URL
BASE_URL = f"https://{REGION}-{PROJECT_ID}.cloudfunctions.net"

# Store auth token (in production, use proper auth)
AUTH_TOKEN: Optional[str] = None


# ============================================================================
# Helper Functions
# ============================================================================

def call_function(function_name: str, data: dict) -> dict:
    """Call a Cloud Function via HTTPS"""
    url = f"{BASE_URL}/{function_name}"
    
    headers = {
        "Content-Type": "application/json",
    }
    
    # Add auth token if available (check global, then file)
    global AUTH_TOKEN
    if not AUTH_TOKEN:
        AUTH_TOKEN = load_token()
    
    if AUTH_TOKEN:
        headers["Authorization"] = f"Bearer {AUTH_TOKEN}"
        
    url = f"{BASE_URL}/{function_name}"
    
    headers = {
        "Content-Type": "application/json",
    }
    
    # Add auth token if available
    if AUTH_TOKEN:
        headers["Authorization"] = f"Bearer {AUTH_TOKEN}"
    
    # Cloud Functions use a specific request format
    payload = {
        "data": data
    }
    
    try:
        response = requests.post(url, json=payload, headers=headers)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"❌ Error calling function: {e}")
        if hasattr(e, 'response') and e.response is not None:
            print(f"Response: {e.response.text}")
        return {"error": str(e)}


def print_result(result: dict):
    """Pretty print result"""
    print("\n" + "="*60)
    print("RESULT:")
    print("="*60)
    print(json.dumps(result, indent=2, default=str))
    print("="*60 + "\n")


# ============================================================================
# Provider Commands
# ============================================================================

def create_provider(args):
    """Create a new provider"""
    print(f"Creating provider: {args.name}")
    
    data = {
        "email": args.email,
        "password": args.password or getpass("Enter password: "),
        "name": args.name,
        "organization_id": args.org_id,
        "division_id": args.division_id,
        "provider_role": args.roles.split(",")
    }
    
    result = call_function("create_provider", data)
    print_result(result)


def update_provider(args):
    """Update an provider"""
    print(f"Updating provider: {args.user_id}")
    
    data = {"user_id": args.user_id}
    
    if args.name:
        data["name"] = args.name
    if args.status:
        data["status"] = args.status
    if args.roles:
        data["provider_role"] = args.roles.split(",")
    if args.profile:
        data["profile"] = json.loads(args.profile)
    
    result = call_function("update_provider", data)
    print_result(result)


def delete_provider(args):
    """Delete an provider"""
    print(f"Deleting provider: {args.user_id}")
    
    confirm = input(f"⚠️  Are you sure you want to {'PERMANENTLY' if args.hard else 'soft'} delete this provider? (yes/no): ")
    if confirm.lower() != 'yes':
        print("❌ Cancelled")
        return
    
    data = {
        "user_id": args.user_id,
        "hard_delete": args.hard
    }
    
    result = call_function("delete_provider", data)
    print_result(result)


# ============================================================================
# Client Commands
# ============================================================================

def create_client(args):
    """Create a new client"""
    print(f"Creating client: {args.name}")
    
    data = {
        "email": args.email,
        "password": args.password or getpass("Enter password: "),
        "name": args.name,
        "organization_id": args.org_id,
        "division_id": args.division_id,
    }
    
    if args.phone:
        data["phone"] = args.phone
    if args.dob:
        data["date_of_birth"] = args.dob
    
    result = call_function("create_client", data)
    print_result(result)


def update_client(args):
    """Update a client"""
    print(f"Updating client: {args.user_id}")
    
    data = {"user_id": args.user_id}
    
    if args.name:
        data["name"] = args.name
    if args.status:
        data["status"] = args.status
    if args.profile:
        data["profile"] = json.loads(args.profile)
    
    result = call_function("update_client", data)
    print_result(result)


def delete_client(args):
    """Delete a client"""
    print(f"Deleting client: {args.user_id}")
    
    confirm = input(f"⚠️  Are you sure you want to {'PERMANENTLY' if args.hard else 'soft'} delete this client? (yes/no): ")
    if confirm.lower() != 'yes':
        print("❌ Cancelled")
        return
    
    data = {
        "user_id": args.user_id,
        "hard_delete": args.hard
    }
    
    result = call_function("delete_client", data)
    print_result(result)


# ============================================================================
# Shared User Commands
# ============================================================================

def reset_password(args):
    """Reset user password"""
    print(f"Resetting password for: {args.user_id}")
    
    data = {"userId": args.user_id}
    
    result = call_function("reset_user_password", data)
    print_result(result)


def update_email(args):
    """Update user email"""
    print(f"Updating email for: {args.user_id}")
    
    data = {
        "userId": args.user_id,
        "newEmail": args.new_email
    }
    
    result = call_function("update_user_email", data)
    print_result(result)


# ============================================================================
# Setup Commands
# ============================================================================

# Add this helper function after print_result()
def save_token(token: str):
    """Save auth token to file"""
    try:
        with open(TOKEN_FILE, 'w') as f:
            f.write(token)
        os.chmod(TOKEN_FILE, 0o600)  # Secure file permissions
        print(f"✅ Token saved to {TOKEN_FILE}")
    except Exception as e:
        print(f"⚠️  Failed to save token: {e}")


def load_token() -> Optional[str]:
    """Load auth token from file"""
    try:
        if os.path.exists(TOKEN_FILE):
            with open(TOKEN_FILE, 'r') as f:
                return f.read().strip()
    except Exception as e:
        print(f"⚠️  Failed to load token: {e}")
    return None


def login(args):
    """Login user via Firebase Auth"""
    print(f"Logging in user: {args.email}")
    
    # Get Firebase API key from environment or use default
    api_key = os.getenv("FIREBASE_API_KEY", "AIzaSyArV5iONaf2fsWtmqfDBU907NJ3FRi_P54")
    
    # Firebase Auth REST API endpoint
    url = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={api_key}"
    
    payload = {
        "email": args.email,
        "password": args.password or getpass("Enter password: "),
        "returnSecureToken": True
    }
    
    try:
        response = requests.post(url, json=payload)
        response.raise_for_status()
        
        result = response.json()
        
        # Extract and save the ID token
        id_token = result.get("idToken")
        if id_token:
            global AUTH_TOKEN
            AUTH_TOKEN = id_token
            save_token(id_token)
            
            print("\n✅ Login successful!")
            print(f"User ID: {result.get('localId')}")
            print(f"Email: {result.get('email')}")
            print(f"Token expires in: {result.get('expiresIn')} seconds")
        else:
            print("❌ No token received")
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Login failed: {e}")
        if hasattr(e, 'response') and e.response is not None:
            error_data = e.response.json()
            error_message = error_data.get('error', {}).get('message', 'Unknown error')
            print(f"Error: {error_message}")

# ============================================================================
# Main CLI
# ============================================================================

def main():
    parser = argparse.ArgumentParser(
        description="CLI for testing Stride Cloud Functions",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Configure project
  python cli.py config --project-id my-project --region us-central1
  
  # Create provider
  python cli.py provider create --email john@example.com --name "John Doe" \\
    --org-id org123 --division-id div123 --roles "manager,psw"
  
  # Create client
  python cli.py client create --email jane@example.com --name "Jane Smith" \\
    --org-id org123 --division-id div123 --phone "555-1234"
  
  # Update provider
  python cli.py provider update --user-id user123 --name "John Smith" --status active
  
  # Delete client (soft delete)
  python cli.py client delete --user-id user456
  
  # Reset password
  python cli.py user reset-password --user-id user123
  
  # Update email
  python cli.py user update-email --user-id user123 --new-email newemail@example.com
        """
    )
    
    subparsers = parser.add_subparsers(dest='command', help='Commands')
    
    # ========================================================================
    # Config commands
    # ========================================================================

    # Add login command
    login_parser = subparsers.add_parser('login', help='Login with email/password')
    login_parser.add_argument('--email', required=True, help='Email address')
    login_parser.add_argument('--password', help='Password (will prompt if not provided)')
    login_parser.set_defaults(func=login)

    # ========================================================================
    # Provider commands
    # ========================================================================
    provider_parser = subparsers.add_parser('provider', help='Provider commands')
    provider_subparsers = provider_parser.add_subparsers(dest='provider_command')
    
    # Create provider
    emp_create = provider_subparsers.add_parser('create', help='Create provider')
    emp_create.add_argument('--email', required=True, help='Email address')
    emp_create.add_argument('--password', help='Password (will prompt if not provided)')
    emp_create.add_argument('--name', required=True, help='Full name')
    emp_create.add_argument('--org-id', required=True, help='Organization ID')
    emp_create.add_argument('--division-id', required=True, help='Division ID')
    emp_create.add_argument('--roles', required=True, help='Comma-separated roles (psw,lw,admin,manager)')
    emp_create.set_defaults(func=create_provider)
    
    # Update provider
    emp_update = provider_subparsers.add_parser('update', help='Update provider')
    emp_update.add_argument('--user-id', required=True, help='User ID')
    emp_update.add_argument('--name', help='New name')
    emp_update.add_argument('--status', help='New status (active,inactive,pending,deleted)')
    emp_update.add_argument('--roles', help='Comma-separated roles')
    emp_update.add_argument('--profile', help='Profile JSON string')
    emp_update.set_defaults(func=update_provider)
    
    # Delete provider
    emp_delete = provider_subparsers.add_parser('delete', help='Delete provider')
    emp_delete.add_argument('--user-id', required=True, help='User ID')
    emp_delete.add_argument('--hard', action='store_true', help='Hard delete (remove from Auth)')
    emp_delete.set_defaults(func=delete_provider)
    
    # ========================================================================
    # Client commands
    # ========================================================================
    client_parser = subparsers.add_parser('client', help='Client commands')
    client_subparsers = client_parser.add_subparsers(dest='client_command')
    
    # Create client
    cli_create = client_subparsers.add_parser('create', help='Create client')
    cli_create.add_argument('--email', required=True, help='Email address')
    cli_create.add_argument('--password', help='Password (will prompt if not provided)')
    cli_create.add_argument('--name', required=True, help='Full name')
    cli_create.add_argument('--org-id', required=True, help='Organization ID')
    cli_create.add_argument('--division-id', required=True, help='Division ID')
    cli_create.add_argument('--phone', help='Phone number')
    cli_create.add_argument('--dob', help='Date of birth (YYYY-MM-DD)')
    cli_create.set_defaults(func=create_client)
    
    # Update client
    cli_update = client_subparsers.add_parser('update', help='Update client')
    cli_update.add_argument('--user-id', required=True, help='User ID')
    cli_update.add_argument('--name', help='New name')
    cli_update.add_argument('--status', help='New status (active,inactive,pending,deleted)')
    cli_update.add_argument('--profile', help='Profile JSON string')
    cli_update.set_defaults(func=update_client)
    
    # Delete client
    cli_delete = client_subparsers.add_parser('delete', help='Delete client')
    cli_delete.add_argument('--user-id', required=True, help='User ID')
    cli_delete.add_argument('--hard', action='store_true', help='Hard delete (remove from Auth)')
    cli_delete.set_defaults(func=delete_client)
    
    # ========================================================================
    # User commands (shared)
    # ========================================================================
    user_parser = subparsers.add_parser('user', help='User commands (shared)')
    user_subparsers = user_parser.add_subparsers(dest='user_command')
    
    # Reset password
    user_reset = user_subparsers.add_parser('reset-password', help='Reset user password')
    user_reset.add_argument('--user-id', required=True, help='User ID')
    user_reset.set_defaults(func=reset_password)
    
    # Update email
    user_email = user_subparsers.add_parser('update-email', help='Update user email')
    user_email.add_argument('--user-id', required=True, help='User ID')
    user_email.add_argument('--new-email', required=True, help='New email address')
    user_email.set_defaults(func=update_email)
    
    # ========================================================================
    # Parse and execute
    # ========================================================================
    args = parser.parse_args()
    
    if hasattr(args, 'func'):
        args.func(args)
    else:
        parser.print_help()


if __name__ == '__main__':
    print("""
╔══════════════════════════════════════════════════════════════╗
║              Stride Cloud Functions CLI Tool                 ║
╚══════════════════════════════════════════════════════════════╝
    """)
    main()