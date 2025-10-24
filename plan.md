# Development Plan

This document outlines the cooperative development of Stride. The app will be developed on a contractual basis.

## Compensation

The pay for this project should be $5,000 and 7% equity.

**Payment Schedule:**
All payments and equity transfers are due within 7 days of phase completion.

- Phase 0 completion: $500 + 1% undilutable equity
- Phase 1 completion: $1,500 + 1% undilutable equity
- Phase 2 completion: $2,000 + 2% undilutable equity
- Phase 3 completion: $1,000 + 2% undilutable equity
- Maintenance post launch: 1% undilutable equity + salary (tbd).

**Undilutable Equity Definition:** Equity that cannot be reduced in percentage through future investment rounds or stock issuances.

**Payment Default:** If payment cannot be made within the agreed timeframe, development will be halted until payment is received. Timeline extensions will apply without penalty to developer.

## Responsibilities

**Developer responsibilities:** All technical implementation, setup, and deployment
**Business owner responsibilities:** Content creation, user testing coordination, business setup, and market validation 

## Developer Project Overview

The product has 2 main part and 1 supporting parts:

1. **Backend (main)** - Firebase setup for authentication, database, and cloud functions to generate exercises. This will include a complementary admin dashboard to manage the backend.

3. **Mobile app (main)** - Where clients fill out forms, discuss their health, and see exercises. This will be as simple and basic as possible

4. **Provider Dashboard (supporting)**: A simple, basic dashboard to provide the bare minimum functionality for organizations to manage their providers. This will not be the focus of development but is required for a full functioning user flow so it will be complementary.

## Definitions:

**Organization**: A group of homecare provider businesses or retirement homes.

**Provider**: A person employed to a business under an organization.

**Manager**: A type of provider who can manage one or multiple businesses in an organization. This person is responsible for managing providers in their business.

**Organization Admin**: A type of manager who can manage managers, and perform all other tasks. This person is responsible for billing.

**Client:** An elderly adult who is, or has the potential to be (registered in stride db) receiving stride from an provider.

## Timeline

This section outlines the projected timeline of the project and corresponding deliverables. The timeline is subject to change if there are valid reasons. 

### Phase 0 - Project Setup and Design (1 week)

This stage will be used to refine and clarify project parameters and requirements.

**Developer tasks:**

- Set up Firebase database and authentication
- Basic project structure and development environment
- Set up hosting and deployment pipeline
- Set up other accounts including app store and domain name

**Business owner tasks (required for developer to proceed):**

- Define the main UI pages - what general info to show, rough layout (iPad sketches/mockups) for both website and mobile app

By the end of this phase, there should be a rough definition of all UI pages, with names and roles for each. All user types and roles should be defined, and all user interactions should be mapped out. The Project Overview should be polished and complete.


### Phase 1 - Authentication and User Management (2 weeks)

This section will target connecting the backend and front ends with basic authentaction. This means sign in/out, and account pages for the web app for retirement homes / homecare provider managers and org admins. And for providers (PSW/LW/EA) mobile apps.

**Developer tasks:**

- Build authentication system for both web and mobile
- Create user account management interfaces
- Implement provider dashboard with client list and basic information
- Set up client-provider relationship management

By the end of this section, both clients and providers should be able to make accounts on a simple UI. Org managers should be able to add/remove/manage clients and see personal data.

**Important questions to resolve:**

- How would large organizations be managed with multiple providers? 
- Should there be an organization data structure? 
- Can an organization have multiple providers? 

### Phase 2 - Exercise Creation Logic (2 weeks)

Add the core functionality. Implement working logic that takes user input/quiz feedback and generates a list of exercises. These exercises are confirmed with the provider, then sent to the client.

**Developer tasks:**

- Build backend logic to generate exercises using AI/automation
- Create provider approval workflow - allow providers to intervene and modify exercises
- Create client interface to view exercises as a formatted list and mark them as complete, or allow their assigned provider to do this on their behalf.

**Business tasks:**

- Provide exercise content sources or GIF libraries
- Test exercise generation quality and provide feedback
- Define what client input/quiz format should look like

This section will implement the backend logic to generate exercises, allow providers to intervene if they would like to, and then forward them to the client. On the frontend, there will be basic management pages for providers to see and manage client exercises.

Clients should be able to view their exercises in a basic, formatted list and mark them as complete.

This section marks the completion of the initial prototype, showing off core functionality.



### Phase 3 - Polish and Launch (2 weeks)

This should result in a close to polished interface for providers and clients, including GIF integration for generated exercises. Simple, clean UI for users on the mobile app.

**Developer tasks:**

- UI/UX improvements and polish
- GIF integration for exercises  
- Mobile app store submission
- Bug fixes and performance optimization
- Production deployment

**Business owner tasks:**

- Coordinate final testing with beta users
- Prepare marketing materials and app store listings
- Set up customer support processes
- Handle legal/business requirements for launch

### Phase 4 - Testing and Iteration (1 week)

Direct feedback and improvement based on real user testing.


## Development Break
**August 25 - September 25, 2025**
*Developer unavailable due to personal travel. Minimal work possible but no deliverable deadlines during this period. Timeline pauses - no compensation penalties for delays during this month.*


## Project Completion Terms & Performance Agreement

### Timeline Adherence and Compensation Adjustments

**Unforeseen Project-Related Delays:**
If a phase takes longer due to legitimate project complexities (e.g., technical challenges, scope changes requested by business owner, third-party integration issues), additional compensation will be negotiated at $50/hour for extra time required, this cost will be split between the developer and business owner.

**Developer Performance Issues:**
If delays are caused by developer underperformance or lack of progress without valid project-related reasons:

- **1-14 days late:** Warning, no compensation adjustment
- **14+ days late:** 20% reduction in phase payment + potential project termination

**Business Owner Delays:**
If business owner fails to provide required materials/feedback within agreed timeframes, timeline extends accordingly without penalty to developer.

**Scheduled Developer Absence:**
During the pre-planned development break (August 25 - September 25, 2025), no work deliverables are expected and no compensation penalties apply for project delays during this period. Timeline automatically pauses and resumes September 26th.

### Project Termination Conditions

**Developer Termination:**

- Failure to deliver working functionality for any phase after 2 weeks past deadline without reason
- Abandonment of project without 1-week notice
- Compensation: Only paid for completed phases, no equity transfer for current phase.

**Business Owner Termination:**

- Can terminate project at any time with 1-week notice
- Developer receives full payment for completed phases + prorated payment for current phase work + earned equity up to that point

**Mutual Termination:**

- Either party can request termination if project scope changes significantly
- Fair compensation negotiated based on work completed

### Intellectual Property Rights

**Code Ownership:** All code, technical documentation, and development work created by the developer during this project remains owned by the business owner upon payment completion for each phase.

**Developer Rights:** Developer retains the right to use general programming techniques, methodologies, and non-proprietary knowledge gained during the project in future work. Developer may reference the project in portfolio/resume.

**Open Source Components:** Any open source libraries or frameworks used remain under their respective licenses.

### Agreement Acceptance

Both parties agree to these terms by proceeding with Phase 0. Any modifications to this agreement must be documented in writing and agreed upon by both parties.

Levi Rogalla:

Sam Pencer:
