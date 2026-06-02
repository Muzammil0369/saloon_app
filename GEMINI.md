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

### 4. Customer Experience
- **Explore & Search**: Customer map and list now fetch real-time salon data and calculate distances dynamically.
- **Booking Flow**: Implemented service selection and booking submission to Firestore.
- **Dynamic Profile**: User information is persisted and accessible via `UserController` throughout the app.

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

## Important Notes
- Pakistan market: Urdu + English support
- 50% advance payment is core booking logic
- QR scan at salon releases remaining 50% payment
- Low-end device optimization
- SHA-1 and SHA-256 fingerprints are required for real device testing.
