# User Service Documentation

This document describes the new Firebase-based user service that mirrors the TypeScript user service from the web application.

## Overview

The `UsersService` class provides comprehensive user management functionality with Firebase Firestore as the backend. It supports both provider and client users with different roles and profiles.

## User Types

### Provider Users
- **Type**: `provider`
- **Roles**: PSW, LW, Admin, Manager
- **Profile**: Flexible key-value pairs for additional provider data

### Client Users
- **Type**: `client`
- **Profile**: Structured profile with phone, date of birth, emergency contact, and medical information

## Key Classes

### Core Models
- `User`: Union type that can be either ProviderUser or ClientUser
- `ProviderUser`: User with provider-specific fields
- `ClientUser`: User with client-specific fields
- `EmergencyContact`: Contact information for emergencies
- `MedicalInfo`: Medical conditions, medications, and mobility information

### Data Transfer Objects
- `CreateProviderUserData`: Data required to create an provider
- `CreateClientUserData`: Data required to create a client
- `UpdateProviderUserData`: Data for updating provider information
- `UpdateClientUserData`: Data for updating client information

## Usage Examples

### 1. Creating Users

#### Create an Provider
```dart
final providerData = CreateProviderUserData(
  email: 'john.doe@example.com',
  name: 'John Doe',
  organizationId: 'org123',
  divisionId: 'div456',
  providerRole: [ProviderRole.psw, ProviderRole.admin],
  profile: {
    'phoneNumber': '+1234567890',
    'department': 'Care Services',
  },
);

final provider = await UsersService.createProvider(providerData);
```

#### Create a Client
```dart
final clientProfile = ClientProfile(
  phone: '+1987654321',
  dateOfBirth: '1950-01-15',
  emergencyContact: EmergencyContact(
    name: 'Jane Doe',
    phone: '+1555123456',
    relationship: 'Daughter',
  ),
  medicalInfo: MedicalInfo(
    conditions: ['Diabetes'],
    medications: ['Metformin'],
    mobility: Mobility.walker,
    notes: 'Requires assistance',
  ),
);

final clientData = CreateClientUserData(
  email: 'mary.smith@example.com',
  name: 'Mary Smith',
  organizationId: 'org123',
  divisionId: 'div456',
  profile: clientProfile,
);

final client = await UsersService.createClient(clientData);
```

### 2. Retrieving Users

#### Get User by ID
```dart
final user = await UsersService.getById('user_id_here');
if (user != null) {
  print('Found user: ${user.name}');
}
```

#### Get Users by Organization
```dart
final users = await UsersService.getByOrganizationId('org123');
for (final user in users) {
  print('User: ${user.name} (${user.type.name})');
}
```

#### Get Users by Type and Organization
```dart
final providers = await UsersService.getByTypeAndOrganization(
  UserType.provider,
  'org123',
);
```

#### Get Users by Status
```dart
final activeUsers = await UsersService.getByStatusAndOrganization(
  UserStatus.active,
  'org123',
);
```

### 3. Updating Users

#### Update Provider
```dart
await UsersService.updateProvider('provider_id', UpdateProviderUserData(
  name: 'New Name',
  providerRole: [ProviderRole.manager],
  profile: {'department': 'Management'},
));
```

#### Update Client
```dart
await UsersService.updateClient('client_id', UpdateClientUserData(
  profile: ClientProfile(phone: '+1999888777'),
));
```

### 4. User Status Management

#### Soft Delete (Recommended)
```dart
await UsersService.softDelete('user_id');
```

#### Restore Deleted User
```dart
await UsersService.restore('user_id');
```

#### Hard Delete (Use with Caution)
```dart
await UsersService.hardDelete('user_id'); // Only if no active assignments
```

### 5. Utility Functions

#### Check User Type
```dart
if (user.isProvider) {
  final provider = user.asProvider!;
  print('Provider roles: ${provider.providerRole}');
} else if (user.isClient) {
  final client = user.asClient!;
  print('Client phone: ${client.profile.phone}');
}
```

#### Check Provider Role
```dart
if (UsersService.hasRole(user, ProviderRole.admin)) {
  print('User is an admin');
}
```

#### Count Active Users
```dart
final count = await UsersService.countActiveByOrganization('org123');
print('Active users: $count');
```

## Authentication Integration

The service integrates with the existing `UserRepository` for authentication:

```dart
final userRepo = UserRepository();

// Login
await userRepo.loginUser('user_id');

// Get current user (new Firebase version)
final currentUser = await userRepo.getCurrentUser();

// Check login status
if (userRepo.isLoggedIn()) {
  print('User is logged in');
}
```

## Firebase Setup

Ensure Firebase is properly initialized in your app:

```dart
// In main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await FirebaseConfig.initialize();
  
  runApp(MyApp());
}
```

## Migration from Legacy System

The old `UserDataModel` is still supported but deprecated. To migrate:

1. Use `UsersService` instead of `UserRepository` for new code
2. Replace `UserDataModel` with `User`, `ProviderUser`, or `ClientUser`
3. Update creation logic to use proper user types
4. Migrate profile data to structured formats

## Error Handling

All service methods throw exceptions on error. Always wrap calls in try-catch blocks:

```dart
try {
  final user = await UsersService.getById('user_id');
  // Handle success
} catch (error) {
  print('Error: $error');
  // Handle error
}
```

## Performance Considerations

- Use pagination for large user lists (`limitCount` parameter)
- Filter queries to reduce data transfer
- Cache frequently accessed user data
- Use soft delete instead of hard delete for data integrity

## Security Notes

- All Firebase security rules should be properly configured
- User organization and division access should be enforced at the database level
- Sensitive medical information should comply with HIPAA requirements
- Provider role changes should be audited

## Testing

For testing, use the Firebase emulator:

```dart
await FirebaseConfig.initializeForTesting(
  host: 'localhost',
  port: 8080,
);
```

## See Also

- `lib/examples/user_service_example.dart` for complete working examples
- `lib/models/user_m.dart` for detailed model documentation
- `lib/services/firebase_config.dart` for Firebase configuration