# 💇‍♂️ Salonify - Project Source of Truth

## 📌 Project Overview
Salonify is a professional-grade Smart Salon Booking Ecosystem tailored specifically for the Pakistan market. It bridges the gap between high-end salon management and customer convenience through a multi-tenant architecture.

- **Target Market**: Pakistan (with a focus on trust-building and cash-economy integration).
- **User Roles**: Customer, Salon Owner, and Platform Administrator.
- **Core Tech**: Flutter + Firebase (Firestore, Auth, Storage) + **Supabase Edge Functions** (trusted server layer for money-moving logic).
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

**Payment model note:** the app follows an inDrive-style split — customer pays the owner **directly** (cash, or scan-to-pay via the owner's own EasyPaisa/JazzCash QR), never through an in-app customer wallet. Only the **owner** holds a ledger (for future commission tracking). See "Owner Commission Escrow (Designed, Not Built)" below.

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
- **`controllers/`**: `booking_controller.dart`, `payment_controller.dart`, `salon_controller.dart`, `user_controller.dart`, `wallet_controller.dart`, `favourites_controller.dart`
- **`localization/`**: `app_translations.dart`
- **`models/`**: `transaction_model.dart`, `wallet_model.dart`
- **`services/`**: `auth_service.dart`, `database_service.dart`, `notification_service.dart`, `payment_service.dart` (now calls Supabase Edge Functions for all money-moving operations), `security_service.dart`
- **`theme/`**: `app_colors.dart`, `app_gradients.dart`, `app_shadows.dart`, `app_text_styles.dart`, `app_theme.dart`, `theme_controller.dart`, `theme_helper.dart`
- **`utils/`**: `validation_utils.dart`

#### 🎨 Feature Layer (`lib/features/`)
- **`auth/`**: `auth_gate.dart` (Smart Routing), `screens/` (Login, Onboarding, Role Selection, Email Verification).
- **`customer/`**:
  - `customer_main_wrapper.dart`: Core navigation for customers. **`WalletScreen` tab removed** (customer wallet discontinued — see Payment Architecture section).
  - `registration/`: `customer_registration_screen.dart`, `customer_profile_setup_screen.dart`.
  - `screens/`: `customer_home_screen.dart` (recent-salons carousel + nearest-ads carousel), `explore_screen.dart`, `booking_screen.dart` (dynamic slots + staff availability), `salon_detail_screen.dart` (Services/Offers tabs), `my_bookings_screen.dart`, `rate_salon_screen.dart`, `qr_screen.dart` (attendance verification QR — unrelated to payments), `customer_profile_screen.dart`, `favourite_salons_screen.dart`, `notifications_screen.dart` **(⚠️ still static/hardcoded)**, `saved_addresses_screen.dart` **(⚠️ still static/hardcoded)**, `help_support_screen.dart`, `success_screen.dart`.
  - ~~`payment_screen.dart`~~ — **dead code, unreachable from anywhere in the app, scheduled for deletion.** Hardcoded Rs. 1500 fake price, fake 50% advance concept that doesn't exist elsewhere, "Pay" button doesn't write to Firestore at all.
  - `widgets/`: `booking_date_chip.dart`, `time_slot_chip.dart`.
- **`owner/`**:
  - `owner_main_wrapper.dart`: Core navigation for salon owners.
  - `registration/`: `owner_registration_screen.dart`, `owner_basic_info_screen.dart`, `owner_coworkers_screen.dart`, `owner_documents_screen.dart`, `owner_services_screen.dart`, `owner_review_screen.dart`, `owner_pending_screen.dart`.
  - `screens/`: `owner_dashboard_screen.dart`, `owner_earnings_screen.dart`, `owner_schedule_screen.dart` (payment QR shown inline for digital methods), `owner_services_management_screen.dart`, `owner_gallery_management_screen.dart` (ImgBB upload), `owner_staff_screen.dart` (shows staff ratings), `owner_profile_screen.dart`, `owner_notifications_screen.dart` **(⚠️ still static/hardcoded)**, `qr_scanner_screen.dart`, `owner_reviews_screen.dart`, `owner_ad_screen.dart`, `owner_payment_qr_screen.dart`.
- **`admin/`**:
  - `admin_main_wrapper.dart`: Core navigation for admins.
  - `controllers/`: `admin_controller.dart`.
  - `screens/`: `admin_dashboard_screen.dart` (confirmed reads live data, no hardcoded stats), `admin_login_screen.dart`, `admin_settings_screen.dart`, `audit_log_screen.dart`, `salon_verification_screen.dart`, `transaction_monitoring_screen.dart`, `user_management_screen.dart`, `withdrawal_management_screen.dart`.
  - `theme/`: `admin_colors.dart`.
  - `widgets/`: `admin_common_widgets.dart`, `admin_scaffold.dart`, `admin_stat_card.dart`, `admin_top_bar.dart`.

#### 📦 Shared Layer (`lib/shared/`)
- **`screens/`**: ~~`wallet_screen.dart`~~ — **commented out / removed from customer nav.**
- **`widgets/`**: `app_button.dart`, `image_carousel.dart`, `progress_step_bar.dart`, `salon_card.dart` (favourite heart, review count), `upload_box.dart`, `favourite_button.dart`, `ad_banner_card.dart`.

#### 🔌 External Backend — Supabase Edge Functions (`supabase/functions/`)
Firebase's Blaze plan (required for Cloud Functions and Phone Auth OTP) is unreachable — every Pakistani card tried (NayaPay, SadaPay, Meezan Bank Visa) was rejected by Google's billing verification. **Supabase Edge Functions** (free, no card required, 500k invocations/month) now serve as the trusted server layer instead, using the Firebase Admin SDK (via a service account secret) to make privileged Firestore writes that the Flutter client is no longer allowed to make directly.

- **`wallet-payment`**: Handles customer-wallet-to-owner-wallet payment (legacy path, dormant now that customer wallet is removed — kept working, unused).
- **`wallet-withdrawal`**: Owner withdrawal request — verifies identity, checks balance, deducts atomically. Real payout is still manual (bank transfer) until a real payment gateway exists.
- **`confirm-salon-payment`**: Replaces the old direct-Firestore-write `processCashPayment`/`processDigitalPayment`. Owner-confirmed (owner already physically verified cash/EasyPaisa receipt) — verifies the caller really is the booking's owner, then atomically marks the booking `paid` and writes the transaction record.

**Firebase service account key** is stored as a Supabase secret (`FIREBASE_SERVICE_ACCOUNT`) — never committed to the repo.

---

## ✅ Completed Technical Work
The application is feature-complete for the Phase 0 launch.
- **UI/UX**: 30+ high-fidelity screens implemented across three roles.
- **Authentication**: Full flow including role selection, email verification, and session persistence. *(Phone/SMS OTP not available — Firebase Phone Auth requires Blaze billing, which is currently unreachable. Email-based verification is the fallback.)*
- **Backend**: Integrated Firestore database with complex querying and real-time listeners, secured by a Supabase Edge Function layer for all money-moving writes.
- **Financials**: Customer-facing wallet **discontinued** in favor of direct payment (cash or QR scan-to-pay) — matches the inDrive model. Owner-side commission ledger designed (see below) but not yet built; currently 0% commission.
- **Operations**: QR-based attendance scanning (customer→owner direction, cryptographically signed, expires every 120s), document upload/verification, and staff management with per-staff ratings.

## 🛠 Development Legacy (User & DeepSeek, then Claude)
This codebase reflects a high-level engineering collaboration, emphasizing structural integrity over simple UI:
- **Atomic Financial Engine**: `PaymentService` uses **Firestore Transactions** (and now Supabase Edge Functions for the actual privileged writes) to guarantee data consistency and idempotency, eliminating the risk of double-payments.
- **Forensic Administrative Oversight**: A robust `AuditLogScreen` that captures a permanent trail of admin actions with "before/after" snapshots.
- **High-Fidelity UX Engineering**: Advanced multi-stage onboarding with real-time regex password validation and geolocation-based discovery.
- **Multi-Tenant Architecture**: A clean separation of concerns between Customer, Owner, and Admin roles, orchestrated by a sophisticated `AuthGate` and `ThemeHelper`.
- **Localized Trust-Model**: Specialized logic for CNIC verification and co-worker management tailored for the Pakistani business environment.
- **Security-First Payment Redesign**: After discovering the wallet system had zero server-side enforcement (any signed-in user could edit any wallet directly via Firestore, and top-up was a hardcoded fake-money bug), the whole money-movement layer was rebuilt behind a trusted server boundary.

---

## 💳 Payment Architecture (Current, Post-Redesign)

**Model: inDrive-style, not full-escrow.** The app never holds customer money.

1. **Cash**: customer pays owner in person. Owner confirms via `confirm-salon-payment` Edge Function.
2. **Digital (EasyPaisa/JazzCash)**: owner uploads their own merchant QR once (`owner_payment_qr_screen.dart`, ImgBB-hosted). At the "Collect Payment" step, if the owner selects EasyPaisa/JazzCash, that QR displays inline (`owner_schedule_screen.dart`) so the customer can scan-and-pay directly into the owner's own real EasyPaisa/JazzCash account — **the app has zero involvement in the actual money transfer.** Owner then taps Confirm (same as cash), which is what makes it trustworthy — the owner has already seen the money land before confirming.
3. **No customer wallet exists.** Removed entirely — was a security liability (fake top-up bug) and didn't match the chosen business model.

### Owner Commission Escrow (Designed, Not Built)
Modeled directly on inDrive's real driver-ledger system (confirmed via research: inDrive routes the fare directly to the driver, and only escrows the **driver's own prepaid commission float** — never the passenger's fare).
- Planned schema: `wallets/{ownerId}` split into `availableBalance` + `escrowBalance`.
- Planned gate: owner needs `availableBalance >= minimumThreshold` to keep accepting new bookings — **must stay behind an off-switch until commission is actually enabled**, or every owner (currently at Rs. 0 balance, since commission is 0%) would be instantly locked out.
- Commission would move to `escrowBalance` only at "service completed" (not booking creation), release back to `availableBalance` on cancellation.
- **Blocker**: no "service completed" status currently exists in the booking lifecycle (only `pending → confirmed/cancelled → paid`). Would need a new explicit step.
- **Not started** — this is a design document only, intentionally deferred until commission launch approaches.

---

## 📅 Implementation Roadmap

### 🛠 Tech Phases (100% Completed)
- [x] **Phase 1: Foundation** (Shell, Theme System, Design Language).
- [x] **Phase 2: Command Center** (Admin & Owner Dashboards).
- [x] **Phase 3: Operations** (Management Modules, Registration Flows).
- [x] **Phase 4: Engineering Excellence** (UI Polish, Performance Tuning).
- [x] **Phase 5: Financial Architecture** (Owner ledger + Edge Function security layer; Commission Engine designed, *disabled for launch*).

### 💰 Business Phases (Current Focus)
- [x] **Phase 0: Market Entry & Free Launch** → **CURRENT STATE**.
- [ ] **Phase 1: Slow Monetization** (12-14 months).
- [ ] **Phase 2: Full Monetization** (14+ months).

---

## ⚖️ Development Rules
1. **Necessity First**: Prioritize user adoption and daily utility over monetization.
2. **Sequential Growth**: Adhere strictly to the Business Phase timeline.
3. **Adoption Over Logic**: If a technical feature hinders user onboarding, prioritize the user experience.
4. **Preserve Logic**: Maintain all commission and payment code in the codebase; toggle it only when transitioning phases.
5. **Dormant-by-default for new monetization hooks**: any new charge-related field/logic (ads `isPaid`, escrow balance gate, etc.) ships wired but switched OFF, never live until deliberately enabled.

## 🚩 Problem Tracking
- **Issue**: Immediate commission fees are a significant barrier to entry for local shop owners.
- **Resolution**: All commission logic is built but locked behind a `defaultCommissionRate = 0` constant.
- **Objective**: Scale user base through Union leadership before enabling fees.
- **Issue**: Firebase Blaze plan (Cloud Functions, Phone Auth) unreachable — every Pakistani card type tested has been rejected by Google billing verification.
- **Resolution**: Supabase Edge Functions (no card required) now serve as the trusted server layer instead. Phone OTP deferred in favor of email verification; a local SMS gateway (Jazz/Zong/Telenor) is the fallback path if phone OTP becomes a priority later.

---

## 🌍 Localization & Dynamic Translation
To cater to the diverse Pakistani market, Salonify implements a robust multi-language system:
- **Multi-Language Support**: Full support for English and Urdu using `GetX` translations.
- **Language Switching**: Integrated language toggle buttons in both Customer and Owner profile screens for seamless switching.
- **Dynamic Translation Engine**: A `TranslationService` that utilizes external APIs to translate user-entered data (e.g., Full Name, Salon Name, Address, Co-worker Names) from English to Urdu in real-time during registration and profile updates.
- **Local Trust-Model**: Ensuring that critical business information is accessible and understandable in the national language to build trust with non-tech-savvy salon owners.
- 100+ new translation keys added across the payment, ratings, ads, and booking overhauls this session — all English + Urdu pairs, no orphaned keys.

---

## ✅ Completed (cumulative session log)

### 1. Gallery Upload — Fixed
Replaced local device file path storage with real ImgBB cloud upload. Fixes broken gallery images on customer/admin side.

### 2. Home Screen Image Fallback
Salon image now falls back `logo → salonPhotos.first`.

### 3. Favourite Salons — Fully Functional
Real Firestore read/write, heart toggle on home/explore/detail screens, live distance calculation.

### 4. Salon Ratings & Reviews — Fully Functional
5-star + comment system, recalculates salon average rating live, owner-side reviews screen, Firestore rules updated.

### 5. Dynamic Time Slots + Staff Availability — Fully Functional
Real-time 30-min slot generation grouped Morning/Afternoon/Evening, checked against real bookings; staff picker with Free/Busy status sorted by rating; fixed `customerName`/`customerImage`/`salonName` bugs on booking creation.

### 6. Staff Rating — Fully Functional
Rates the specific staff member who served the booking; feeds directly into the sort order in the booking screen's staff picker.

### 7. Owner Schedule Screen — Polish
Customer avatar, staff-name pill, centered time box.

### 8. Missing Asset Crash — Fixed
`assets/default_avatar.png` never existed; all 4 references now fall back gracefully to an icon.

### 9. Owner Ad / Banner System — Fully Functional
Full create/manage ad screen, template or custom-photo backgrounds, nearest-ads carousel on home screen (25km cutoff), Services/Offers tabs on salon detail, working "Book This Offer" flow. Monetization hooks (`isPaid` etc.) present but dormant.

### 10. Recently Visited Salons (Home Screen Redesign)
Categories row replaced with real recent-bookings carousel, falls back to Top Rated Near You for new customers.

### 11. Wallet Security Overhaul
Discovered and fixed two critical live vulnerabilities: (a) `topUpWallet` was hardcoded `paymentSuccessful = true` — free fake money, now disabled with a clear message; (b) Firestore rules allowed any signed-in user to write any wallet's balance directly. Fixed via Supabase Edge Functions (`wallet-payment`, `wallet-withdrawal`) + locked-down `firestore.rules` (wallets/transactions now deny all direct client writes).

### 12. Owner Payment QR System
Owner uploads their real EasyPaisa/JazzCash merchant QR once (`owner_payment_qr_screen.dart`); displays inline during "Collect Payment" when a digital method is selected. Pure display feature — the app never touches the actual money transfer.

### 13. Customer Wallet — Removed
Discontinued in favor of the inDrive-style direct-payment model. `WalletScreen` removed from customer nav; `Wallet` removed from the salon payment-method list.

### 14. Cash/Digital Payment Confirmation Bug — Fixed
After locking down the `transactions` collection (item 11), `processCashPayment`/`processDigitalPayment` broke — the booking write succeeded but the follow-up transaction-record write threw, so the owner saw a false "Payment failed" despite the booking actually being marked paid. Fixed by moving both into a new `confirm-salon-payment` Edge Function, consistent with the rest of the security model.

### 15. Full Hardcoded-Data Audit
Systematic repo-wide sweep for fake/static data. Confirmed clean: admin dashboard, ratings, ads, bookings, favourites, home screen. Confirmed still broken: `saved_addresses_screen.dart` (hardcoded fake addresses, flagged since session start, still unfixed), `notifications_screen.dart` + `owner_notifications_screen.dart` (fully fake notification data). Newly discovered: `payment_screen.dart` — an entire dead, unreachable fake payment screen with a hardcoded price and a "Pay" button that doesn't write to Firestore at all; scheduled for deletion.

### 16. Localization
100+ new translation keys across every feature above, English + Urdu, no duplicates remaining.

---

## Known follow-ups / not yet done
- **`saved_addresses_screen.dart`** — still hardcoded fake addresses, real bug, not yet fixed.
- **`notifications_screen.dart` / `owner_notifications_screen.dart`** — still fully static/hardcoded fake data. Review notifications are already written to Firestore (`confirm-salon-payment` and `rate_salon_screen.dart` both write to the `notifications` collection) but nothing reads/displays them yet. FCM push itself is free (no Blaze needed) — the real gap is wiring a trusted sender (could reuse the Supabase Edge Function layer) plus building the actual UI to read real notification docs.
- **`payment_screen.dart`** — dead code, unreachable, needs deletion.
- **Owner commission escrow** — fully designed (see Payment Architecture section above), zero code written. Deliberately deferred until commission launch approaches.
- **Real payment gateway (EasyPaisa/JazzCash merchant API)** — not integrated; current digital payment is manual QR display + owner self-confirmation, not automated.
- **Phone/SMS OTP** — unavailable (Firebase Blaze unreachable); email verification is the current fallback.
- Old bookings/photos created before earlier fixes won't retroactively update (stale data, not a bug).