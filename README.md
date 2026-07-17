# Scoops — Order & Eat 🍦

A Flutter mobile app for ordering desserts, drinks and pastries from local
stores — built for **PRM393 (Mobile Application Development)**, FPT
University. Business scenario: an online sales / food-ordering platform
("Online sales systems" track from the assignment brief).

## Business scenario

Scoops lets a customer browse a sweets & drinks menu (ice cream, cakes,
cookies, donuts, drinks, pastries), customize an order (size, toppings,
quantity, note), manage a cart with promo codes, check out with a choice of
payment methods, track past orders, message a store directly, and locate
stores on a map. A guest can browse freely but must sign in to check out.

## Architecture

**Pattern: MVVM** (Model – View – ViewModel), with a Repository layer
between ViewModels and the database:

```
views/screens (View)  →  viewmodels/*_vm.dart (ViewModel, ChangeNotifier)
      →  repositories/*_repository.dart (Repository)
      →  services/database_service.dart (SQLite access via sqflite)
```

- **State management:** [`provider`](https://pub.dev/packages/provider).
  Every ViewModel extends `ChangeNotifier`; screens read/watch it via
  `context.read<T>()` / `context.watch<T>()`, wired once in `main.dart`'s
  `MultiProvider`.
- **Database:** local SQLite (`sqflite`), fully self-contained — no backend
  server needed, so the app is gradeable without any external account
  setup. Seeded automatically on first launch (see [Seed data](#seed-data)).
- **Session persistence:** `shared_preferences` remembers the logged-in
  user id (or guest mode) between app launches; `SplashScreen` reads it via
  `AuthViewModel.restoreSession()` to decide whether to route straight to
  the app or to Onboarding.
- **Testability:** `CartViewModel` (the ViewModel with the most business
  logic — line-total/subtotal/discount/total math, add/increment/decrement/
  remove) keeps all its mutations synchronous and in-memory, persisting to
  SQLite as a fire-and-forget side effect. This means its business rules
  can be unit-tested with zero database/platform setup (see
  `test/unit/cart_vm_test.dart`).

### Folder structure

```
lib/
  main.dart                   Entry point, MultiProvider wiring
  core/                       theme.dart, colors.dart, constants.dart, formatters.dart
  models/                     user, category, store, food, cart_item, order,
                               order_item, app_notification, message
  services/                   database_service (schema+seed), auth_service, session_service
  repositories/                food, favourite, cart, order, notification, chat
  viewmodels/                  auth_vm, food_vm, cart_vm, order_vm,
                               notification_vm, chat_vm, favourite_vm
  views/
    screens/                  splash, onboarding, auth, main_shell, home,
                               food_detail, cart, checkout, order_success,
                               notifications, map, chat_list, chat, profile,
                               order_history
    widgets/                  food_card, filter_chip, floating_bottom_nav,
                               primary_button, app_text_field, empty_state, shimmer_box,
                               quantity_stepper, payment_sheet, order_timeline,
                               status_pill, stat_tile, voucher_ticket
test/
  unit/cart_vm_test.dart      Business logic (no DB/platform dependency)
  widget/auth_screen_test.dart Form validation + correct handler invocation
  widget_test.dart            App-boots smoke test
```

## Database design (SQLite)

11 tables — pickup-in-store model (no delivery address/fee). ERD (also
duplicated as an ASCII comment at the top of `lib/services/database_service.dart`,
which is the single source of truth for the schema):

```
users ──< favourites >── foods ──< order_items >── orders ──< vouchers
  │                        │                          │
  │                        ├──< cart_items >── users   ├── order_code, status
  │                        │                            └── payment_method, card_last4
stores ──< foods                                       │
  │                                                     │
  └──< messages >── users                        notifications ── users
categories ──< foods
```

| Table | Key columns |
|---|---|
| `users` | id, full_name, email (unique), password_hash, phone, address, avatar |
| `categories` | id, name, emoji |
| `stores` | id, name, address, lat, lng, rating |
| `foods` | id, store_id→stores, category_id→categories, name, price, emoji, rating, is_available, kcal, ready_minutes, serve_temp, flavour_tags (CSV) |
| `favourites` | id, user_id→users, food_id→foods (unique pair) |
| `cart_items` | id, user_id→users, food_id→foods, quantity, size, note |
| `orders` | id, order_code (e.g. `IC-1041`), user_id→users, subtotal, discount, total, status, payment_method, card_last4, created_at |
| `order_items` | id, order_id→orders, food_id→foods, quantity, price_at_order |
| `vouchers` | id, order_id→orders (unique, 1-1), code, qr_data, expires_at, is_redeemed |
| `notifications` | id, user_id→users, title, body, is_read, created_at |
| `messages` | id, user_id→users, store_id→stores, content, is_from_user, is_read, created_at |

**Checkout is atomic**: `OrderRepository.checkout()` runs inside a single
`db.transaction()` — insert `orders` (with a generated `order_code`) → insert
every `order_items` → insert the `vouchers` row (QR payload for in-store
redemption) → delete the user's `cart_items` → insert a confirmation
`notifications` row. If any step throws, the whole transaction rolls back and
the cart is left untouched. This write happens on [`ProcessingScreen`]
(during the 4-step "Preparing your order" timeline), not at the moment the
user taps "Pay" on [`PaymentSheet`] — the sheet only collects the payment
method choice.

### Seed data

On first launch (empty database), `DatabaseService` seeds:
- 1 demo account — `demo@scoops.com` / `123456`
- 6 categories (Ice Cream, Cakes, Cookies, Donuts, Drinks, Pastries)
- 4 stores with real Ho Chi Minh City coordinates (for the Map screen)
- 24 foods (4 per category), distributed round-robin across the 4 stores

## Functional requirements (10 core functions, matching the rubric)

| # | Function | Screens / files |
|---|---|---|
| 1 | Database/API design | `services/database_service.dart` (schema + ERD comment) |
| 2 | Login / Sign up | `views/screens/auth_screen.dart` |
| 3 | Product (food) list | `views/screens/home_screen.dart` |
| 4 | Product (food) detail | `views/screens/food_detail_screen.dart` |
| 5 | Shopping cart | `views/screens/cart_screen.dart` |
| 6 | Checkout/billing | `widgets/payment_sheet.dart`, `views/screens/processing_screen.dart`, `order_detail_screen.dart` |
| 7 | Notifications | `views/screens/notifications_screen.dart` |
| 8 | Map (store location) | `views/screens/map_screen.dart` (flutter_map + OpenStreetMap, no API key) |
| 9 | Messaging/chat | `views/screens/chat_list_screen.dart`, `chat_screen.dart` |
| 10 | State management | `provider` throughout (see Architecture) |

**Beyond the sample rubric:** onboarding flow with guest mode, favourites,
promo codes, QR pickup vouchers, order history (`my_orders_screen.dart`),
splash screen with staggered letter animation, custom floating pill bottom
navigation with unread badges.

## Non-functional requirements

- Works fully offline (no network dependency — local SQLite only).
- Cold start renders the animated splash within ~2.2s, then routes based on
  session state.
- All async DB/network-shaped calls (`Future`-returning repository methods)
  are awaited with loading states surfaced in the relevant ViewModel
  (`isLoading`) so screens can show spinners/shimmer instead of freezing.
- Code comments are in Vietnamese on every class and non-trivial method, as
  required by the assignment brief.

## Non-technical: new technology explored

**`flutter_map` + OpenStreetMap** (instead of `google_maps_flutter`): avoids
needing a Google Cloud Console API key/billing account, which would be a
setup burden for a course project graded on a stranger's machine. It's a
fully open-source tile renderer; `MapScreen` uses it with a `MarkerLayer`
for the 4 seeded stores and a bottom sheet on marker tap.

## Running the app

```bash
flutter pub get
flutter run
```

Requires an Android emulator, iOS Simulator, or physical device with
Flutter's toolchain set up (`flutter doctor`).

## Testing

```bash
flutter test
```

- **Unit test** — `test/unit/cart_vm_test.dart`: 11 cases covering
  `CartViewModel`'s core business rules — add/merge/split cart lines,
  increment/decrement (auto-remove at 0), remove, subtotal math with size
  surcharges, valid/invalid promo code handling (`SCOOPS10`), and the
  total-never-negative guarantee.
- **Widget test** — `test/widget/auth_screen_test.dart`: 3 cases covering
  `AuthScreen`'s client-side validation (invalid email format, password
  under 6 characters) and that a valid submission calls
  `AuthViewModel.login()` with the exact typed email/password. Uses a
  hand-written `FakeAuthViewModel` (not mockito) so the test never touches
  the real `AuthService`/`SessionService`, which need platform channels
  unavailable under plain `flutter test`.
- `test/widget_test.dart` — smoke test that the app boots without throwing.

## Building a release APK / AppBundle

```bash
# APK
flutter build apk --release

# AppBundle (for Play Store)
flutter build appbundle --release
```

Output:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AppBundle: `build/app/outputs/bundle/release/app-release.aab`

**Proof of release mode:** install the release APK on a device/emulator
(`flutter install --release`, or drag the APK onto an emulator) and take a
screenshot/screen recording showing the app running — release builds strip
the debug banner and run with production-level performance, which should
be captured for the report's deployment section.

## Known limitations / future work

- No real backend — all data lives in local SQLite per device install. A
  future iteration could swap the repository layer for a REST API/Firebase
  without touching the ViewModels or UI (the repository interfaces are
  already isolated for this).
- Chat auto-replies are canned/simulated (no real store staff on the other
  end) since the project scope excludes a live multi-user backend.
- Food/logo images are emoji placeholders (`Food.emoji`, rendered on a
  pastel background) rather than real 3D artwork — `Food.image` is already
  wired to switch to `Image.asset` the moment real PNGs are added under
  `assets/foods/` and declared in `pubspec.yaml`.
- Promo codes support a single hardcoded demo code (`SCOOPS10`) rather than
  a `coupons` table — a deliberate scope simplification.
- Pickup-in-store model only (no delivery) — `orders` has no delivery
  address/fee by design; a future delivery mode would need those columns
  back plus a courier-tracking flow.
- If given more time: real push notifications for order status changes,
  a "reorder" shortcut from My Orders, and a way for the demo "store staff"
  side to actually scan/redeem a voucher (today redemption is a manual
  "Mark as redeemed" button on the customer's own screen).

This project is a from-scratch Flutter app; it does not reuse code from any
other project.
