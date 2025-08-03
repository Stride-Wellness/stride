# Development Plan

This document outlines the cooperative development of Stride. The app will be developed on a contractual basis.

## Compensation

The pay for this project should be $5,000 and 7% equity.

**Payment Schedule:**
- Phase 0 completion: $500 + 1% equity
- Phase 1 completion: $1,500 + 1% equity  
- Phase 2 completion: $2,000 + 2% equity
- Phase 3 completion: $1,000 + 3% equity (within 2 weeks of project completion)

## Responsibilities

**Developer responsibilities:** All technical implementation, setup, and deployment
**Business owner responsibilities:** Content creation, user testing coordination, business setup, and market validation 

## Project Overview

The product has 4 main parts:

1. **Web provider dashboard** - Manage clients, administer exercises to clients, intervene on client health, and check up on clients
2. **Web dashboard for clients** - See history of exercises, interact with providers, and access more advanced asynchronous features/communication  
3. **Mobile app** - Where clients fill out forms, discuss their health, and see exercises. This will be as simple and basic as possible
4. **Backend** - Simple chatgpt wrapper to create recommended excersies and manage user data (Firebase)

### Other consideration

- How will payment work?
- The content format will be done using gifs to reduce storage complexity and cost.


## Timeline

This section outlines the projected timeline of the project and corresponding deliverables.

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

Connect the frontend and backend. The frontend will have sign in/out and account pages for users to manage data. The account pages should support the different types of users: Client and Provider.

**Developer tasks:**
- Build authentication system for both web and mobile
- Create user account management interfaces
- Implement provider dashboard with client list and basic information
- Set up client-provider relationship management

A client should only have one provider. A provider can have 1 or multiple clients. The provider should be able to see all clients in a basic list and some information. The client should have minimal control to keep the client interface as simple as possible. The provider should have the most control.

By the end of this section, both clients and providers should be able to make accounts on a simple UI. Providers should be able to add/remove/manage clients and see personal data.

**Important questions to resolve:**
- How would large organizations be managed with multiple providers? 
- Should there be an organization data structure? 
- Can an organization have multiple providers? 

### Phase 2 - Exercise Creation Logic (2 weeks)

Add the core functionality. Implement working logic that takes user input/quiz feedback and generates a list of exercises. These exercises are confirmed with the provider, then sent to the client.

**Developer tasks:**
- Build backend logic to generate exercises using AI/automation
- Create provider approval workflow - allow providers to intervene and modify exercises
- Build provider management pages to see client exercises and manage them (view, delete, refine)
- Create client interface to view exercises as a formatted list and mark them as complete

**Business tasks:**
- Provide exercise content sources or GIF libraries  
- Test exercise generation quality and provide feedback
- Define what client input/quiz format should look like

This section will implement the backend logic to generate exercises, allow providers to intervene if they would like to, and then forward them to the client. On the frontend, there will be basic management pages for providers to see and manage client exercises.

Clients should be able to view their exercises in a basic, formatted list and mark them as complete.

This section marks the completion the the intial prototype, showing off core functionality.

### Development Break
**August 25 - September 25, 2025**
*Developer unavailable due to personal travel. Minimal work possible but no deliverable deadlines during this period. Timeline pauses - no compensation penalties for delays during this month.*

### Phase 3 - Polish and Launch (2 weeks)
**Timeline:** September 26 - October 10, 2025

This should result in a close to polished interface for providers and clients, including GIF integration for generated exercises. Simple, clean UI for users on the mobile app. More complex provider app on the web.

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
**Timeline:** October 11 - 18, 2025

Direct feedback and improvement based on real user testing.

**Total timeline:** 8 weeks of development work (excludes 1-month break)

## Business Model Questions

We need to figure out several things before and during development:

- How do we charge? Monthly subscription per provider? Per client? Flat rate?
- What's the pricing strategy for different provider types (solo vs. clinics)?
- Do clients pay anything or is it all through providers?

## Project Completion Terms & Performance Agreement

### Timeline Adherence and Compensation Adjustments

**Unforeseen Project-Related Delays:**
If a phase takes longer due to legitimate project complexities (e.g., technical challenges, scope changes requested by business owner, third-party integration issues), additional compensation will be negotiated at $50/hour for extra time required, this cost will be split between the developer and business owner.

**Developer Performance Issues:**
If delays are caused by developer underperformance or lack of progress without valid project-related reasons:
- **1-3 days late:** Warning, no compensation adjustment
- **7 days late:** 10% reduction in phase payment
- **14+ days late:** 20% reduction in phase payment + potential project termination

**Business Owner Delays:**
If business owner fails to provide required materials/feedback within agreed timeframes, timeline extends accordingly without penalty to developer.

**Scheduled Developer Absence:**
During the pre-planned development break (August 25 - September 25, 2025), no work deliverables are expected and no compensation penalties apply for project delays during this period. Timeline automatically pauses and resumes September 26th.

### Project Termination Conditions

**Developer Termination:**
- Failure to deliver working functionality for any phase after 2 weeks past deadline without reason
- Abandonment of project without 1-week notice
- Compensation: Only paid for completed phases, no equity transfer

**Business Owner Termination:**
- Can terminate project at any time with 1-week notice
- Developer receives full payment for completed phases + prorated payment for current phase work + earned equity up to that point

**Mutual Termination:**
- Either party can request termination if project scope changes significantly
- Fair compensation negotiated based on work completed

### Agreement Acceptance

Both parties agree to these terms by proceeding with Phase 0. Any modifications to this agreement must be documented in writing and agreed upon by both parties.
