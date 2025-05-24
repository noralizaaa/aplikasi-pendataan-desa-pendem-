# 📦 CHANGELOG

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),  
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0] - 2025-05-24
> Created by **Bayu Ardiyansyah**

### 🎉 Added
- **firebase integration(Core Setup)**
- **User Authentication System (Initial Implementation):**
  - Created `LoginScreen` for user authentication, featuring username and password input fields.
  - Implemented `LoginController` to manage login logic, including state management for input fields, password visibility, and loading indicators.
  - Added basic validation for login credentials (e.g., checking for empty fields).
  - **Dummy User Role-Based Navigation:**
    - Integrated a simple mechanism to differentiate between 'user' and 'admin' roles after successful login.
    - Created `UserHomePage` (dummy screen) for regular users.
    - Created `AdminDashboardPage` (dummy screen) for admin users.
    - Configured routing to navigate to the appropriate home page based on login credentials.
- **New UI Elements:**
  - Custom styled `TextField` widgets for username and password with `OutlineInputBorder` and focus effects.
  - `Obx` widget for reactive UI updates, especially for password visibility toggle and loading state on the login button.
  - `ElevatedButton` for login action with loading indicator (`CircularProgressIndicator`) when authentication is in progress.

### 🛠️ Changed
- **Router Configuration:**
  - Updated `routes.dart` to include new routes for `/login`, `/user_home`, and `/admin_dashboard`.
  - Modified initial route logic to direct to `LoginScreen` as the entry point after `SplashScreen` (or directly if Splash screen is bypassed).
- **Dependency Management:**
  - Ensured `get` package is correctly configured and utilized for state management and routing in the new login flow.

### 🐛 Fixed
- (No specific fixes related to this feature addition, assuming previous issues are still pending or resolved in other commits)

---

## [0.3.1] - 2025-05-24
> Created by **Bayu Ardiyansyah**

### 🛠️ Changed
- **`LoginScreen` UI/UX Enhancements:**
  - Modified `pageBackgroundColor` to a pure light blue shade (`0xFFF2FAFF`) by removing opacity, providing a cleaner, almost white background.
  - Adjusted `AppBar` leading icon (back arrow) color from `primaryTextColor` (white) to `Colors.black54` for improved visibility and contrast against the new light background.
  - Updated primary text color for the title (`Silakan isi Username dan Password Terlebih Dahulu`) from `primaryTextColor` (white) to `Colors.black87` to ensure clear readability on the light background.

---

## [0.3.0] - 2025-05-21
> Created by **Bayu Ardiyansyah**

### 🎉 Added
- **`PrototypeScreen` Redesign:**
  - Implemented a modern UI with a gradient header and a custom `BottomRightRoundedClipper` for a rounded bottom-right corner.
  - Integrated `SensusKu.png` asset as the main title logo.
  - Added `undraw_mobile-ux_5h2w.png` illustration with a smooth fade-in animation.
  - Included a descriptive text: "Aplikasi Pendataan dan Pengelolaan Desa oleh BPS Kota Batu."
  - Implemented a prominent "START" button with custom green styling (`0xFF00D1A3`).
- **`PrototypeController` Enhancements:**
  - Added logic to manage staggered fade-in animations for both the logo and the illustration, enhancing visual appeal.
- **Asset Integration:**
  - Added `SensusKu.png` to `pubspec.yaml` for project use.

### 🛠️ Changed
- **`PrototypeScreen` Layout Rework:**
  - Transformed from a simple centered text layout to a sophisticated two-section design.
  - Top section now features a gradient background integrating `bps.png`, `SensusKu.png`, and `undraw_mobile-ux_5h2w.png`.
  - Bottom section now presents a clean white background with the application description and the "START" button.
- **`PrototypeController` Animation Timing:**
  - Reduced animation delay from 1000ms to 500ms for smoother and faster transitions.
- **`SplashScreen` Navigation Adjustment (Temporary):**
  - `FadeInAnimation` was temporarily removed to troubleshoot a navigation issue.
- **`SplashBinding` Initialization Strategy:**
  - Changed from `Get.lazyPut` to `Get.put` to ensure eager initialization of `SplashController`, aiming to resolve navigation problems.

### 🐛 Fixed
- **Asset Loading Performance:**
  - Addressed asset loading lag in `PrototypeScreen` by implementing `precacheImage` for `bps.png`, `SensusKu.png`, and `undraw_mobile-ux_5h2w.png`, ensuring faster image display.

### 🚨 Issues
- **Splash Screen Navigation Blocker:**
  - The application remains stuck on the splash screen; `SplashController`’s `onInit` or `onReady` methods are not executing as expected, preventing proper navigation to `PrototypeScreen`. This remains a known issue.

---

## [0.2.0] - 2025-05-15
> Created by **Bayu Ardiyansyah**

### 🎉 Added
- **Splash Screen Implementation:**
  - Introduced a `SplashScreen` featuring the `bps.png` logo with an integrated fade-in animation using the `FadeInAnimation` widget.
- **Splash Screen Controller:**
  - Added `SplashController` responsible for managing the navigation logic, transitioning to `PrototypeScreen` after a 3-second delay.
- **Centralized Routing Configuration:**
  - Configured centralized routing in `routes.dart` utilizing `AppRoutes` for defined paths: `/splash` and `/prototype`.
- **Firebase Integration (Core Setup):**
  - **Initiated core Firebase integration across the project.** This includes:
    - Setting up `firebase_core` for application initialization.
    - Initial configuration for **Firebase Authentication** services.
    - Initial configuration for **Cloud Firestore** as the database.
    - **Note:** Further, specific Firebase feature implementations (e.g., actual login logic, data manipulation) will be detailed in subsequent versions.
- **Development Environment Indicator:**
  - Implemented `EnvironmentsBadge` to visually display the current development environment status.

### 🛠️ Changed
- **Dependency Updates:**
  - Updated `pubspec.yaml` to include `get: ^4.6.5` (GetX state management) and `firebase_core` for Firebase functionalities.
- **Main Application Setup:**
  - Modified `main.dart` to leverage `GetMaterialApp` for routing and state management, integrated with `AppTheme` for consistent styling.

### 🐛 Fixed
- **Initial Asset Loading:**
  - Resolved early asset loading issues by correctly declaring `bps.png` within `pubspec.yaml`, ensuring proper image display.

---

## [0.1.0] - 2025-05-10
> Created by **Bayu Ardiyansyah**

### 🎉 Added
- **Project Initialization:**
  - Initialized Flutter project, adopting GetX for efficient state management and streamlined navigation.
- **Basic UI Setup:**
  - Created a foundational `PrototypeScreen` displaying a simple centered "Prototype" text.
- **Clean Architecture Structure:**
  - Established a clear project structure following clean architecture principles:
    - `lib/navigation/`: Dedicated for routing logic and bindings.
    - `lib/presentation/`: Contains UI screens and their corresponding controllers.
    - `lib/theme/`: Houses application-wide theme configurations.
- **Asset Integration:**
  - Added `bps.png` asset, intended for use as the BPS logo within the application.
- **Main Application Configuration:**
  - Configured `main.dart` with `GetMaterialApp` as the root widget and applied initial theme settings.

### 🛠️ Changed
- **Initial Dependencies:**
  - Set up core dependencies in `pubspec.yaml`, including `flutter`, `get` (for GetX), and `cupertino_icons`.

### 🐛 Fixed
- **Initial Build Errors:**
  - Addressed and resolved initial build errors by ensuring the correct Flutter SDK version was utilized.