# Saloon App - Project Context for Gemini CLI

## Project Overview
A Smart Salon Booking App built with Flutter + Firebase for the Pakistan market.
Two user types: Customer and Salon Owner.
Language support: English and Urdu.

## Tech Stack
- Flutter + GetX (state management + navigation)
- Firebase (Firestore, Auth, Storage, FCM)
- Material 3, Pink Theme
- EasyPaisa / JazzCash payment integration
- TomTom + Geolocator for maps
- QR Flutter + Mobile Scanner for QR system
- Shared Preferences for local persistence

## Architecture
- MVVM / Clean Architecture
- Service Layer: `AuthService`, `DatabaseService`
- Folder: lib/models, services, providers, views, widgets, utils
- Adaptive theming via ThemeHelper (light/dark mode)
- Typography: Syne (headings) + DM Sans (body)
- Theme constants: AppColors, AppTextStyles, AppGradients, AppShadows, AppRadius, AppSpacing

## Booking Flow
Customer: Login → Home → Explore → Salon Detail → Booking → Payment (50% advance) → Success
Owner: Register → Upload Docs → Verified → Set Slots → Receive Booking → Accept → Scan QR → Get Paid

## Wallet & Payment Logic
- Customer wallet: top-up via EasyPaisa/JazzCash
- Escrow holds 50% advance until service complete
- Auto commission deduction (10-20%) to platform
- Remaining 50% released after QR scan at salon

## Completed Work & Accomplishments
### 1. Core Screens & UI/UX
- **Full Screen Suite**: All 30+ screens for both Customer and Owner roles are built and themed.
- **Adaptive Theming**: Full support for Light and Dark modes using `ThemeController` and `ThemeHelper`.
- **Premium Aesthetics**: Consistent use of Pink gradients, soft shadows, and custom rounded cards.
- **Onboarding Logic**: Implemented first-launch check using `shared_preferences` and centralized `AuthGate`.

### 2. Backend & Auth Migration
- **Authentication**: Migrated from Phone Auth to Email/Password authentication for security and reliability.
- **AuthGate**: Centralized navigation controller to handle role-based redirection (`CustomerMainWrapper`, `OwnerMainWrapper`, `OwnerPendingScreen`).
- **Owner Approval Flow**: Implemented pending verification screen and status-based routing.

### 3. Business Management (Owner)
- **Dynamic Dashboard**: Dashboard stats, earnings charts, and schedule are now live-streamed from Firestore.
- **Location Pinning**: Implemented custom map-based salon location pinning for owners.
- **Profile Management**: Dynamic business profile management with real-time Firestore updates.

### 5. Enterprise Admin UI Redesign (COMPLETED)
- **Command Center**: Responsive dashboard with interactive stat cards (trend-aware) and revenue analytics via Syncfusion charts.
- **Operations Modules**: Fully refactored Verification, Withdrawals, Transactions, and User Management to follow the enterprise SaaS design system.
- **Audit Logs**: Implemented a dedicated Audit Log viewer with actor (Admin name) tracking.
- **Responsiveness**: Implemented a responsive navigation drawer for smaller screens.
- **Search Functionality**: Added localized, role-based search within the User Management screen.

## Navigation Flow
Onboarding (Runs once) → Role Select →
  Customer: Phone → OTP → Profile Setup → Customer Home (Bottom Nav: Home, Explore, Bookings, Wallet, Profile)
  Owner: Phone → OTP → Basic Info → Services → Documents → Review → Owner Dashboard (Bottom Nav: Stats, Schedule, Earnings, Profile)

## Design Rules (ALWAYS FOLLOW)
- Use ThemeHelper for ALL colors - never hardcode colors
- Use AppTextStyles for ALL text - never hardcode font sizes
- Use AppGradients, AppShadows, AppRadius, AppSpacing everywhere
- Pink gradient theme throughout
- Rounded cards with soft shadows
- Bottom sheets for selection dialogs
- Full dark/light mode support on every screen
- Follow exact same pattern as customer_home_screen.dart

## Firebase Structure
Collections: users, salons, bookings, services, wallets, transactions, disputes, messages

## Current Status
All features and screens are logically connected and visually polished. Real-world Firebase Phone Auth is integrated.

## Currently Working On: Enterprise Admin UI Redesign (COMPLETED)
**Status**: The Admin Panel has been upgraded to a premium, production-ready SaaS dashboard.

### Roadmap (Completed)
- [x] **Phase 1: The Foundation (Shell & Design System)**
- [x] **Phase 2: The Command Center (Dashboard)**
- [x] **Phase 3: The Operations (Management Modules)**
- [x] **Phase 4: Engineering Excellence (Polish & Deployment)**

## Important Notes
- Pakistan market: Urdu + English support
- 50% advance payment is core booking logic
- QR scan at salon releases remaining 50% payment
- Low-end device optimization
- SHA-1 and SHA-256 fingerprints are required for real device testing.

# Upcoming Work

The Admin Panel redesign has been completed and is considered stable for now.

The next development phases should be executed in the following order.

---

## Phase A – Payment & Financial Architecture (Highest Priority)

Objective:
Finalize the complete payment architecture before implementing additional business features.

Tasks:

* Finalize payment workflow.
* Finalize QR payment architecture.
* Finalize owner wallet architecture.
* Finalize commission engine.
* Finalize withdrawal workflow.
* Ensure all payment-related operations are backend validated.
* Ensure future compatibility with EasyPaisa, JazzCash, PayFast, Safepay, and other payment providers.
* Prevent duplicate payments.
* Prevent duplicate wallet credits.
* Create transaction ledger structure.
* Create financial audit trail.

Deliverable:

A complete production-ready payment and financial system.

---

## Phase B – Booking State Machine & Security

Objective:
Transform booking management into a secure production-grade workflow.

Tasks:

Define and enforce booking states:

* PENDING_APPROVAL
* CONFIRMED
* IN_PROGRESS
* COMPLETED
* PAID
* CANCELLED

Prevent invalid status transitions.

Implement:

* Firestore security rules
* Role-based authorization
* Backend validation
* Atomic operations
* Transaction-safe updates

Protect:

* Wallet balances
* Booking statuses
* Commission calculations
* Payment records

Deliverable:

A secure booking lifecycle with production-grade data integrity.

---

## Phase C – Notifications, Reviews & Disputes

Objective:
Improve user experience and operational management.

Tasks:

Notifications:

* Booking accepted
* Booking rejected
* Booking reminder
* 10-minute arrival reminder
* Payment confirmation
* Withdrawal approval

Reviews:

* Allow reviews only after PAID status.
* Prevent fake reviews.
* Store rating history.

Disputes:

* Customer complaints
* Owner complaints
* Admin review process
* Resolution workflow

Deliverable:

Complete communication and trust-management system.

---

## Phase D – Verification, Analytics & Growth

Objective:
Prepare platform for scale.

Tasks:

Salon Verification:

* Document verification
* Video verification workflow
* Verification history

Analytics:

* Most booked salons
* Most booked services
* Repeat customer metrics
* Cancellation rate
* Revenue tracking
* Commission tracking

Growth Features:

* Referral system
* Loyalty system
* Featured salons
* Marketing tools

Deliverable:

Scalable platform management and business intelligence features.

---

# Development Rule

Whenever development resumes in the future:

1. Read this Upcoming Work section first.
2. Determine the current phase.
3. Complete phases sequentially.
4. Do not skip earlier phases unless explicitly instructed.
5. Maintain compatibility with all previously implemented systems.

Current Next Phase:

Phase A – Payment & Financial Architecture

This should be considered the next major milestone of the project.
