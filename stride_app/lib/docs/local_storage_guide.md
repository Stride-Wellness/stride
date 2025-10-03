# Local Storage Guide for Stride App

## Overview

This guide shows you how to use the local storage system for the Stride app to save user data, login state, and app settings.

## Files Created

1. **`/lib/services/storage_service.dart`** - Main storage service using SharedPreferences and Hive
2. **Updated `/lib/repositories/user_repo.dart`** - Repository now uses persistent storage
3. **Updated `/lib/models/user_m.dart`** - Added toMap() method for serialization

## How to Use

### 1. Login a User and Save Their ID

```dart
// In your login logic
final userRepo = context.read<UserRepository>();
bool success = await userRepo.loginUser(userId);
if (success) {
  Navigator.pushReplacementNamed(context, '/home');
}
```

### 2. Check if User is Logged In (App Startup)

```dart
// In your app startup logic
final userRepo = context.read<UserRepository>();

if (userRepo.isLoggedIn()) {
  String? userId = userRepo.getCurrentUserId();
  UserDataModel? currentUser = await userRepo.getCurrentUser();
  // Navigate to home
} else {
  // Navigate to login/onboarding
}
```

### 3. Save User Data After Onboarding

```dart
// After completing onboarding
final userRepo = context.read<UserRepository>();
String? userId = userRepo.getCurrentUserId();

if (userId != null) {
  UserDataModel? user = await userRepo.getUser(userId);
  if (user != null) {
    UserDataModel updatedUser = UserDataModel(
      id: user.id,
      name: user.name,
      email: user.email,
      quizAnswers: onboardingAnswers, // Your quiz answers
    );
    await userRepo.saveUser(updatedUser);
  }
}
```

### 4. Logout User

```dart
final userRepo = context.read<UserRepository>();
bool success = await userRepo.logoutUser();
if (success) {
  Navigator.pushReplacementNamed(context, '/onboarding');
}
```

### 5. Create New User

```dart
final userRepo = context.read<UserRepository>();
bool success = await userRepo.createUser(name: name, email: email);
// User is automatically logged in after creation
```

## Storage Types

- **SharedPreferences**: For simple data like user ID, login status, app settings
- **Hive**: For complex objects like user data, quiz answers
- **In-Memory Cache**: For frequently accessed data (performance)

## Key Methods in UserRepository

- `loginUser(userId)` - Login user and save their ID
- `logoutUser()` - Clear login state
- `getCurrentUserId()` - Get current logged-in user ID
- `isLoggedIn()` - Check login status
- `getCurrentUser()` - Get current user data
- `saveUser(user)` - Save user data
- `getUser(userId)` - Get user by ID

## Data Flow

1. User data is saved to both **cache** (fast access) and **Hive** (persistence)
2. Login state is saved to **SharedPreferences** (survives app restarts)
3. On app startup, check login state and load user data from storage
4. Cache is cleared on logout for security

## Installation

Add to your `pubspec.yaml`:
```yaml
dependencies:
  shared_preferences: ^2.2.2
  hive: ^2.2.3
  hive_flutter: ^1.1.0
```

Then run: `flutter pub get`

## Initialization

The storage is automatically initialized in `main.dart` when the app starts.