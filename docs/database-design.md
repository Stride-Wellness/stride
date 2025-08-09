# Stride Database Design

## Overview
This document outlines the Firestore database structure for the Stride elderly care support app. The design supports a multi-tenant architecture where businesses purchase seats, manage employees, and serve elderly clients with personalized exercise programs.

## Design Principles

1. **Multi-tenancy**: Each business operates independently with their own data isolation
2. **Role-based access**: Clear separation between Admins, Managers, PSWs, and Clients
3. **Scalability**: Structure supports businesses of all sizes (single user to large retirement homes)
4. **Security**: Firestore security rules can enforce proper access control
5. **Flexibility**: Supports various business models (family care, retirement homes, etc.)

## Collections Structure

### 1. Organizations
**Collection:** `organizations`
**Purpose:** Represents businesses that purchase Stride

```javascript
{
  id: "org_12345",
  name: "Sunset Retirement Homes",
  totalSeats: 50,
  usedSeats: 35,
  status: "active", // active, suspended, cancelled
  stripeUserId: "id"
  settings: {
    "not sure what will go here yet"
  },
  createdAt: timestamp,
  updatedAt: timestamp
}
```

**Design Decision:** Organizations are the top-level tenant boundary. All other data is scoped to an organization, enabling complete data isolation and independent billing.

### 2. Users
**Collection:** `users`
**Purpose:** All users in the system (Admins, Managers, PSWs, Clients)

```javascript
{
  id: "user_67890",
  email: "john.doe@example.com",
  name: "John Doe",
  role: "psw", // admin, manager, psw, client
  organizationId: "org_12345",
  profile: {
    phone: "+1234567890",
    dateOfBirth: "1990-05-15", // For clients, important for exercise customization
    emergencyContact: {
      name: "Jane Doe",
      phone: "+1234567891",
      relationship: "daughter"
    },
    medicalInfo: {
      conditions: ["arthritis", "diabetes"],
      medications: ["metformin"],
      mobility: "walker", // independent, cane, walker, wheelchair
      notes: "Prefers morning exercises"
    }
  },
  permissions: {
    canManageUsers: false,
    canViewAllClients: false,
    assignedLocations: ["location_123"] // For managers assigned to specific homes
  },
  status: "active", // active, inactive, pending
  lastLoginAt: timestamp,
  createdAt: timestamp,
  updatedAt: timestamp
}
```

**Design Decision:** Single users collection with role-based differentiation simplifies authentication and user management. Medical info is included for clients to inform exercise recommendations.

### 3. Divisions
**Collection:** `locations`
**Purpose:** A sub catagory of a organization, employees are grouped into divisions. A manager can manage 1 or more divisions.

```javascript
{
  id: "location_123",
  organizationId: "org_12345",
  name: "Sunset Manor East",
  address: {
    street: "456 Oak Ave",
    city: "Springfield",
    state: "CA",
    zipCode: "90211"
  },
  managerId: "user_manager1", // Primary manager for this location
  capacity: 100,
  currentResidents: 75,
  settings: {
    operatingHours: {
      start: "08:00",
      end: "20:00"
    },
    exerciseRooms: ["Main Hall", "Therapy Room A"]
  },
  createdAt: timestamp,
  updatedAt: timestamp
}
```

**Design Decision:** Separate locations collection supports multi-location businesses and enables location-specific management and reporting.

### 4. Client-Worker Assignments
**Collection:** `assigenments`
**Purpose:** Links PSWs to their assigned clients

```javascript
{
  id: "assignment_789",
  organizationId: "org_12345",
  clientId: "user_client1",
  workerId: "user_psw1",
  locationId: "location_123",
  assignedBy: "user_manager1",
  status: "active", // active, inactive, completed
  permissions: {
    canModifyExercises: true,
    canViewMedicalInfo: true,
    canScheduleSessions: true
  },
  assignedAt: timestamp,
  lastSessionAt: timestamp
}
```

**Design Decision:** Explicit assignment collection provides flexible many-to-many relationships between PSWs and clients, with granular permissions and audit trails.

### 5. Assessments
**Collection:** `assessments`
**Purpose:** Initial intake forms and periodic reassessments

```javascript
{
  id: "assessment_456",
  organizationId: "org_12345",
  clientId: "user_client1",
  conductedBy: "user_psw1",
  type: "initial", // initial, reassessment, progress
  responses: {
    goals: ["improve balance", "increase strength", "reduce pain"],
    currentActivity: "light walking 2x/week",
    painLevel: 3, // 1-10 scale
    fallHistory: false,
    preferredActivities: ["chair exercises", "walking"],
    concerns: ["fear of falling", "joint pain"],
    mobilityAids: ["walker"],
    cognitiveStatus: "alert"
  },
  aiRecommendations: {
    focusAreas: ["balance", "strength"],
    cautions: ["avoid high impact"],
    frequency: "3x/week",
    duration: "20-30 minutes"
  },
  status: "completed", // draft, completed, reviewed
  completedAt: timestamp,
  createdAt: timestamp
}
```

**Design Decision:** Assessments capture both structured data for AI processing and free-form responses for personalization. AI recommendations are stored for audit and refinement.

### 6. NOT USING FOR NOW Exercise Programs
**Collection:** `exercisePrograms`
**Purpose:** AI-generated personalized exercise programs

```javascript
{
  id: "program_789",
  organizationId: "org_12345",
  clientId: "user_client1",
  assessmentId: "assessment_456",
  createdBy: "user_psw1", // PSW who requested the program
  program: {
    name: "Balance & Strength for Joe",
    duration: "4 weeks",
    frequency: "3x/week",
    exercises: [
      {
        id: "ex_001",
        name: "Seated Leg Extensions",
        description: "Strengthen quadriceps while seated",
        sets: 2,
        reps: 10,
        duration: null,
        restTime: "30 seconds",
        equipment: ["chair"],
        difficulty: "beginner",
        targetAreas: ["legs", "strength"],
        instructions: [
          "Sit in sturdy chair with back straight",
          "Slowly extend one leg straight out",
          "Hold for 2 seconds, lower slowly"
        ],
        mediaUrl: "gs://stride-exercises/seated-leg-extensions.gif",
        modifications: {
          easier: "Partial extension only",
          harder: "Add ankle weights"
        },
        cautions: ["Stop if knee pain occurs"]
      }
    ],
    progressionPlan: {
      week1: "Focus on form, low intensity",
      week2: "Increase repetitions",
      week3: "Add resistance",
      week4: "Prepare for reassessment"
    }
  },
  aiMetadata: {
    model: "gpt-4",
    prompt: "Create exercises for 75yo with arthritis...",
    confidence: 0.85,
    generatedAt: timestamp
  },
  status: "active", // draft, active, completed, archived
  approvedBy: "user_manager1", // Optional manager approval
  createdAt: timestamp,
  updatedAt: timestamp
}
```

**Design Decision:** Programs store complete exercise details with rich metadata for tracking, progression, and safety. AI generation details are preserved for quality improvement.



**Design Decision:** Detailed session tracking enables progress monitoring, safety tracking, and program refinement. Both objective and subjective measures are captured.

### 8. Exercise Library
**Collection:** `exercises`
**Purpose:** Master library of available exercises

```javascript
{
  id: "lib_ex_001",
  name: "Seated Leg Extensions",
  category: "strength",
  targetAreas: ["quadriceps", "balance"],
  difficulty: "beginner",
  equipment: ["chair"],
  duration: "2-3 minutes",
  description: "Strengthen leg muscles while seated safely",
  instructions: [...],
  mediaUrl: "gs://stride-exercises/seated-leg-extensions.gif",
  contraindications: ["recent knee surgery", "severe arthritis flare"],
  benefits: ["leg strength", "knee stability"],
  modifications: {
    easier: "Partial range of motion",
    harder: "Add ankle weights",
    wheelchair: "Focus on ankle flexion"
  },
  tags: ["senior-friendly", "chair-based", "no-equipment"],
  approvedBy: "clinical-team",
  lastReviewed: timestamp,
  createdAt: timestamp
}
```

**Design Decision:** Centralized exercise library enables consistency, quality control, and easy updates across all programs.

## Subcollections

### Organization Invitations
**Subcollection:** `organizations/{orgId}/invitations`
**Purpose:** Manage user invitations to join an organization

```javascript
{
  id: "invite_123",
  email: "newuser@example.com",
  role: "psw",
  invitedBy: "user_manager1",
  locationId: "location_123", // Optional
  status: "pending", // pending, accepted, expired
  expiresAt: timestamp,
  createdAt: timestamp
}
```

### User Activity Log
**Subcollection:** `users/{userId}/activityLog`
**Purpose:** Audit trail of user actions

```javascript
{
  id: "activity_123",
  action: "session_completed",
  details: {
    sessionId: "session_123",
    clientName: "Joe Smith"
  },
  timestamp: timestamp,
  ipAddress: "192.168.1.1"
}
```

### Client Progress Reports
**Subcollection:** `users/{clientId}/progressReports`
**Purpose:** Generated progress summaries

```javascript
{
  id: "report_123",
  period: "monthly",
  startDate: "2025-07-01",
  endDate: "2025-07-31",
  metrics: {
    sessionsCompleted: 12,
    averagePainLevel: 2.5,
    improvementAreas: ["balance", "confidence"],
    concernAreas: ["fatigue"]
  },
  generatedBy: "ai",
  reviewedBy: "user_psw1",
  sharedWith: ["user_manager1"],
  createdAt: timestamp
}
```

## Indexes Required

1. **users**: 
   - `organizationId` + `role`
   - `organizationId` + `status`

2. **clientAssignments**: 
   - `organizationId` + `workerId`
   - `organizationId` + `clientId`
   - `organizationId` + `status`

3. **exerciseSessions**: 
   - `organizationId` + `clientId` + `createdAt`
   - `organizationId` + `conductedBy` + `createdAt`

4. **assessments**: 
   - `organizationId` + `clientId` + `createdAt`

## Security Considerations

1. **Organization Isolation**: All queries must filter by `organizationId`
2. **Role-based Access**: Firestore rules enforce role permissions
3. **Data Encryption**: Sensitive medical data encrypted at rest
4. **Audit Trails**: All modifications logged in activity subcollections
5. **HIPAA Compliance**: Medical information properly segregated and protected

## Rationale for Key Decisions

1. **Single Users Collection**: Simplifies authentication and reduces complexity while supporting role-based access through the `role` field.

2. **Organization-centric Design**: Every document includes `organizationId` for clean multi-tenancy and data isolation.

3. **Flexible Assignment System**: The `clientAssignments` collection supports complex scenarios like multiple PSWs per client or PSWs covering multiple locations.

4. **Rich Exercise Data**: Detailed exercise information supports AI improvements and ensures safety through proper instruction and contraindication tracking.

5. **Session Granularity**: Individual session tracking enables detailed progress monitoring and helps identify patterns for better care.

6. **Subcollections for Related Data**: Activity logs and progress reports use subcollections to keep the main collections focused while providing detailed audit capabilities.

This design supports your use cases from simple family care (one admin managing one client) to complex retirement home operations (multiple locations, managers, PSWs, and clients) while maintaining data integrity and enabling future feature expansion.