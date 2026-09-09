# 💇‍♂️ Salonify - Project Source of Truth

## 📌 Project Overview
Salonify is a professional-grade Smart Salon Booking Ecosystem tailored specifically for the Pakistan market. It bridges the gap between high-end salon management and customer convenience through a multi-tenant architecture.

- **Target Market**: Pakistan (with a focus on trust-building and cash-economy integration).
- **User Roles**: Customer, Salon Owner, and Platform Administrator.
- **Core Tech**: Flutter + Firebase (Firestore, Auth, Storage, Cloud Messaging) + **Supabase Edge Functions** (trusted server layer for money-moving logic and push notifications).
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

**Payment model note:** the app follows an inDrive-style split — customer pays the owner **directly** (cash, or scan-to-pay via the owner's own EasyPaisa/JazzCash QR), never through an in-app customer wallet. Only the **owner** holds a ledger (for future commission tracking).

---

## 🌍 Market Insights & Growth Strategy
- **Local Context**: 80%+ cash economy; high skepticism toward digital commissions.
- **Growth Lever**: Leveraging the **Peshawar Salon Owners Union President** to build community trust.
- **Onboarding**: Simple tutorial videos to assist non-tech-savvy salon owners.
- **Operations**: Direct physical outreach to local barbers and salons.
- **External validation**: Demoed to a university professor (Sept 2026), who gave concrete UX feedback based on foodpanda's search/discovery patterns — see "Scoped, Not Yet Built" below.

---

## 🛠 Technical Architecture

### 📂 Complete Codebase Map (`lib/`)

#### 🚀 Root & Entry Points
- `main.dart`: Main app entry, Dependency Injection (GetX), Global Routing, and `NotificationService().initialize()`.
- `admin_main.dart`: Dedicated entry point for the Admin Web Portal. Deploy: `flutter build web -t lib/admin_main.dart --release` then `firebase deploy --only hosting`.
- `firebase_options.dart`: Firebase configuration for multiple platforms.

#### 🧠 Core Layer (`lib/core/`)
- **`controllers/`**: `booking_controller.dart`, `payment_controller.dart` (salon payment methods: Cash/EasyPaisa/JazzCash only), `salon_controller.dart`, `user_controller.dart`, `wallet_controller.dart`, `favourites_controller.dart`
- **`services/`**: `auth_service.dart`, `database_service.dart`, `notification_service.dart` (FCM: permission, Android channel with explicit sound/vibration/public lock-screen visibility, foreground/background handlers, auto-saves device token on login), `payment_service.dart` (all money-moving writes go through Supabase Edge Functions, every call has a 15s timeout), `security_service.dart` (customer attendance QR).
- **`theme/`**: `app_colors.dart`, `app_gradients.dart`, `app_shadows.dart`, `app_text_styles.dart`, `app_theme.dart`, `theme_controller.dart`, `theme_helper.dart`

#### 🎨 Feature Layer (`lib/features/`)
- **`customer/`**:
  - `screens/`: `customer_home_screen.dart`, `explore_screen.dart` (search bar + category chips + sort/filter sheet — **scoped for a foodpanda-style overhaul, not yet built**, see below), `booking_screen.dart` (time slots currently hardcoded 10 AM–8 PM regardless of actual salon hours — **known bug, fix scoped below**), `salon_detail_screen.dart`, `my_bookings_screen.dart`, `rate_salon_screen.dart`, `qr_screen.dart`, `customer_profile_screen.dart` (menu tiles fixed: `ListTile`s now properly wrapped in `Material` so tap ripples render), `favourite_salons_screen.dart`, `notifications_screen.dart`, `saved_addresses_screen.dart`, `help_support_screen.dart`, `success_screen.dart`.
  - ~~`payment_screen.dart`~~ — dead code, confirmed unreachable, still needs manual deletion.
- **`owner/`**:
  - `screens/`: `owner_dashboard_screen.dart`, `owner_earnings_screen.dart`, `owner_schedule_screen.dart`, `owner_services_management_screen.dart`, `owner_gallery_management_screen.dart`, `owner_staff_screen.dart`, `owner_profile_screen.dart` (same `ListTile`/`Material` fix applied here too), `owner_notifications_screen.dart`, `qr_scanner_screen.dart`, `owner_reviews_screen.dart`, `owner_ad_screen.dart`, `owner_payment_qr_screen.dart`.
  - **Missing entirely**: a business-hours settings screen (opening/closing time, working days) — scoped below, doesn't exist yet.
- **`admin/`**: unchanged from prior state — dashboard, verification, transactions, users, withdrawals, audit log, all reading live data.

#### 📦 Shared Layer (`lib/shared/`)
- **`widgets/`**: `app_button.dart`, `image_carousel.dart`, `progress_step_bar.dart`, `salon_card.dart`, `upload_box.dart`, `favourite_button.dart`, `ad_banner_card.dart`, `notifications_list.dart`, `notification_bell.dart`.

#### 🔌 External Backend — Supabase Edge Functions (`supabase/functions/`)
Firebase's Blaze plan (Cloud Functions, Phone Auth) is unreachable — every Pakistani card tried was rejected by Google billing. Supabase Edge Functions (free, no card) serve as the trusted server layer, using the Firebase Admin SDK via a `FIREBASE_SERVICE_ACCOUNT` secret.

**Critical infrastructure fix applied to ALL 5 functions**: the Firebase Admin SDK's default gRPC transport hangs/fails indefinitely on Supabase's Deno-based edge runtime (`14 UNAVAILABLE: No connection established... TLS connection was established` / a 150s+ hang returning HTTP 546). Root-caused via verbose step-logging on `confirm-salon-payment`, then confirmed identically in `notify-booking-status`'s logs. **Fix: `db.settings({ preferRest: true })` right after `getFirestore()`**, applied to every function that touches Firestore. This was the single root cause behind weeks of "payment stuck loading" / "notification not sending" symptoms that looked like unrelated bugs but were all the same issue.

- **`wallet-payment`**: Legacy, dormant (customer wallet removed).
- **`wallet-withdrawal`**: Owner withdrawal — verifies identity, checks balance, deducts atomically.
- **`confirm-salon-payment`**: Owner-confirmed cash/digital payment. Now also notifies the customer on confirmation (closes the last gap in the notification lifecycle).
- **`notify-new-booking`**: Customer→owner — fires when a booking is created.
- **`notify-booking-status`**: Owner→customer — fires on accept/cancel/complete. The `completed` case already includes a "don't forget to rate it!" nudge.

**Full booking-lifecycle notifications, confirmed working end-to-end**: booking created → accepted/rejected → **payment confirmed** → completed + rate reminder. All 4 steps covered, both in-app (Firestore list + live badge) and real FCM push (banner + sound + vibration + lock-screen visible).

Every client call has a 15-second timeout (`payment_service.dart`).

---

## ✅ Completed Technical Work
- **UI/UX**: 30+ screens across three roles. Two real `ListTile`/`Material` ink-splash bugs found and fixed (both Profile screens).
- **Authentication**: Full flow; phone/SMS OTP unavailable (Blaze required), email verification is the fallback.
- **Backend**: Firestore + real-time listeners, secured by Supabase Edge Functions — **now fully stable** after the gRPC/`preferRest` root-cause fix.
- **Financials**: Customer wallet discontinued (inDrive-style direct payment). Owner commission ledger designed, not built, 0% commission.
- **Notifications**: Fully real and complete — in-app list, live badge, true FCM push, all 4 lifecycle steps, both directions. Fixed a corrupted icon resource string (`ic_flutter utter cleanlauncher` → `ic_launcher`) and added explicit lock-screen visibility.
- **App branding (⚠️ open issue)**: confirmed via file size inspection that every `ic_launcher.png` is still Flutter's default template icon (442–1443 bytes, far too small to be a real design) — the app has never had a real custom icon set, on the home screen OR in notifications. Blocked on the user producing a real logo asset; `flutter_launcher_icons` package + steps already provided once that exists.
- **Operations**: QR-based attendance scanning, document upload/verification, staff management with ratings.

---

## 🔍 Scoped, Not Yet Built (from professor's UX review)

Two separate pieces of feedback from a university demo, both agreed on but **not started**:

### A. Business Hours → Dynamic Time Slots (real bug fix, not just UX)
**The bug**: `booking_screen.dart`'s `_generateTimeSlots()` is hardcoded 10 AM–8 PM for every salon, regardless of when that salon actually opens. Confirmed zero `openingTime`/`closingTime`/`workingDays` fields exist anywhere in the codebase.
**The fix** (3 parts):
1. New owner screen: set opening time, closing time, working days.
2. `booking_screen.dart` reads that specific salon's hours instead of the hardcoded window.
3. If a customer picks a date the salon is closed, show "Closed on this day" instead of slots.
   **Priority**: higher than the search overhaul below — this is fixing something actively wrong today, not adding something new.

### B. Foodpanda-Style Search & Discovery Overhaul
Professor's reference: foodpanda's search flow (browse-before-typing popular categories → typed results with Restaurants/Dishes/Shops tabs → filter chips for Delivery/Pickup/Sort/Free-delivery → a full filter sheet with Sort/Price/Offers → tapping into a richly-designed detail page with search-within-menu and category tabs like "Based on your search / Popular / [category]").

Mapped onto Salonify, broken into pieces:
1. **Quick win, not yet applied**: change `explore_screen.dart`'s default sort from `'Nearest to Far'` to `'Rating: High to Low'` — directly addresses "top-rated shown first, no training needed."
2. **Dedicated search screen**: browse-before-typing (popular services/categories shown before any input), matching foodpanda's blank→loaded transition.
3. **Result tabs**: Salons / Services / Staff (adapted from Restaurants/Dishes/Shops).
4. **Expanded filter sheet**: add Price tiers and an Offers checkbox to the existing sort sheet (which already has Nearest/Far/Price/Rating sort options — just missing the tier/checkbox filters foodpanda has).
5. **Search by service**, not just salon name/category — "haircut and shave" should surface salons offering that service specifically.
6. **Redesigned salon detail page**: tabbed service browsing matching the polished foodpanda menu aesthetic — the biggest visual lift of the six.
7. **Customer-adjustable search radius** (owner's own idea, not foodpanda's): profile setting, default 2km, selectable up to 25km max, visualized as a circle overlay on the map, restricting/prioritizing results accordingly. Doesn't exist in any form today.

**Agreed sequencing**: A (business hours bug fix) first, then B in the order listed above.

---

## 📅 Implementation Roadmap

### 🛠 Tech Phases (100% Completed)
- [x] Phase 1: Foundation — [x] Phase 2: Command Center — [x] Phase 3: Operations — [x] Phase 4: Engineering Excellence
- [x] Phase 5: Financial Architecture (Edge Function security layer; Commission Engine designed, disabled for launch)
- [x] Phase 6: Real-Time Notifications (all 4 lifecycle steps, both directions, push + in-app)
- [x] Phase 7: Infrastructure Stability (gRPC/Deno root-cause fixed across all Edge Functions)

### 💰 Business Phases (Current Focus)
- [x] **Phase 0: Market Entry & Free Launch** → **CURRENT STATE**.
- [ ] Phase 1: Slow Monetization (12-14 months). — [ ] Phase 2: Full Monetization (14+ months).

---

## ⚖️ Development Rules
1. Necessity First — prioritize adoption over monetization.
2. Sequential Growth — adhere to the Business Phase timeline.
3. Adoption Over Logic — UX wins over technical purity when they conflict.
4. Preserve Logic — commission/payment code stays in the codebase, toggled not deleted.
5. Dormant-by-default for new monetization hooks.
6. Never let a network call hang the UI — every Edge Function call carries an explicit timeout.
7. **New**: any Supabase Edge Function touching Firestore must call `db.settings({ preferRest: true })` — learned the hard way after weeks of intermittent hangs/failures across multiple functions traced to one root cause.

## 🚩 Problem Tracking
- **RESOLVED**: `confirm-salon-payment` (and, it turned out, every other Firestore-touching Edge Function) intermittently hung or failed with `14 UNAVAILABLE`. Root cause: gRPC transport incompatibility with Supabase's Deno edge runtime. Fixed universally via `preferRest: true`.
- **Open**: commission fees remain a barrier to entry — locked behind `defaultCommissionRate = 0` until adoption is established.
- **Open**: Firebase Blaze unreachable (every Pakistani card rejected) — Supabase Edge Functions are the permanent workaround, not a temporary one.
- **Open**: app has never had a real icon — blocked on the user providing a logo asset.
- **Open**: booking time slots don't reflect real salon hours — scoped fix above, not yet built.

---

## 🌍 Localization & Dynamic Translation
- Full English/Urdu via `GetX`. Language toggle in both Customer and Owner profile screens.
- `TranslationService` translates user-entered data (salon name, address, co-worker names) in real-time during registration.
- 120+ translation keys added across every feature this session — English + Urdu pairs, no duplicates.

---

## ✅ Completed (cumulative session log)

### 1–17. See prior entries
Gallery upload, favourites, ratings/reviews, dynamic booking slots + staff availability, staff rating, ad/banner system, recent-salons redesign, wallet security overhaul, owner payment QR, customer wallet removal, hardcoded-data audit (saved addresses fixed; notifications rebuilt real; `payment_screen.dart` flagged dead), full notification system build (in-app + FCM push, both directions).

### 18. Payment Infrastructure — Root Cause Found & Fixed
Weeks of intermittent "stuck loading," "payment failed," and "notification not sending" symptoms across multiple Edge Functions were all the same bug: Firebase Admin SDK's default gRPC transport doesn't work reliably on Supabase's Deno edge runtime. Diagnosed via verbose step-logging (`confirm-salon-payment`) confirming the hang happened specifically inside `runTransaction`, then confirmed identically via raw error logs (`14 UNAVAILABLE`) in `notify-booking-status`. Fixed with one line (`db.settings({ preferRest: true })`) applied to all 5 Edge Functions. Also added the missing payment-confirmation notification, completing the full 4-step booking lifecycle notification chain.

### 19. UI Bug Fixes
- Fixed a real `RenderFlex`/`ParentDataWidget` crash on `salon_detail_screen.dart` (a `Flexible` was nested inside a `Container`'s padding instead of being a direct `Row` child).
- Fixed `ListTile`/`Material` ink-splash warnings on both Profile screens (menu tiles were painting inside a plain `Container`, not a `Material` ancestor).
- Fixed a corrupted notification icon resource string and added explicit sound/vibration/lock-screen-visibility settings.
- Discovered the app has never had a real custom icon — still shipping Flutter's default template icon everywhere (home screen and notifications both).

### 20. Localization
120+ keys total across every feature, English + Urdu.

---

## Known follow-ups / not yet done
- **App icon** — still the default Flutter template icon everywhere. Blocked on the user providing a real logo file.
- **Business hours + dynamic time slots** — real bug (hardcoded 10 AM–8 PM for every salon), scoped, not yet built. See "Scoped, Not Yet Built" section above.
- **Foodpanda-style search/discovery overhaul** — 7 sub-pieces scoped, not yet built. See section above.
- **`payment_screen.dart`** — dead code, confirmed unreachable, needs manual deletion.
- **Owner commission escrow** — fully designed, zero code written, deliberately deferred.
- **Real payment gateway (EasyPaisa/JazzCash merchant API)** — not integrated; current digital payment is manual QR display + owner self-confirmation.
- **Phone/SMS OTP** — unavailable (Blaze unreachable); email verification is the fallback.
- **Play Store readiness checklist** — Privacy Policy, Data Safety form, in-app account deletion, signed release build, 12-tester closed testing period, store listing assets (icon depends on the app-icon item above) — none started.
- **ImgBB API key rotation** — sitting in plaintext in the public GitHub repo, should be rotated.
- **Broader Firestore rules hardening** — only `wallets`, `transactions`, `ads`, `reviews` are locked down. `bookings`, `messages`, `disputes`, `qr_tokens` still allow any signed-in user to read/write anything.
- Old bookings/photos from before earlier fixes won't retroactively update (stale data, not a bug).