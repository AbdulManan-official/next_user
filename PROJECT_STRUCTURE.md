# NextUser Application — Master Project Architecture & Directory Structure

---

## 1. Executive System Overview & Architecture

The **NextUser Application** is an enterprise-grade luxury relocation concierge client application built with **Flutter** (Dart). It is tailored for high-net-worth individuals and corporate clients seeking white-glove household and commercial moving experiences.

### Key Architectural Pillars
- **Clean Architecture & Separation of Concerns**: Clearly partitioned into `controllers/`, `models/`, `services/`, `views/`, `widgets/`, `utils/`, and `auth/`.
- **Reactive State Management**: Centralized reactive in-memory state via `MoveStore` (`ChangeNotifier`) and controller layers.
- **Luxury Visual Identity**: Ultra-premium Dark & Gold design system with glassmorphic cards, fluid ambient glows, and responsive typography scaling.
- **Fluid Micro-Interactions**: Haptic feedback on all tactile controls, spring curves, and custom entrance transitions.

---

## 2. Directory Tree Structure

```
next_user/
├── android/                                  # Native Android platform code and manifests
├── assets/                                   # High-resolution raster imagery and brand artwork
│   ├── 1.png                                 # Onboarding / showcase visual graphic 1
│   ├── 6.png                                 # Onboarding / showcase visual graphic 2
│   └── 7.png                                 # Onboarding / showcase visual graphic 3
├── ios/                                      # Native iOS platform project and Info.plist
├── lib/                                      # Core Flutter application source code
│   ├── auth/                                 # Authentication subsystem
│   │   ├── controllers/                      # Auth business logic and input state
│   │   │   ├── auth_controller.dart          # Auth session dispatcher and credentials handling
│   │   │   └── login_controller.dart         # Login validations, loading states & error banners
│   │   ├── models/                           # User session and credentials entity models
│   │   │   └── user_model.dart               # User identity, tokens & profile metadata
│   │   ├── views/                            # Authentication screens
│   │   │   ├── forgot_password_view.dart     # Password reset flow with verification code step
│   │   │   ├── login_view.dart               # Luxury glassmorphic login interface with Email/Phone & Google/Apple
│   │   │   └── signup_view.dart              # Bespoke registration view with Email/Phone toggle & social sign-up
│   │   └── widgets/                          # Auth-specific UI primitives
│   │       ├── auth_card.dart                # Glassmorphic container wrapper for credentials forms
│   │       ├── auth_divider.dart             # Gradient hairline divider with subtle overline text
│   │       ├── auth_tab_switch.dart          # Sliding gold pill switch between Email and Phone methods
│   │       ├── phone_input_field.dart        # Luxury phone input with country code modal selector
│   │       └── social_auth_buttons.dart      # Custom-painted Google & Apple glass authentication buttons
│   │
│   ├── controllers/                          # Application state controllers & store singletons
│   │   ├── move_store.dart                   # Reactive central store for active, scheduled & historical moves
│   │   └── user_controller.dart              # User profile state & concierge service catalog controller
│   │
│   ├── models/                               # Domain models & entities
│   │   ├── move_model.dart                   # Move order entity, status enum, property type & pricing
│   │   └── service_model.dart                # Concierge add-on service offerings model
│   │
│   ├── reusable_components/                  # Communication and calling components
│   │   ├── call_page.dart                    # Active voice/video call session container
│   │   ├── incoming_call_screen.dart         # Full-screen incoming call responder
│   │   └── outgoing_call_screen.dart         # Outgoing call dialer with audio waveform animation
│   │
│   ├── services/                             # Network clients, system services & storage
│   │   ├── auth_service.dart                 # Authentication API connector
│   │   ├── dio_client.dart                   # Configured HTTP client with interceptors
│   │   ├── notification_service.dart         # Push notifications and alert handlers
│   │   ├── permission_service.dart           # Runtime permissions (camera, location, mic)
│   │   ├── session_service.dart              # Local storage session token management
│   │   └── user_service.dart                 # User-specific remote catalog & profile API calls
│   │
│   ├── utils/                                # Theme constants, responsive engine & helpers
│   │   ├── app_theme.dart                    # Material ThemeData setup (Dark mode default)
│   │   ├── app_theme_styles.dart             # Central design tokens: AppColors (Gold/Dark), gradients, text styles
│   │   ├── app_urls.dart                     # Centralized API endpoint registry
│   │   ├── map_launcher_helper.dart          # Deep-link launcher for Google Maps & Apple Maps
│   │   └── responsive_helper.dart            # Multi-breakpoint layout engine (context.r(), context.sp())
│   │
│   ├── views/                                # Main application root screens & flows
│   │   ├── booking_flow_screen.dart          # 4-Step bespoke relocation booking & instant quote flow
│   │   ├── bottom_tab_view.dart              # Root navigation shell with curved navigation bar
│   │   ├── chat_screen.dart                  # Luxury real-time client chat with crew & concierge channels
│   │   ├── home_screen.dart                  # User home dashboard featuring active move card & quick actions
│   │   ├── live_tracking_screen.dart         # Real-time GPS transit tracking, route map & crew info
│   │   ├── move_detail_screen.dart           # Detailed relocation itinerary, crew roster & invoice summary
│   │   ├── moves_screen.dart                 # Filterable move records (Scheduled, In-Progress, Completed)
│   │   ├── profile_screen.dart               # Platinum member profile, notification settings & logout
│   │   └── refer_earn_screen.dart            # Concierge referral code sharing and rewards tracking
│   │
│   ├── widgets/                              # Reusable luxury UI components & modals
│   │   ├── animation_helper.dart             # Entrance transitions, stagger fades & route transitions
│   │   ├── app_shimmer.dart                  # Universal dark-mode shimmer placeholder skeleton
│   │   ├── app_snack_bar.dart                # Elegant top/bottom floating luxury toast notifications
│   │   ├── concierge_call_sheet.dart         # Bottom-sheet modal for direct concierge/crew VoIP calling
│   │   ├── custom_button.dart                # Metallic gold gradient button with loading state
│   │   ├── custom_search_bar.dart            # Dark-styled search input with clear action
│   │   ├── custom_text_field.dart            # Gold-bordered form input with validation handling
│   │   ├── glass_kit.dart                    # Frosted glass containers (GlassCard, GlassContainer)
│   │   ├── image_preview_screen.dart         # Fullscreen zoomable photo viewer with pinch-to-zoom
│   │   ├── logout_dialog.dart                # Confirmation dialog for signing out of session
│   │   ├── notification_sheet.dart           # Preferences bottom sheet for notification triggers
│   │   ├── pdf_preview_screen.dart           # In-app viewer and printer for PDF moving contracts
│   │   ├── rating_sheet.dart                 # Post-move review modal with 5-star rating & comments
│   │   ├── service_card.dart                 # Interactive card showcasing bespoke concierge services
│   │   └── video_viewer_screen.dart          # In-app video player for moving tutorials & recordings
│   │
│   └── main.dart                             # App initialization entry point, root theme & startup routing
│
├── test/                                     # Unit and widget test suite
├── analysis_options.yaml                     # Dart analyzer and linting rules
├── pubspec.yaml                              # Package dependencies and asset configurations
└── README.md                                 # High-level project repository documentation
```

---

## 3. Core Feature Workflows & Architecture

### 1. Root Tab Shell (`bottom_tab_view.dart`)
- Hosts the 4 primary tabs: **Home**, **Book a Move**, **My Moves**, and **Profile**.
- Implements `CurvedNavigationBar` with animated icon transitions, gold accent lighting, and responsive bottom padding to ensure zero notch/home bar conflicts.

### 2. Concierge Booking Flow (`booking_flow_screen.dart`)
- **Step 1 — Property & Residence**: Selection of property type (Studio, Flat, 3-Bed House, Manor, Commercial).
- **Step 2 — Route & Schedule**: Origin address, destination address, and date/time slot picker.
- **Step 3 — Bespoke Add-on Services**: Full packing, fine art crating, vehicle transport, climate-controlled storage.
- **Step 4 — Review & Instant Quote**: Cost calculation breakdown, terms confirmation, and live booking dispatch into `MoveStore`.

### 3. Live Move Tracking (`live_tracking_screen.dart`)
- Visual delivery status with animated transit pulse.
- Dedicated driver & crew contact card with direct audio/video call integration via `ConciergeCallSheet`.
- Live timeline milestones: *Packing Completed ➔ En Route ➔ Arrival at Destination ➔ Unloading*.

### 4. Moves Archive & Review (`moves_screen.dart` & `move_detail_screen.dart`)
- Filter tabs for **All**, **Scheduled**, **In Progress**, and **Completed** moves.
- Full inspection of services requested, addresses, dates, and live status.
- Triggers `RatingSheet` upon completion for quality feedback.

---

## 4. Design System Tokens & Theming

All design tokens are centralized in `lib/utils/app_theme_styles.dart`:
- **AppColors.gold**: `#D4AF37` (Primary luxury accent)
- **AppColors.goldLight**: `#F5E296`
- **AppColors.goldDark**: `#997D24`
- **AppColors.background**: `#0B0C0E` (Deep luxury black)
- **AppColors.surface**: `#14171C`
- **AppColors.surfaceElevated**: `#1B1F26`
- **AppColors.border**: `#2A303C`

### Responsive Framework (`responsive_helper.dart`)
- Extensions on `BuildContext` (`context.responsive`, `context.r(size)`, `context.sp(size)`).
- Ensures seamless visual fidelity across compact phones (360dp width) through large phablets and tablets.
