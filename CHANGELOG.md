# 📦 CHANGELOG

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),  
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).



## [0.13.1] - 2025-05-27
> Created by Lutfi Indra

>  Resolved Login/Profile Bugs and Improved User Interface

### 🎉 Added
-   **Added profile.png asset to represent the user profile picture across the application.:**

### 🛠️ Changed
-   **Landing Page UI Update: Refreshed design elements and layout for a more modern and welcoming first impression.**
-   **User Home Page UI Update: Improved layout consistency, spacing, and typography for enhanced usability.**
-   **User Profile Page UI Update: Redesigned UI elements to provide better clarity and aesthetic appeal.**

### 🐛 Fixed
-   **Logout/Login Issue: resolved a bug where users could not immediately log in again after logging out.**
-   **Profile Page Repetition Bug: eFixed an issue on the profile page where the Pendata display was looping indefinitely (e.g., pendata1-2-3-...).**
---

## [0.12.1] - 2025-05-27
> Created by Bayu Ardiyansyah

> Enhanced Admin Dashboard with BI Features, Advanced Date Filtering, and Improved UI Consistency

### 🎉 Added
-   **Comprehensive BI Dashboard (`_DashboardContentOnly`):**
  -   Integrated key performance indicators: **Total Submissions**, **Active Users**, **Submissions per Form**, and **Form Access Overview**.
  -   Implemented a **date range filter** allowing administrators to analyze data within specific timeframes.
-   **Form Access Overview Section:**
  -   Added a new section to the dashboard displaying each available form along with the **count of users who have access** to that specific form.
  -   This provides quick insights into access management per form.
-   **Dummy Data for Trend Chart:**
  -   When no real submission trend data is available, a **placeholder chart with "Data Dummy" label** is displayed, giving a visual representation and indicating the absence of live data.
-   **New Data Fetching Methods (`AdminController`):**
  -   `_fetchFormAccessCounts()`: Fetches the number of `managedAccounts` for each form.
  -   `_fetchTotalSubmissions()`: Calculates total submissions across all forms.
  -   `_fetchTotalActiveUsers()`: Counts all registered users.
  -   `_fetchFormSubmissionCounts()`: Retrieves submission counts per individual form.
  -   `_fetchSubmissionTrend()`: Gathers data for submission trends over time.

### 🛠️ Changed
-   **Dashboard UI Overhaul:**
  -   **Date Filter Section (`_buildDateFilterSection`):** Redesigned for a more modern and elegant appearance with an `InkWell` styled to look like a card, subtle borders, and shadows. Date format for display is now `dd MMMYYYY` for better readability.
  -   **Date Picker Dialog Theming:** Customized the `showDateRangePicker`'s `builder` property in `AdminController` to align its colors (header, selected dates, text) and shape (rounded dialog corners) with the app's primary and accent colors.
  -   **Metric Card Styling:** Enhanced **Total Submissions** and **Active Users** metric cards with improved elevation, rounded corners, and clear icon/text styling.
  -   **Form Submission & Access Item Styling:** Individual items in "Submissions per Form" and "Form Access Overview" sections are given a clean, card-like appearance with subtle shadows and consistent typography.
-   **`AdminController` Logic Refinements:**
  -   `WorkspaceDashboardData()`: Orchestrates fetching all dashboard-related data concurrently for efficiency.
  -   `_applyDashboardFilter()`: Now intelligently filters `formSubmissions` and `submissionTrend` based on the selected date range, recalculating `totalSubmissions` accordingly.
  -   `_filterSubmissionTrendByDate()`: Filters the `submissionTrend` data based on the applied date range.
-   **Code Structure:**
  -   Moved `_DummyChartPainter` class definition outside of `_DashboardContentOnly` to resolve "Classes can't be declared inside other classes" error, improving code organization.

### 🐛 Fixed
-   **`DateFormat` Not Defined:** Resolved by ensuring `package:intl/intl.dart` is correctly imported in `admin_controller.dart`.
-   **Firestore Permission Denied (Dashboard Data):** Addressed `permission-denied` errors by explicitly allowing `read` access to the `submissions` subcollection within `adminForms/{formId}` in Firestore Security Rules.
-   **`_buildDateFilterSection` Syntax:** Corrected a syntax error with a misplaced parenthesis in the `Row` widget within `_buildDateFilterSection`.
-   **`_DummyChartPainter` Definition:** Corrected class definition location and associated errors (`CustomPainter isn't a type`, `covariant` keyword misuse) by placing `_DummyChartPainter` as a top-level class.

---

## [0.12.0] - 2025-05-26
> Form Builder Functionality Enhancements and Stability Fixes

### 🎉 Added
-   **Roman Numeral Section Titles:** Sections in the form builder now display their index as Roman numerals followed by the user-defined title (e.g., "I. Section Title").
-   **Indonesian Phone Number Validation Guidance:** Provided format guidance and a sample Regex (`^(\+62|0)8[0-9]{8,11}$`) for "No HP" (Mobile Number) validation using the "Custom Regex Pattern" feature.

### 🛠️ Changed
-   **Parent Selection Logic for Cascading Dropdowns:** Improved the logic for identifying potential parent questions in cascading dropdown setups. Parent questions (e.g., "102 RW") are now required to have their own primary "Main Options List" populated to be selectable as a parent for subsequent questions (e.g., "103 RT").
-   **Dynamic Child Option Dialog Stability (`_showEditChildOptionsDialog`):** Significantly refactored `TextEditingController` lifecycle management within the "Manage Child Options" dialog for cascading dropdowns. This includes adjusted `dispose` strategies (e.g., using `WidgetsBinding.instance.addPostFrameCallback` and modifying `dispose` timing during save operations after option removal) to enhance stability.

### 🐛 Fixed
-   Addressed critical runtime errors (`A TextEditingController was used after being disposed.` and `_dependents.isEmpty: is not true.`) that occurred when users reduced, added, or saved changes to child options within the "Manage Child Options" dialog for cascading dropdown configurations.
-   Improved robustness of `TextEditingController` handling during dynamic list modifications within dialogs.

### 📝 Notes & Guidance
-   **Repeatable Question Groups (Rosters):** Clarified that the current "Repeatable?" feature applies to repeating individual questions. For repeating a *group* of questions (e.g., questions 204-208 based on the answer to question 203 "Number of working people?"), workarounds such as "Fixed Question Sets with Conditional Logic" or using a "Paragraph" field were outlined, as a direct "repeatable group/roster" feature is not yet available.

---

## [0.11.0] - 2025-05-26
> Created by Bayu Ardiyansyah

> Introduction of Global Account Management Page and Enhanced UI/UX for All Account Operations

### 🎉 Added
-   **Global Account Management Section (`AdminAccountPage`):**
  -   Introduced a new dedicated card/section in `AdminAccountPage` titled "**Daftar Semua Akun**".
  -   Tapping this card now navigates to the new `AllAccountPage`.
-   **Dedicated All Accounts Page (`AllAccountPage`):**
  -   Implemented a new page to list and manage all registered user accounts globally, independent of specific forms.
  -   Includes a **search bar** to filter accounts by email or username.
  -   Features a "**Buat Akun Pengguna Baru**" button to create new system users directly from this page.
-   **All Accounts Controller (`AllAccountController`):**
  -   Developed a new GetX controller to handle data fetching, searching, creation, editing, and deletion of **all user accounts** from the `/users` Firestore collection.
  -   Implements real-time listening to user data changes via Firestore snapshots.
-   **New Route and Binding:**
  -   Added `AppRoutes.allAccountManagement` and `AllAccountBinding` to the application's routing system to support the new `AllAccountPage`.

### 🛠️ Changed
-   **Modernized UI/UX for All Account Dialogs (`AllAccountPage` & `AllAccountController`):**
  -   **"Buat Akun Pengguna Baru" Dialog:**
    -   Redesigned with elegant rounded borders, improved spacing, and modern `TextField` styling (filled background, `OutlineInputBorder`).
    -   Action buttons ("Batal", "Buat Akun") are now `ElevatedButton` and `TextButton` with consistent branding colors and rounded shapes.
  -   **"Edit Akun Pengguna" Dialog:**
    -   Updated with similar modern styling as the create dialog (rounded borders, improved text fields, consistent button styles).
    -   The email field is now disabled to prevent accidental changes, visually indicated by a slightly darker background.
  -   **"Konfirmasi Hapus" Dialog:**
    -   Enhanced with a more prominent warning title (bold, red color) and clearer confirmation message.
    -   Action buttons ("Batal", "Hapus") are styled for better visual distinction, with the "Hapus" button using a strong red background.
-   **Account Item Display (`AllAccountPage`):**
  -   The "Edit" and "Delete" buttons within each account list item are now styled as `OutlinedButton` for a cleaner, less heavy appearance, with borders matching their respective action colors.
  -   Font sizes for button labels are slightly increased for better readability.
-   **Reused `AdminAccountModel`:**
  -   The existing `AdminAccountModel` is now consistently used across `AllAccountPage` and `AllAccountController` for representing user account data, promoting code reusability.

### 🐛 Fixed
-   **Navigation to All Accounts Page:** Resolved the issue preventing navigation from `AdminAccountPage` to `AllAccountPage` by correctly registering the new route and its binding in `lib/routes/app_routes.dart`.

---

## [0.10.0] - 2025-05-26
> Created by Bayu Ardiyansyah

> Enhancements to Form-Specific Account Management: New User Creation and UI/UX Overhaul for Dialogs

### 🎉 Added
- **New System User Creation via Admin Panel (`FormAccountManagementController`):**
  - Implemented `showCreateSystemUserDialog()` to allow administrators to create new user accounts directly.
  - The dialog facilitates input for `username`, `email`, and `password`.
  - New users are created in Firebase Authentication and a corresponding document is added to the `/users` Firestore collection with a default `role: 'user'`.
- **Select Existing User for Form Authority (`FormAccountManagementController`):**
  - Implemented `showSelectUserFromListDialog()` enabling administrators to grant form-specific authority to existing users.
  - The dialog fetches and displays users with the role 'user' from the `/users` collection.
  - Includes functionality to filter out users who already possess authority for the current form.
  - Selected users are granted 'user' role access for the specific form, managed in the `adminForms/{formId}/managedAccounts` subcollection.

### 🛠️ Changed
- **UI/UX Overhaul for Account Management Dialogs (`FormAccountManagementController`):**
  - **"Buat Akun Pengguna Baru" Dialog:**
    - Redesigned with a custom header, modern `TextField` styling (rounded borders, prefix icons, consistent padding), and improved layout for a more elegant and user-friendly experience.
    - Password field now includes a visibility toggle.
    - Action buttons ("Batal", "Buat Akun") styled for better visual hierarchy and clarity.
  - **"Pilih dari Daftar Pengguna" Dialog:**
    - Redesigned with a custom colored header, an integrated search bar within the dialog to filter users by name or email.
    - `ListTile` items for user selection enhanced with `CircleAvatar` (displaying initials), clearer typography for username/email, and improved spacing.
    - Loading and empty states within the dialog are made more informative.
- **Action Button Reorganization in `FormAccountManagementPage`:**
  - The primary action buttons for managing form authorities were restructured for clarity and improved workflow:
    1.  The button "Tambah Otoritas via Email" has been **replaced** by **"Buat Akun Pengguna Baru"**, which now triggers the `showCreateSystemUserDialog()`.
    2.  The button **"Pilih dari Daftar Pengguna"** (calling `showSelectUserFromListDialog()`) is retained as the second primary action.
    3.  This results in two main buttons: one for creating entirely new system users, and one for granting authority to existing users selected from a list.
- **Model Update (`ManagedAccount`):**
  - Ensured `ManagedAccount` model includes `role` and `userId` fields to properly store and display form-specific user authorities.

### 🐛 Fixed
- **Missing Parameters in `ListView.separated`:** Ensured `itemCount`, `itemBuilder`, and `separatorBuilder` are correctly implemented within the `showSelectUserFromListDialog` method in `FormAccountManagementController`, resolving potential runtime errors.
- **Firestore Query Index Requirement:** (Assumed resolved by user) This version's functionality relies on the correct composite index (`role` Ascending, `username` Ascending on `users` collection) being in place to prevent `failed-precondition` errors when fetching users for the "Pilih dari Daftar Pengguna" dialog.

---

## [0.9.0] - 2025-05-26
> Created by Bayu Ardiyansyah

> Iterative UI/UX Refinements, Form Display Logic, and Bug Fixes

### 🛠️ Changed
- **Admin "Account" Tab Major Redesign (`AdminAccountPage` & `AdminAccountController`):**
  - The "Account" tab in `AdminScreen` (managed by `AdminAccountPage` and `AdminAccountController` located in `lib/presentation/admin/Admin_Profile/`) now displays a list of existing *Forms* (`FormItem` model) fetched directly from the `adminForms` Firestore collection. This replaces its previous functionality of displaying "Account Management Categories."
  - `AdminAccountController` has been refactored to fetch an `RxList<FormItem>` using Firestore real-time streams (`snapshots().listen()`), ordering forms by creation date.
  - `AdminAccountPage` UI has been completely redesigned to list these `FormItem`s. Each item card now shows the form's title, description, creation date, and total questions.
  - Implemented a `PopupMenuButton` on each form card in the "Account" tab for actions like "Delete Form," with the confirmation dialog logic now handled within `AdminAccountController`.
  - The `_getIconFromString` helper in `AdminAccountPage` (previously for category icons) has been adapted to show icons for form items based on their titles (e.g., a "people" icon if the form title contains "penduduk").
- **Admin Form Builder UI/UX Enhancements (`AdminFormBuilderPage`):**
  - **AppBar Styling:** The `AppBar` in `AdminFormBuilderPage` has been restyled to feature an orange gradient background and a curved bottom-right corner, aligning with the main `AdminScreen` header theme. This was achieved using `flexibleSpace` within the `AppBar` and making the `AppBar`'s `backgroundColor` transparent.
  - **Adjusted `AppBar` Height:** `toolbarHeight` was increased to comfortably accommodate the two-line title ("Management Form" and the dynamic form title).
  - **Modernized Form Input Fields:**
    - Implemented a consistent and more elegant styling for all primary `TextField`s (form title, description, section titles, question text, validation inputs) using a new `_modernInputDecoration` helper method.
    - The new style includes rounded borders (`borderRadius: 10.0`), a white fill color, a neutral grey label color when not focused, an orange accent color for the floating label (when focused or has text), and an orange accent for the focused border.
    - Refined the visual appearance of `Card`s for sections and questions with consistent elevation and border radius for a cleaner look.
    - `ExpansionTile`s used for settings (validation, repeatable, conditional jumps) have been styled for better visual integration.
    - Improved the UI for adding options in Multiple Choice/Checkbox questions (`_buildOptionsSection`) with more compact styling.
    - Enhanced the UI for the "Pilih Tipe Pertanyaan" `BottomSheet` by using a `GridView` for a more organized and user-friendly selection.
- **Admin Dashboard (`AdminScreen` & `AdminController`):**
  - Reconfirmed and ensured that `AdminController` correctly fetches and `_DashboardContentOnly` (the Dashboard tab content) displays a list of `FormItem` from the `adminForms` Firestore collection, consistent with the "Account" tab's new functionality.

### 🐛 Fixed
- **"Controller Not Found" (AdminFormBuilderController):** Resolved by ensuring `AdminFormBuilderController` is correctly registered via `AdminFormBuilderBinding` in `app_routes.dart` and by removing any direct `Get.put()` calls from the `AdminFormBuilderPage`'s `build` method. Ensured navigation to the page uses named routes to trigger the binding.
- **RenderFlex Overflow Errors in Form Builder:**
  - Addressed right-side pixel overflows in `AdminFormBuilderPage`, particularly in the "Opsi 'Lainnya'" switch row within question cards, and in option input rows for Multiple Choice/Checkbox questions. Fixes involved adjusting `Flexible`/`Expanded` widget usage, text properties (`softWrap`, `overflow`), and optimizing spacing for compact elements like `IconButton`s.
- **Firestore Permission Denied (Form Listing/Saving & Dashboard):**
  - Addressed `permission-denied` errors by guiding the update of Firestore Security Rules to allow necessary read and write operations on the `adminForms` collection for authenticated admin users. This ensures both the Form Builder can save forms and the Dashboard/Account tabs can list them.
- **Undefined Getters/Methods in Pages/Controllers:**
  - Corrected errors like "The getter 'isSaving' isn't defined" by renaming to `isBusy` in `AdminFormBuilderPage` to match `AdminFormBuilderController`.
  - Fixed "The method 'getArgumentFormId' isn't defined" by adding a public getter `isEditMode` in `AdminFormBuilderController` and using it in `AdminFormBuilderPage`.
  - Resolved "This expression has a type of 'void' so its value can't be used" for `RefreshIndicator`'s `onRefresh` by ensuring the called controller method (e.g., `refreshFormsData()` in `AdminFormController`) returns a `Future`.
  - Fixed "The getter 'isLoadingDashboard' isn't defined" in `AdminScreen` by ensuring it uses `controller.isLoading` from `AdminController`.
- **`const` Expression Error in `DropdownMenuItem`:** Resolved by removing the `const` keyword where non-compile-time constant colors (e.g., `Colors.green.shade700`) were used within `DropdownMenuItem`'s child hierarchy in `AdminFormBuilderPage`.
- **Typo `sectionIndex` vs `questionIndex`:** Corrected a variable name typo in `_buildQuestionCard`'s title string in `AdminFormBuilderPage`.
- **Ambiguous Import/Type Cast Error for `AdminAccountController`:** Resolved by enforcing consistent import path capitalization (`Admin_Profile` vs `admin_profile`) for `AdminAccountController` and its related model across all relevant files (including `app_routes.dart` within `AdminBinding`, and `AdminAccountPage.dart`).
- **Redundant Firebase Initialization in Controllers:** Ensured controllers like `AdminFormController` correctly use pre-initialized Firebase instances (`FirebaseFirestore.instance`, `FirebaseAuth.instance`) and removed any redundant re-initialization or direct use of `__app_id` for basic collection paths.

---

## [0.8.0] - 2025-05-25
> Created by Bayu Ardiyansyah

### 🎉 Added
- **Dedicated Admin Profile Page (`AdminProfilPage`):**
  - Created a new, separate admin profile page (`lib/presentation/admin/profil/admin_profil_page.dart`) accessible via the profile icon in the `AdminScreen` header.
  - Implemented `AdminProfilController` (`lib/presentation/admin/profil/admin_profil_controller.dart`) to manage fetching and displaying admin details (username, role, photo) from Firestore for this page.
  - Created `AdminProfilModel` (`lib/presentation/admin/profil/admin_profil_model.dart`) for this page.
  - Added `AdminProfilBinding` (`lib/presentation/admin/profil/admin_profil_binding.dart`) for dependency injection.
  - Implemented UI for `AdminProfilPage` featuring a custom `SliverAppBar` for header display and profile information cards.
  - **Username Editing Feature:**
    - Added an edit icon next to the username on `AdminProfilPage`.
    - Implemented `promptEditUsername()` in `AdminProfilController` to show a dialog for username input.
    - Implemented `updateUsername()` in `AdminProfilController` to save the new username to Firestore (updating `username` and `displayName` fields in the `users` collection) and refresh the UI.
- **New Route for Dedicated Admin Profile:**
  - Added `/admin-profil` route in `app_routes.dart` pointing to `AdminProfilPage` with its `AdminProfilBinding`.

### 🛠️ Changed
- **`AdminAccountPage` (Account Tab) Refactoring:**
  - Redesigned `AdminAccountPage` (`lib/presentation/admin/Admin_Profile/admin_account_page.dart`) to display a list of "Kategori Manajemen Akun" (Account Management Categories) fetched from Firebase, matching the new provided UI design.
  - `AdminAccountController` (`lib/presentation/admin/Admin_Profile/admin_account_controller.dart`) was refactored to:
    - Fetch and manage a `RxList<AccountCategoryItem>` from a Firestore collection (e.g., `adminAccountCategories`).
    - Removed logic related to displaying detailed user profile information (username, role), as this is now handled by `AdminProfilPage`.
  - `AdminAccountPage` now uses `AccountCategoryItem` model (from `lib/presentation/admin/Admin_Profile/admin_account_model.dart`) for displaying these categories.
  - Implemented `_getIconFromString()` helper in `AdminAccountPage` to map `iconName` strings (from Firestore) to `IconData` for display. Emphasized that the `case` statements within this function must be customized by the user based on their actual `iconName` values in Firestore.
  - Ensured `AdminAccountPage` displays a "Belum Ada Kategori" message if the Firestore collection is empty, not dummy data.
- **Navigation in `AdminScreen`:**
  - Updated the `onTap` action for the profile icon in the `AdminScreen` header to navigate to the new `/admin-profil` route (`Get.toNamed(AppRoutes.adminProfil)`).
- **`AdminController` (`admin_controller.dart`):**
  - Modified `adminName` to be an `RxString` (e.g., `var adminName = ''.obs;`).
  - Implemented logic (e.g., using an `ever` worker or fetching in `onInit`) to update `adminName` based on the logged-in user's display name, likely sourced from `LoginController` or an auth service, to ensure the "Hello, [AdminName]" in `AdminScreen` header is reactive and correct.
  - Refactored `_loadDashboardItems()` to fetch real data from Firestore instead of using dummy data, updating `isLoading` and `dashboardItems` observables.
- **Firestore Security Rules:**
  - Updated Firestore Security Rules to explicitly allow authenticated read access to the `dashboardItems` collection.
  - Advised on adding rules for the `adminAccountCategories` collection (or the user-specified path for account management categories) to allow read access for authenticated users or specific roles.

### 🐛 Fixed
- **Type Cast Error for `AdminAccountController`:**
  - Addressed `type 'AdminAccountController' is not a subtype of type 'AdminAccountController'` error by ensuring consistent import path capitalization for `AdminAccountController` and related files across the project (specifically using `Admin_Profile` if that's the actual folder name).
  - Emphasized using `flutter clean` and full app restarts after correcting import paths.
- **`refreshProfile` Method Undefined Error:**
  - Ensured the `refreshProfile()` public method is correctly defined in `AdminAccountController` and `AdminProfilController` and called by the `RefreshIndicator` in their respective pages.
- **`.value` on non-RxString Error:**
  - Corrected errors like "The getter 'value' isn't defined for the type 'String'" by ensuring that reactive variables (e.g., `adminName` in `AdminController`) are properly declared as Rx types (e.g., `RxString`) and accessed with `.value` in `Obx` widgets.
- **Firestore Permission Denied for Dashboard Items:**
  - Resolved by guiding the update of Firestore Security Rules to allow read access to the `dashboardItems` collection for authenticated users or appropriate roles.

---

## [0.7.0] - 2025-05-25
> Created by **Bayu Ardiyansyah**

### 🎉 Added
- **Form Builder Module (Advanced):**
  - Introduced a robust `AdminFormBuilderPage` (`lib/presentation/admin/formpage/admin_form_builder_page.dart`) for creating and editing dynamic forms.
  - Implemented `AdminFormBuilderController` (`lib/presentation/admin/formpage/admin_form_builder_controller.dart`) to manage form structure, questions, and saving to Firestore.
  - Enhanced `FormItem` Model: Significantly updated `lib/presentation/admin/formpage/admin_form_model.dart` to support:
    - **Sections (`FormSection`):** Grouping of questions.
    - **Diverse Question Types (`QuestionType` enum):** Short Text, Paragraph, Number, Date, Multiple Choice, Checkboxes, Dropdown.
    - **Question Properties:** `isRequired`, `hasOtherOption` (for text input in multiple choice/checkboxes).
    - **Validation Rules (`ValidationRule`):** Min/Max length (text), Min/Max value (number).
    - **Conditional Logic (`ConditionalJump`):** Ability to define jump rules based on answers (e.g., "if answer is 'No', jump to question X").
    - **Repeatable Questions:** Flag to indicate if a question can be repeated (e.g., daily entries).
  - **Firestore Integration for Forms:** Forms created/edited via the builder are now saved to and loaded from Firestore, including their complex question structures.
  - **UUID Generation:** Integrated `uuid` package for generating unique IDs for questions and sections.
- **Admin Account Management UI (Initial Version - Detail View):**
  - Implemented an earlier version of `AdminAccountPage` (`lib/presentation/admin/Admin_Profile/admin_account_page.dart`) focused on displaying detailed admin profile info (username, role, logout), matching a previous design.
  - Corresponded with an earlier `AdminAccountController` and `AdminAccountModel` for this detailed view.
- **Authenticated User Model (`AuthUser`):**
  - Introduced `AuthUser` model (`lib/models/auth_user.dart`) to represent properties of any authenticated user (admin or regular user), including `displayName`, `roleFromFirestore`, and `programId`.
  - `AuthUser` is built from Firebase `User` objects and extended with data from Firestore `UserModel`.
- **Admin Dashboard UI:**
  - Implemented `AdminScreen` (`lib/presentation/admin/admin_view.dart`) with a new UI layout matching the provided design.
  - Features a gradient header, search bar, and dynamic dashboard cards for various data collection programs.
  - Designed with reusable color definitions for consistency.
- **Admin Dashboard Model:**
  - Created `DashboardItem` model (`lib/presentation/admin/admin_model.dart`) to structure data for dashboard cards (title, category, location, `programId`).
  - Populated dashboard with static dummy data for initial display.
- **Bottom Navigation for Admin:**
  - Implemented a `BottomNavigationBar` in `AdminScreen` to switch between "Dashboard", "Form", and "Account" tabs.
  - Utilized `IndexedStack` in `AdminScreen` to manage tab content, preserving state between switches.
- **Firestore User Data Integration:**
  - `LoginController` now attempts to fetch `UserModel` data from Firestore (`users` collection) for authenticated users to retrieve their `role`.
  - Includes logic to create a default `UserModel` document in Firestore if one doesn't exist for a newly logged-in user.
- **Logging for Authentication Flow:**
  - Added extensive `print` statements throughout `LoginController` to provide detailed debug logs for authentication state changes, data loading, and navigation decisions.

### 🛠️ Changed
- **LoginController Refactoring:**
  - Renamed `loggedInUser` to `loggedInAuthUser` and changed its type to `Rx<AuthUser?>`, aligning with the new `AuthUser` model.
  - Adjusted `_loadAndSetAuthUser` to combine Firebase Auth user data with Firestore `UserModel` data into a comprehensive `AuthUser` object.
  - Modified navigation logic in `_navigateToAppropriatePage` to use `AuthUser` properties (`displayName`, `roleFromFirestore`, `programId`).
  - Consolidated fallback logic for login failures to consistently create a fallback `AuthUser` and navigate.
- **AdminController Updates (Initial):**
  - `AdminController` initially retrieved `adminName`, `adminRole`, and `adminProgramId` directly from `LoginController`'s `loggedInAuthUser.value`.
  - Managed `selectedPageIndex` for `BottomNavigationBar`.
- **UserController and UserProfileController Adjustments:**
  - Updated to receive `userRole` (string) as an argument from `LoginController` during navigation, providing the user's role consistently.
- **UserModel (Firestore) Clarification:**
  - Reaffirmed `lib/domain/auth/models/user_model.dart` as the sole `UserModel` for Firestore data operations (containing `uid`, `email`, `role`).
  - Removed ambiguity and potential conflicts with other `UserModel` definitions by specifying `admin_model.dart` should only contain `DashboardItem`.
- **Routing Configuration (`app_routes.dart` - Initial):**
  - Adjusted `adminPage` route to no longer contain nested routes, as `IndexedStack` handles tab switching internally within `AdminScreen`.
  - Added new route `/admin-form-builder` for the dedicated form creation/editing page.
- **Firebase Initialization in Controllers:**
  - Crucially refactored `AdminFormController` and the initial `AdminAccountController` to remove redundant `Firebase.initializeApp()` calls and Firebase configuration variables.
  - Controllers now correctly obtain `FirebaseFirestore.instance` and `FirebaseAuth.instance` assuming Firebase is initialized globally.
- **AdminFormPage Navigation:**
  - Changed "Buat Form Baru" button to navigate to `AdminFormBuilderPage`.
  - Enabled tapping on existing form cards to navigate to `AdminFormBuilderPage` for editing.
  - Updated form cards to display the count of sections and total questions.
- **Persistent Header in AdminScreen:**
  - Modified `AdminScreen` to have a persistent custom header that stays visible across bottom navigation tabs.
  - `_DashboardContent` was renamed to `_DashboardContentOnly` and refactored.

### 🐛 Fixed
- **Persistent Auto-Login Issue:**
  - Addressed persistent auto-login behavior by implementing explicit `Get.offAllNamed(AppRoutes.login)` in `LoginController.onInit()`.
- **Firestore Permission Denied Errors (Initial):**
  - Identified `PERMISSION_DENIED` errors from Firestore as a security rule issue.
  - Updated Firestore Security Rules to explicitly allow authenticated read/write access to `artifacts/{appId}/public/data/{collectionName}` paths.
- **"Undefined getter" Errors (Initial):**
  - Resolved persistent "The getter 'loggedInAuthUser' isn't defined for the type 'LoginController'." errors through code correction and build cleaning.
- **Google Play Services Warning:**
  - Noted Google Play Services being out of date.
- **FirebaseOptions.fromJson and typeof Errors:**
  - Corrected `FirebaseOptions` instantiation logic.
  - Removed invalid JavaScript operators.
- **admin-restricted-operation Error:**
  - Resolved by preventing redundant Firebase authentication attempts in child controllers.

### 🚨 Issues
- **Google Play Services Out of Date Warning:**
  - `Google Play services out of date` warnings observed; recommend updating.
- **Conditional Logic Execution (Form Builder):**
  - Runtime execution of conditional logic in the form filling page is not yet implemented.
- **Advanced Validation (Form Builder):**
  - Complex validation rules require custom implementation in the form filling page.
- **Repeatable Question UI (Form Builder):**
  - UI for filling out repeatable questions is not yet implemented in the form filling page.

---

## [0.5.0] - 2025-05-25
> Created by **Bayu Ardiyansyah**

### 🎉 Added
- **User Profile Management Feature:**
  - Implemented `UserProfileScreen` with a visually consistent design matching provided mockups, including a gradient header, profile avatar, and account information cards.
  - Developed `UserProfileController` to manage user profile data (`username`, `role`, `programId`).
  - Created `UserProfile` model (`user_profile_model.dart`) to structure user profile data.
  - **Dynamic Default Username Generation:** `UserProfileController` now assigns sequential default usernames (e.g., 'Pendata 1', 'Pendata 2') if a username is not provided during navigation.
  - **Dynamic Role/Authority Display:**
    - `UserProfileController` attempts to fetch the role name from Firestore based on a `programId` passed during navigation (e.g., '001' for 'DC-Penduduk').
    - If `programId` is '000' or not provided/found, a default "Tidak ada otoritas" role is fetched from Firestore (requires a document with `idForm: '000'` in the 'forms' collection).
  - **Username Editing Functionality:** Users can now edit their username directly on the `UserProfileScreen` via a `TextField` and save changes (currently client-side, with a placeholder for backend persistence).
- **New Routes and Bindings:**
  - Added `UserProfileBinding` to `app_routes.dart` for proper initialization of `UserProfileController`.
  - Registered `/user-profile` route in `AppRoutes` for navigation to the `UserProfileScreen`.

### 🛠️ Changed
- **Navigation from `UserScreen`:**
  - The profile icon in `UserScreen` is now clickable and navigates to `UserProfileScreen` using the new `/user-profile` route.
  - `UserScreen` now passes the `userName` and the associated `programId` (if available) as arguments to `UserProfileScreen` to facilitate dynamic profile display.
- **UserController Enhancements:**
  - `UserController` now receives and stores `userProgramId` from login arguments, which can be used to filter forms based on the user's authority/program access.
  - Modified `WorkspaceFormData` logic in `UserController` to conditionally display forms based on `userHasAuthority` or `userProgramId` (e.g., only non-authority forms for ID '000', or forms matching the specific program ID).
- **LoginController Logic:**
  - Updated `signIn` method in `LoginController` to pass `userName` and `programId` (representing the user's role/authority ID) as arguments to `UserScreen` after authentication.
  - Implemented fallback logic in `LoginController` to generate default usernames and a '000' `programId` if login fails or no explicit user data is available.
- **Model Flexibility:**
  - Modified `username` field in `UserProfile` model (`user_profile_model.dart`) from `final` to `String` to allow its value to be updated for the editing feature.

### 🐛 Fixed
- **Routing Mismatch:**
  - Resolved the `Null check operator used on a null value` error occurring on profile icon click by correcting the route name from `'/user_profile'` to `AppRoutes.userProfile` (which resolves to `'/user-profile'`) in `UserScreen`, aligning with `app_routes.dart` definitions.
- **Undefined Type Errors:**
  - Addressed "Undefined name 'FormDataModel'" and "The name 'UserProfile' isn't a type" errors by ensuring correct `package:` import paths for `user_model.dart` and `user_profile_model.dart` in their respective controllers (`user_controller.dart` and `user_profile_controller.dart`).
- **UserProfile.fromMap Syntax:**
  - Corrected the `factory UserProfile.fromMap` constructor signature in `user_profile_model.dart` to `Map<String, dynamic> data`.
- **Username Update Persistence:**
  - Ensured `userProfile.refresh()` is called after updating the `username` in `UserProfileController` to trigger UI updates in `Obx` widgets.

---

## [0.4.0] - 2025-05-24
> Created by **Bayu Ardiyansyah**

### 🎉 Added
- **Firebase Integration (Core Setup):**
  - Initiated core Firebase integration across the project, including `firebase_core`, Firebase Authentication, and Cloud Firestore.
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
- **LoginScreen UI/UX Enhancements:**
  - Modified `pageBackgroundColor` to a pure light blue shade (`0xFFF2FAFF`) by removing opacity, providing a cleaner, almost white background.
  - Adjusted `AppBar` leading icon (back arrow) color from `primaryTextColor` (white) to `Colors.black54` for improved visibility and contrast against the new light background.
  - Updated primary text color for the title (`Silakan isi Username dan Password Terlebih Dahulu`) from `primaryTextColor` (white) to `Colors.black87` to ensure clear readability on the light background.

---

## [0.3.0] - 2025-05-21
> Created by **Bayu Ardiyansyah**

### 🎉 Added
- **PrototypeScreen Redesign:**
  - Implemented a modern UI with a gradient header and a custom `BottomRightRoundedClipper` for a rounded bottom-right corner.
  - Integrated `SensusKu.png` asset as the main title logo.
  - Added `undraw_mobile-ux_5h2w.png` illustration with a smooth fade-in animation.
  - Included a descriptive text: "Aplikasi Pendataan dan Pengelolaan Desa oleh BPS Kota Batu."
  - Implemented a prominent "START" button with custom green styling (`0xFF00D1A3`).
- **PrototypeController Enhancements:**
  - Added logic to manage staggered fade-in animations for both the logo and the illustration, enhancing visual appeal.
- **Asset Integration:**
  - Added `SensusKu.png` to `pubspec.yaml` for project use.

### 🛠️ Changed
- **PrototypeScreen Layout Rework:**
  - Transformed from a simple centered text layout to a sophisticated two-section design.
  - Top section now features a gradient background integrating `bps.png`, `SensusKu.png`, and `undraw_mobile-ux_5h2w.png`.
  - Bottom section now presents a clean white background with the application description and the "START" button.
- **PrototypeController Animation Timing:**
  - Reduced animation delay from 1000ms to 500ms for smoother and faster transitions.
- **SplashScreen Navigation Adjustment (Temporary):**
  - `FadeInAnimation` was temporarily removed to troubleshoot a navigation issue.
- **SplashBinding Initialization Strategy:**
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
  - Initiated core Firebase integration across the project, including:
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