# 💇‍♂️ Salonify - Project Source of Truth

## 📌 Project Overview
Salonify is a professional-grade Smart Salon Booking Ecosystem tailored specifically for the Pakistan market. It bridges the gap between high-end salon management and customer convenience through a multi-tenant architecture.

- **Target Market**: Pakistan (with a focus on trust-building and cash-economy integration).
- **User Roles**: Customer, Salon Owner, and Platform Administrator.
- **Core Tech**: Flutter + Firebase (Firestore, Auth, Storage).
- **Language Support**: English & Urdu.

---

## 💡 Business Strategy (Teacher's Mandate)
> **"Pehle logon ki zaroorat banao, phir paisa kamao."**
*(First create a necessity for the people, then earn money.)*

### 📈 Monetization Roadmap
| Phase | Timeline | Strategy | Goal |
| :--- | :--- | :--- | :--- |
| **Phase 0** | 0-12 Months | **Completely FREE.** No commissions or fees. | Rapid adoption; make Salonify a daily necessity. |
| **Phase 1** | 12-14 Months | **Slow Monetization.** Small fees (Rs. 50-100/booking). | Monetize once user behavior is established. |
| **Phase 2** | 14+ Months | **Full Monetization.** 15% commission structure. | Establish sustainable long-term revenue. |

---

## 🌍 Market Insights & Growth Strategy
- **Local Context**: 80%+ cash economy; high skepticism toward digital commissions.
- **Growth Lever**: Leveraging the **Peshawar Salon Owners Union President** to build community trust.
- **Onboarding**: Simple tutorial videos to assist non-tech-savvy salon owners.
- **Operations**: Direct physical outreach to local barbers and salons.

---

## 🛠 Technical Architecture

### 📂 Complete Codebase Map (`lib/`)

#### 🚀 Root & Entry Points
- `main.dart`: Main app entry, Dependency Injection (GetX), and Global Routing.
- `admin_main.dart`: Dedicated entry point for the Admin Web Portal.
- `firebase_options.dart`: Firebase configuration for multiple platforms.

#### 🧠 Core Layer (`lib/core/`)
- **`constants/`**: `app_durations.dart`, `app_radius.dart`, `app_spacing.dart`
- **`controllers/`**: `booking_controller.dart`, `payment_controller.dart`, `salon_controller.dart`, `user_controller.dart`, `wallet_controller.dart`
- **`localization/`**: `app_translations.dart`
- **`models/`**: `transaction_model.dart`, `wallet_model.dart`
- **`services/`**: `auth_service.dart`, `database_service.dart`, `notification_service.dart`, `payment_service.dart`, `security_service.dart`
- **`theme/`**: `app_colors.dart`, `app_gradients.dart`, `app_shadows.dart`, `app_text_styles.dart`, `app_theme.dart`, `theme_controller.dart`, `theme_helper.dart`
- **`utils/`**: `validation_utils.dart`

#### 🎨 Feature Layer (`lib/features/`)
- **`auth/`**: `auth_gate.dart` (Smart Routing), `screens/` (Login, Onboarding, Role Selection, Email Verification).
- **`customer/`**:
    - `customer_main_wrapper.dart`: Core navigation for customers.
    - `registration/`: `customer_registration_screen.dart`, `customer_profile_setup_screen.dart`.
    - `screens/`: `customer_home_screen.dart`, `explore_screen.dart`, `booking_screen.dart`, `salon_detail_screen.dart`, `my_bookings_screen.dart`, `payment_screen.dart`, `qr_screen.dart`, `customer_profile_screen.dart`, `favourite_salons_screen.dart`, `notifications_screen.dart`, `saved_addresses_screen.dart`, `help_support_screen.dart`, `success_screen.dart`.
    - `widgets/`: `booking_date_chip.dart`, `time_slot_chip.dart`.
- **`owner/`**:
    - `owner_main_wrapper.dart`: Core navigation for salon owners.
    - `registration/`: `owner_registration_screen.dart`, `owner_basic_info_screen.dart`, `owner_coworkers_screen.dart`, `owner_documents_screen.dart`, `owner_services_screen.dart`, `owner_review_screen.dart`, `owner_pending_screen.dart`.
    - `screens/`: `owner_dashboard_screen.dart`, `owner_earnings_screen.dart`, `owner_schedule_screen.dart`, `owner_services_management_screen.dart`, `owner_gallery_management_screen.dart`, `owner_staff_screen.dart`, `owner_profile_screen.dart`, `owner_notifications_screen.dart`, `qr_scanner_screen.dart`.
- **`admin/`**:
    - `admin_main_wrapper.dart`: Core navigation for admins.
    - `controllers/`: `admin_controller.dart`.
    - `screens/`: `admin_dashboard_screen.dart`, `admin_login_screen.dart`, `admin_settings_screen.dart`, `audit_log_screen.dart`, `salon_verification_screen.dart`, `transaction_monitoring_screen.dart`, `user_management_screen.dart`, `withdrawal_management_screen.dart`.
    - `theme/`: `admin_colors.dart`.
    - `widgets/`: `admin_common_widgets.dart`, `admin_scaffold.dart`, `admin_stat_card.dart`, `admin_top_bar.dart`.

#### 📦 Shared Layer (`lib/shared/`)
- **`screens/`**: `wallet_screen.dart`.
- **`widgets/`**: `app_button.dart`, `image_carousel.dart`, `progress_step_bar.dart`, `salon_card.dart`, `upload_box.dart`.

---

## ✅ Completed Technical Work
The application is feature-complete for the Phase 0 launch.
- **UI/UX**: 30+ high-fidelity screens implemented across three roles.
- **Authentication**: Full flow including role selection, email verification, and session persistence.
- **Backend**: Integrated Firestore database with complex querying and real-time listeners.
- **Financials**: Complete wallet and transaction system (currently set to 0% commission).
- **Operations**: QR-based scanning, document upload/verification, and staff management.

## 🛠 Development Legacy (User & DeepSeek)
This codebase reflects a high-level engineering collaboration between the User and DeepSeek, emphasizing structural integrity over simple UI:
- **Atomic Financial Engine**: Implementation of `PaymentService` using **Firestore Transactions** to guarantee data consistency and idempotency, eliminating the risk of double-payments.
- **Forensic Administrative Oversight**: A robust `AuditLogScreen` that captures a permanent trail of admin actions with "before/after" snapshots.
- **High-Fidelity UX Engineering**: Advanced multi-stage onboarding with real-time regex password validation and geolocation-based discovery.
- **Multi-Tenant Architecture**: A clean separation of concerns between Customer, Owner, and Admin roles, orchestrated by a sophisticated `AuthGate` and `ThemeHelper`.
- **Localized Trust-Model**: Specialized logic for CNIC verification and co-worker management tailored for the Pakistani business environment.

---

## 📅 Implementation Roadmap

### 🛠 Tech Phases (100% Completed)
- [x] **Phase 1: Foundation** (Shell, Theme System, Design Language).
- [x] **Phase 2: Command Center** (Admin & Owner Dashboards).
- [x] **Phase 3: Operations** (Management Modules, Registration Flows).
- [x] **Phase 4: Engineering Excellence** (UI Polish, Performance Tuning).
- [x] **Phase 5: Financial Architecture** (Wallet Logic, Commission Engine - *Disabled for Launch*).

### 💰 Business Phases (Current Focus)
- [x] **Phase 0: Market Entry & Free Launch** $
ightarrow$ **CURRENT STATE**.
- [ ] **Phase 1: Slow Monetization** (12-14 months).
- [ ] **Phase 2: Full Monetization** (14+ months).

---

## ⚖️ Development Rules
1. **Necessity First**: Prioritize user adoption and daily utility over monetization.
2. **Sequential Growth**: Adhere strictly to the Business Phase timeline.
3. **Adoption Over Logic**: If a technical feature hinders user onboarding, prioritize the user experience.
4. **Preserve Logic**: Maintain all commission and payment code in the codebase; toggle it only when transitioning phases.

## 🚩 Problem Tracking
- **Issue**: Immediate commission fees are a significant barrier to entry for local shop owners.
- **Resolution**: All commission logic is built but locked behind a `defaultCommissionRate = 0` constant.
- **Objective**: Scale user base through Union leadership before enabling fees.

---

## 🌍 Localization & Dynamic Translation
To cater to the diverse Pakistani market, Salonify implements a robust multi-language system:
- **Multi-Language Support**: Full support for English and Urdu using `GetX` translations.
- **Language Switching**: Integrated language toggle buttons in both Customer and Owner profile screens for seamless switching.
- **Dynamic Translation Engine**: A `TranslationService` that utilizes external APIs to translate user-entered data (e.g., Full Name, Salon Name, Address, Co-worker Names) from English to Urdu in real-time during registration and profile updates.
- **Local Trust-Model**: Ensuring that critical business information is accessible and understandable in the national language to build trust with non-tech-savvy salon owners.

Today, we successfully completed the full localization and dynamic translation system for the Salonify salon booking app. We fixed critical issues including the GetX Obx error in customer and owner profile screens by replacing nested Obx widgets with inline implementations. We added comprehensive Urdu translations for all UI elements including profile subtitles (favourite_salons_subtitle, wallet_subtitle, saved_addresses_subtitle, help_subtitle) and fixed the userNameUr property in the UserController to properly display customer names in Urdu when the language is switched. We resolved the starting_from_rs translation key and added starting_from to both English and Urdu sections. The UserController was enhanced with proper auth state listening using authStateChanges().listen() instead of ever(), and the refreshProfile() method was updated to return Future<void> to support async refresh operations. We also fixed the customer profile display by adding loading states and refresh functionality, ensuring the user's name and email appear correctly after login. All translation keys are now properly mapped in app_translations.dart, enabling seamless language switching between English and Urdu throughout the app. The app is now fully localized with dynamic translation support for user inputs during registration, making it ready for the Pakistani market. 🚀

## ✅ Completed (this session)

### 1. Gallery Upload — Fixed
- Replaced local device file path storage with real ImgBB cloud upload
- `owner_gallery_management_screen.dart` now uploads via ImgBB API and saves the real hosted URL to Firestore
- Fixes broken gallery images on customer/admin side (previously only visible on owner's own device)
- **Note:** photos uploaded before this fix still need manual delete + re-upload

### 2. Home Screen Image Fallback
- `customer_home_screen.dart`: salon image now falls back `logo → salonPhotos.first` (was `salonPhotos` only)

### 3. Favourite Salons — Fully Functional
- New: `favourites_controller.dart`, `favourite_button.dart`
- Heart toggle added to `salon_card.dart` (home/explore/favourites) and `salon_detail_screen.dart`
- `favourite_salons_screen.dart` rewritten to read real Firestore data (was hardcoded empty list)
- Includes live distance calculation matching home screen behavior

### 4. Salon Ratings & Reviews — Fully Functional
- New: `rate_salon_screen.dart` — 5-star + comment, writes to `reviews` collection
- Recalculates and updates salon's average `rating` + `reviewCount` on `owners` doc
- New: `owner_reviews_screen.dart` — owner-side view of all reviews (added to owner profile menu)
- Review count now displayed on `salon_card.dart` and `salon_detail_screen.dart`
- `my_bookings_screen.dart`: "Rate Salon" button added on completed bookings, becomes "Review Submitted" badge after
- Firestore rules updated: added `reviews` collection rules + tightened `owners` update rule (customer can update only `rating`/`reviewCount` fields)

### 5. Dynamic Time Slots + Staff Availability — Fully Functional
- `booking_screen.dart` rewritten: real-time slot generation (10 AM–8 PM, 30-min intervals), grouped into Morning/Afternoon/Evening
- Slots check real bookings for that owner + date, mark fully-booked slots as unavailable
- Staff picker shown after slot selection: Free/Busy status per staff member, sorted by staff rating (highest first)
- Booking doc now saves `staffId` + `staffName`
- Fixed: `customerName` and `customerImage` now correctly written on booking creation (previously always saved literal "Customer")
- Fixed: `salonName` on booking now correctly reads from raw owner doc (`salonName` key, not `name`)

### 6. Staff Rating — Fully Functional
- `rate_salon_screen.dart` extended: rates the specific staff member who served the booking (if `staffId` exists on it)
- Updates `ownerStaffRating` (if owner is the stylist) or the specific worker's `rating` field inside the `workers` array
- `owner_staff_screen.dart`: each staff card now shows star rating + review count ("No ratings yet" if none)
- Feeds directly into the staff sort order in the booking screen (item 5)

### 7. Owner Schedule Screen — Polish
- Customer avatar added next to name on each booking card (helps distinguish same-name customers)
- Staff name shown as a pink pill under customer name
- Time box properly centered regardless of card height

### 8. Missing Asset Crash — Fixed
- `assets/default_avatar.png` was referenced in 4 files but never existed in the project, causing a crash
- Fixed in: `owner_schedule_screen.dart`, `owner_staff_screen.dart`, `booking_screen.dart`, `customer_profile_screen.dart` — all now gracefully fall back to an icon instead of a missing asset

### 9. Owner Ad / Banner System — Fully Functional
- New: `owner_ad_screen.dart` — create/manage a salon ad: offer title, % off slider, service picker (auto-calculates original vs. discounted price), 3/7/14-day duration, background (4 built-in gradient templates or custom photo via ImgBB)
- New: `ad_banner_card.dart` — shared banner renderer (logo+name → % off → offer title → price → services line → Claim Now), auto dark-overlay for legibility over custom photos
- `customer_home_screen.dart`: static banner replaced with a real carousel of nearest active ads (25km cutoff, sorted `isPaid desc → distance asc → rating desc`)
- `salon_detail_screen.dart`: added Services/Offers tab switcher; Offers tab shows the salon's live ad + a working "Book This Offer" button that pre-selects the offer's services and jumps to the booking flow
- One ad per owner enforced via Firestore doc ID = `ownerId`
- Monetization hooks included but inactive: `isPaid`, `paymentStatus`, `amountCharged`, `transactionId` — ready for future ad-charging via existing wallet system
- Firestore rules updated: added `ads/{ownerId}` collection rules

### 10. Recently Visited Salons (Home Screen Redesign)
- Categories row replaced with "Recent Salons" — shows the customer's most recently booked salons
- Falls back to "Top Rated Near You" for customers with no booking history yet
- Search bar redesigned (pill shape, filled filter button)

### 11. Localization
- ~50+ new translation keys added across all of the above features, English + Urdu
- Fixed a duplicate `select_staff` key that existed in both the original Booking section and the new dynamic-slots section

---

## Known follow-ups / not yet done
- Old bookings/photos created before fixes above won't retroactively update (stale data, not a bug)
- Notification screens (`notifications_screen.dart`, `owner_notifications_screen.dart`) are still static/hardcoded — review notifications are written to Firestore but not yet visibly surfaced there
- Ad monetization (`isPaid` charging logic) not yet active — schema is ready, logic is not built