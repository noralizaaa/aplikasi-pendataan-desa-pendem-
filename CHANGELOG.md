# 📦 CHANGELOG

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),  
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - 2025-05-21
> Created by **Bayu Ardiyansyah**

### 🎉 Added
- Redesigned `PrototypeScreen` with a modern UI:
    - Gradient header with a custom `BottomRightRoundedClipper` for a rounded bottom-right corner.
    - Added `SensusKu.png` asset for the title logo.
    - Included `undraw_mobile-ux_5h2w.png` illustration with fade-in animation.
    - Added a description text: "Aplikasi Pendataan dan Pengelolaan Desa oleh BPS Kota Batu."
    - Implemented a "START" button with custom styling (green color: `0xFF00D1A3`).
- Enhanced `PrototypeController` to manage staggered fade-in animations for the logo and illustration.
- Added new asset `SensusKu.png` to `pubspec.yaml`.

### 🛠️ Changed
- Updated `PrototypeScreen` layout from a simple centered text to a two-section design:
    - Top section: Gradient background with `bps.png`, `SensusKu.png`, and `undraw_mobile-ux_5h2w.png`.
    - Bottom section: White background with description and "START" button.
- Modified `PrototypeController` to reduce animation delay from 1000ms to 500ms for smoother transitions.
- Adjusted `SplashScreen` to remove `FadeInAnimation` temporarily to troubleshoot navigation issue.
- Changed `SplashBinding` to use `Get.put` instead of `Get.lazyPut` to eagerly initialize `SplashController`.

### 🐛 Fixed
- Fixed asset loading lag in `PrototypeScreen` by adding `precacheImage` for `bps.png`, `SensusKu.png`, and `undraw_mobile-ux_5h2w.png`.

### 🚨 Issues
- App remains stuck on the splash screen; `SplashController`’s `onInit` or `onReady` not executing, preventing navigation to `PrototypeScreen`.

---

## [0.2.0] - 2025-05-15
> Created by **Bayu Ardiyansyah**

### 🎉 Added
- Implemented `SplashScreen` with `bps.png` logo and a fade-in animation using `FadeInAnimation` widget.
- Added `SplashController` to handle navigation to `PrototypeScreen` after a 3-second delay.
- Configured centralized routing in `routes.dart` with `AppRoutes` for `/splash` and `/prototype`.
- Integrated Firebase for authentication and Firestore (initial setup).
- Added `EnvironmentsBadge` to display development environment status.

### 🛠️ Changed
- Updated `pubspec.yaml` to include `get: ^4.6.5` and `firebase_core`.
- Modified `main.dart` to use `GetMaterialApp` with centralized routes and `AppTheme`.

### 🐛 Fixed
- Resolved initial asset loading issues by correctly declaring `bps.png` in `pubspec.yaml`.

---

## [0.1.0] - 2025-05-10
> Created by **Bayu Ardiyansyah**

### 🎉 Added
- Initialized Flutter project with GetX for state management and navigation.
- Created basic `PrototypeScreen` with centered "Prototype" text.
- Set up project structure with clean architecture:
    - `lib/navigation/`: Routing and bindings.
    - `lib/presentation/`: Screens and controllers.
    - `lib/theme/`: App theme configuration.
- Added `bps.png` asset for the BPS logo.
- Configured `main.dart` with `GetMaterialApp` and initial theme.

### 🛠️ Changed
- Set up initial dependencies in `pubspec.yaml`: `flutter`, `get`, and `cupertino_icons`.

### 🐛 Fixed
- Fixed initial build errors by ensuring correct Flutter SDK version.