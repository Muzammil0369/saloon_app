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
- **Onboarding Logic**: Implemented first-launch check using `shared_preferences`.
- **Customer Home**: Dynamic header, intent-based search, and interactive category/salon lists.

### 2. Backend Integration (Firebase)
- **Service Layer**: Implemented `AuthService` (Phone Auth) and `DatabaseService` (Firestore).
- **Registration Flow**: Real-world wiring for Customer Phone -> OTP -> Profile Setup.
- **Data Persistence**: Profiles and roles are saved to Firestore upon successful verification.
- **Android Configuration**: Optimized `build.gradle` and plugin applications for Firebase services.

### 3. Business Management (Owner)
- **Modular Management**: Separate, functional screens for Service Menus (CRUD) and Salon Galleries.
- **Live Dashboard**: Interactive appointment queue where owners can Accept/Reject bookings with real-time UI updates.
- **Analytics**: Integrated bar charts for weekly earnings visualization.

### 4. Advanced Features
- **Wallet System**: Functional top-up simulation and transaction history.
- **QR System**: Customer-side QR generation and Owner-side scanner with simulation logic.
- **Profile Hub**: Complete account management with functional editing for both user types.

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
