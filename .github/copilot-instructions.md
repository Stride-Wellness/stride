# Stride AI Helper Notes

## Monorepo layout

Firebase cloud function in Python at `functions/main.py`. The function available, at a high level, are:
- create_provider: This function takes a validated provider creation request as input (name, email, etc.), verifies the caller is an admin with modify privileges, and creates a new provider in Firebase Auth and Firestore. This function returns success status, userId, and a message.
- update_provider: This function takes a validated provider update request (user_id, updated fields), verifies admin privileges, and updates provider data in Firestore. This function returns success status and a message.
- create_client: This function takes a validated client creation request (name, email, etc.), verifies admin privileges, and creates a new client in Firebase Auth and Firestore. This function returns success status, userId, and a message.
- update_client: This function takes a validated client update request (user_id, updated fields), verifies admin privileges, and updates client data in Firestore. This function returns success status and a message.
- get_users: This function takes a validated user query request (filters: IDs, organization, division, type, status, limit), verifies admin privileges, and fetches users (providers and clients) with Auth metadata. This function returns success status, a list of users, and count.
- get_user_by_id: This function takes a userId as input, verifies admin privileges, and fetches a single user (provider or client) by ID with Auth metadata. This function returns success status and the user object.
- get_user_stats: This function takes an optional organizationId as input, verifies admin privileges, and returns user statistics (counts by type, status, etc.). This function returns success status and stats.
- delete_user: This function takes a validated delete user request (user_id, hard_delete flag), verifies admin privileges, and deletes a user (soft or hard delete). This function returns success status and a message.
- create_admin: This function takes a validated admin creation request (name, privilege), verifies admin privileges, and creates a new admin in Firebase Auth and Firestore. This function returns success status, userId, and a message.
- update_admin: This function takes a validated admin update request (user_id, updated fields), verifies admin privileges, and updates admin data in Firestore. This function returns success status and a message.
- delete_admin: This function takes a validated delete admin request (user_id), verifies admin privileges, and deletes an admin (hard delete). This function returns success status and a message.
- get_admins: This function takes a validated admin query request (filters: IDs, privilege level, limit), verifies admin privileges, and fetches admin users with Auth metadata. This function returns success status, a list of admins, and count.
- get_admin_by_id: This function takes a userId as input, verifies admin privileges, and fetches a single admin by ID with Auth metadata. This function returns success status and the admin object.
- reset_user_password: This function takes a userId as input, verifies admin privileges, and generates a password reset link for the user. This function returns success status, a message, and the reset link.
- update_user_email: This function takes userId and newEmail as input, verifies admin privileges, and updates the user's email in Auth and Firestore. This function returns success status and a message.
- generate_exercise_plan: This function takes a validated exercise plan request (user_id, assessment_id, user_requests), verifies the user is authenticated, calls AI to generate an exercise plan, saves exercises to Firestore, and returns success status, exercises, exerciseIds, and count.

`stride_admin` is currently not up to date and not being used, I plan to convert it all to flutter.

`stride_admin2` contains the new flutter based dev admin dashboard fire simple CRUD operations.

`stride_app` is the main flutter app.

`stride_web` will be the flutter web app.

`packages/stride_core` holds all shared core logic dart code for stride_app and stride_web to use. it has models, repositories, and services. There are models for all the main data objects (User, Admin, Exercise, Assignment, Division, Organization, Invitation). The repositories are Admin, Assignments, Divisions, Exercise, Invitation, Organization, and User. And the services are auth_service, and firebase_config.

`packages/stride_ui` defines a constant theme for all apps to use, and shared widgets, as well as style constants.

make sure you update this file too if any of this changes!