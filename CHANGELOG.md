**# 📦 CHANGELOG

This format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.1.0] - 2025-07-20
> Contributed by [Febri Bagus Triwibowo]

> Major improvements to numeric grid validation, refactoring of validation logic, and fixes related to the "Other" option in form submissions. Enhancements also include UI layout fixes for better user experience.

### ✨ Added
- **Numeric Grid Validation Rules (`input_user_controller.dart`):**
  - Added new validation rules specifically for the `QuestionType.gridNumeric` question type.
  - New rule `gridAllCellsRequired` ensures all cells in the numeric grid must be filled.
  - Implemented `minValue` and `maxValue` validation for each filled cell in the grid for more granular validation control.

### 🛠️ Changed
- **Refactoring of Validation Logic (`input_user_screen.dart`):**
  - Rewrote the core validation function for clearer and more structured logic.
  - Simplified the validation process for empty answers, required fields, and specific rules (minLength, maxLength, regex).
  - Replaced hardcoded comparison checks with a more dynamic `comparisonOperator`.

- **"Other" Option Handling in `admin_form_builder_page.dart`:**
  - Fixed a bug where the "Other" option text was not properly recognized when loading existing submissions.
  - The system now correctly maps free text to the "Other" option in checkbox-type questions.
  - Improved UI layout to prevent overflow, ensuring the "Other" option remains properly aligned.

### 🐛 Fixed
- **"Other" Option Data Submission Bug (`admin_form_builder_page.dart`):**
  - Fixed a bug where the internal flag for "Other" was being saved to Firestore instead of the actual user input.
  - Now, the system replaces the internal flag with the actual "Other" text before submitting the data, ensuring data integrity.

### 🔧 Refactoring & Improvements
- **Grid Data Conversion Extraction (`input_user_controller.dart`):**
  - Added the `GridMapConversion` extension with the `getGridMapForValidation` function to convert grid data to a more robust structure.
  - This reduces code duplication and enhances readability in the validation process.

- **Code Simplification (`input_user_screen.dart`):**
  - Used the `??=` operator in `submitForm` to assign `firstInvalidSectionIdToFocus`, making the code more concise and efficient.

---

## [0.31.0] - 2025-06-18
> Contributed by [Bayu Ardiyansyah]

> Fundamental enhancements to user data handling, improved data export logic, and increased robustness of form data submission.

### ✨ Added
- **Intelligent Fallback for Submitter Name on Export (`submissions_form_controller.dart`):**
  - Implemented an intelligent fallback mechanism when exporting old data that lacks a `userName`.
  - If `userName` is empty, the system now retrieves the `userId` from the submission data, looks it up in the `users` collection in Firestore, and uses the `username` from that collection as the submitter's name in the exported file (JSON/CSV/XLSX).
  - Added a caching system for fetched usernames to avoid repeated database queries for the same user, ensuring the export process remains efficient.

### 🛠️ Changed
- **Submitter Name Storage Priority (`input_user_controller.dart`):**
  - Changed the `userName` storage logic when a user submits a new form.
  - The priority order was changed to:
    1.  **User's Email** (as the primary priority).
    2.  **Full Name (DisplayName)** (used if the email is unavailable).
    3.  The text "Unknown User" (as the final fallback if both are empty).
  - This change ensures that all new data entering the database will always have an informative and consistent `userName`, prioritizing email as required.

### 🐛 Fixed
- **Empty `userName` Storage:**
  - The issue where submissions could be saved with an empty `userName` has now been prevented at its source.
  - With the new logic in `input_user_controller.dart`, every new submission is guaranteed to have a valid `userName`, retrieved from the authentication details of the currently logged-in user. This effectively eliminates the "empty submitter name" issue for all future entries.

---

## [0.30.0] - 2025-06-10
> Contributed by [Bayu Ardiyansyah]

> Added descriptive text support for each answer option to enhance clarity for form respondents.

### ✨ Added
- **Answer Option Descriptions:** A new feature has been implemented allowing administrators to add a descriptive text to each individual answer option (e.g., for Multiple Choice, Checkboxes, Dropdown).
  - **Data Model (`admin_form_model.dart`):** Introduced a new `QuestionOption` class to store both a `value` and a `description`. The `FormQuestion` model was updated to use `List<QuestionOption>` and includes backward compatibility to correctly load older forms.
  - **Admin Form Builder (`admin_form_builder_page.dart`):** The question editor UI now includes a dedicated text field for adding or editing the description for each answer option.
  - **User Input Form (`input_user_screen.dart`):** The user-facing form now displays these descriptions as a subtitle below each corresponding option, making the choices clearer and more informative for the person filling out the form.
  - **Edit Mode Support (`input_user_controller.dart`):** Corrected the data population logic in edit mode (`_populateAnswersFromSubmission`) to properly recognize the new `QuestionOption` structure, ensuring that submitted answers are mapped correctly when editing a form.

---

## [0.29.4] - 2025-06-10
> Contributed by [Bayu Ardiyansyah]

> Implemented automatic question sorting by code for a consistent and logical form structure in both user and admin views.

### ✨ Added
- **Automatic Question Sorting:**
  - **User Input Form (`input_user_screen.dart`):** Questions presented to the end-user are now automatically sorted in ascending order based on their assigned `code` within each section. This ensures a logical and predictable question flow, independent of the order they were created in the database.
  - **Admin Form Builder (`admin_form_builder_page.dart`):** The question editor for administrators now also displays questions sorted by `code`. This provides a "what you see is what you get" experience, allowing admins to view and manage questions in the exact same logical sequence that users will see them.

---

## [0.29.3] - 2025-06-05
> Contributed by [Bayu Ardiyansyah]

> UI Display Fixes for Form Configuration and User Input, Application Icon Update, and Build and Dependency Adjustments.

### 🛠️ Changed
- **Application Icon:**
  - Updated the application's launcher icon (`launcher_icon.png`) for various resolutions.
- **Dependency Management:**
  - Updated and refined library version constraints in `pubspec.yaml` to improve stability (e.g., changing versions from `any` to specific versions where relevant, or updating libraries).
- **Build System & Android Configuration:**
  - Made updates to Android build configurations (`build.gradle.kts` for project and app, `AndroidManifest.xml`, `gradle.properties`).
  - Adjusted Proguard rules (`proguard-rules.pro`).
- **Firebase Integration:**
  - Updated Firebase project options configuration (`firebase_options.dart`).
- **Other Enhancements:**
  - Potential updates to controller logic (`admin_form_builder_controller.dart`) related to form creation and management.
  - Possible minor adjustments to the main admin screen (`admin_screen.dart`) and the main application file (`main.dart`).

### 🐛 Fixed
- **Form Builder User Interface:**
  - Addressed text truncation issue for the 'Opsi "Lainnya"' (Other Option) label next to the configuration switch in the question editor (`admin_form_builder_page.dart`). The label now wraps to multiple lines if necessary, ensuring full text visibility by modifying the `softWrap` and `overflow` properties of the `Text` widget.
- **User Input Form User Interface:**
  - Improved readability of long validation error messages in input fields (`input_user_screen.dart`). Error messages in `TextFormField`s now wrap correctly across multiple lines through updates to `_modernInputDecoration`, which includes explicit `errorMaxLines` and `errorStyle`.

---

## [0.29.2] - 2025-06-03
> Created by Lutfi Indra Nur Praditya

> Answer state initialization to support both new entries and edit mode with fallback to defaults.

### 🛠️ Changed
-   **Answer State Initialization (`_initializeStatesBasedOnMode`):**
  - Resets all answer states to default (empty/null) based on the form definition.
  - In edit mode, if submission data is loaded, `_populateAnswersFromSubmission()` is called to overwrite defaults with submitted answers.
  - Questions without submitted answers retain their default values, as expected.

---

## [0.29.0] - 2025-06-03
> Contributed by [Lutfi Indra Nur Praditya]

> Enhanced number-type validation with dynamic comparison logic and improved display of comparison rules.

### 🎉 Added
-   **Helper `_getComparisonOperatorDisplayText`:**
  - Added in `InputUserScreen` to convert shorthand operators (e.g., `"lessThan"`) into user-friendly text (e.g., `"less than"`), similar to `admin_form_builder_page`.

### 🛠️ Changed
-   **Number Question Validation (`validatorFunction`):**
  - Checks if `comparisonOperator` and `compareToQuestionId` are valid before proceeding.
  - Retrieves the target question using `controller.findQuestionById()`.
  - Fetches the target answer from:
    - `repeatableGroupAnswers` if inside the same repeating group.
    - `userAnswers` if outside.
  - Applies dynamic comparison logic via `switch` based on the operator.

---

## [0.28.3] - 2025-06-03
> Contributed by [Lutfi Indra Nur Praditya]

> Navigation and section handling for cleaner jumps and better user control.

### 🎉 Added
-   **Auto-Expand Section:**
  - Automatically expands the section if the form contains only one.

### 🛠️ Changed
-   **Jump Logic (`_performJump`):**
  - No longer modifies `expandedSectionId` automatically.
  - Section expansion now only happens via user toggle or validation errors on submit.
-   **Jump Target Validation:**
  - Ensures `effectiveNextVisibleQId` is valid; defaults to end of form if not.
-   **Form Cleanup on Jump:**
  - Clears answers and hides questions after `currentQuestionId` before jumping.

### 🐛 Fixed
-   **Section Expansion Bug:**
  - Prevented unintended section changes during automated jumps.

---

## [0.28.2] - 2025-06-03
> Contributed by [Febri Bagus Triwibowo]

### ✨ Added
- **Splash Screen Image**: Added new asset `DaunSS.png` to `assets/images/` directory.
- **Splash Screen Update**: Integrated the `DaunSS.png` image into the splash screen at `lib/presentation/splash/splash_screen.dart`.

### 🎨 Changed
- **Landing Page Title Styling**: Enhanced the text styling for the landing page title "SENSUSKU - Sistem Entri dan Survei untuk Statistik Desa/Kelurahan" in `LandingPage.dart`, making it more visually appealing and prominent.

---

## [0.28.1] - 2025-06-03
> Contributed by [Bayu Ardiyansyah]

### 🛠️ Changed
- **Unified Validation Error Notifications**: All form validation error messages are now consolidated into a **single, scrollable snackbar notification**. This prevents "notification spam" when multiple fields fail validation, providing a cleaner user experience. The snackbar now displays a list of all problematic question IDs or names.
- **Improved Dialog Handling on Form Submission**: The confirmation dialog that appears before submitting/saving a form now **closes immediately** when "Yes, Send/Save" is tapped. If validation fails, the user remains on the form screen (it doesn't "get back" to the previous page), allowing them to correct errors. Navigation to the list of submissions only occurs if the form submission is fully successful.

### 🐛 Fixed
- Resolved an issue where multiple individual snackbars would appear for each validation error, leading to a cluttered user interface.
- Corrected the navigation flow to ensure the form screen is not automatically dismissed upon validation failure.

---

## [0.28.0] - 2025-06-03
> Contributed by [Lutfi Indra Nur Praditya]

> Changed input form mechanism, especially for grid questions and repeatable groups

### 🎉 Added
- The function `_mapAnswerToCorrectType` now accepts the full `questionDef` object instead of just the type, enabling handling of single grids with the "default_row" key from Firestore.
- Introduced `updateRepeatableGroupCount` as the central handler for changes in the number of items within repeatable groups (e.g., number of family members), including adjustment of the current display index when the count decreases.

### 🛠️ Changed
- In `InputUserScreen.dart`, the field `'noKK'` is now used with strict validation requiring exactly 16 digits for the Family Card Number.
- Updated function calls in `_populateAnswersFromSubmission` to ensure consistency with other parts like `evaluateAndExecuteJumps`.
- Modified section expansion in the build method:
  - Removed `onTap` from `InkWell`.
  - Replaced expand/collapse button with an `IconButton` calling `controller.toggleSectionExpansion(section.id)`.
- For the GridNumeric Question (`_buildQuestionInput`):
  - Maintained nested Map structure in `effectiveGridAnswers`.
  - Horizontal headers now come from `gridSubColumnLabels`, vertical headers from `gridColumnLabels`.
  - Inputs are generated by looping through columns and sub-columns.
  - Adjusted `getSafeCellValue` and `controller.updateGridAnswer` to use original key structure (`superRow`, `originalCol`, `originalSubCol`).
  - Updated `Key` and `columnWidth` (using `FixedColumnWidth`) to ensure stable and unique layout.
- Changed `contentPadding` from `EdgeInsets.symmetric(vertical: 0, horizontal: 2)` to `EdgeInsets.symmetric(vertical: 4, horizontal: 8)` for better spacing inside input fields vertically and horizontally.

### 🐛 Fixed
- Corrected logic in updating repeatable group counts to prevent display inconsistencies when the number of items decreases and to reset the display index if it becomes invalid.

---**

## [0.27.1] - 2025-06-02
> Contributed by [Bayu Ardiyansyah]

> Fix images decoration 

### 🎉 Added
- **Image** : Add Image Content to SplashScreen & LandingPage
- **Scrollable** : Add Scrollable function to LandingPage

### 🛠️ Changed
- **Routes Logic**
  - **Routes toLandingPage** : Change routes toLandingPage
- **IconChange** : Change Icon, newest one.
### 🐛 Fixed

- **Wrong routes** : Fix the issue of routes from SplashScreen to LandingPage ()
  Not Login)
- **LandingPageScrollabelIssue** : Fix the page to prevent unusable.


---

## [0.27.0] - 2025-06-02
> Contributed by [Lutfi Indra Nur Praditya]

> Implemented login state tracking using Firestore with support for automatic migration, state validation, and conditional navigation.

### 🎉 Added
- **Login State Field (`isLogin`) for Users:**
  - Implemented automatic migration logic to add `isLogin: false` to all existing users who do not already have the field.
  - Migration is executed only once, marked via the `system/migration_status` collection in Firestore.

- **User Login Status Initialization:**
  - On user login, the system checks whether the user document contains the `isLogin` field.
  - If not present, the field is automatically added with a default value of `true`.
  - On successful login, `isLogin` is explicitly set to `true`, and `lastLoginAt` is updated.

- **User Logout Handling:**
  - On logout, the user's `isLogin` field is set to `false`, and `lastLogoutAt` is recorded.
  - The user is also signed out from Firebase Authentication.

- **Login State-Based Navigation:**
  - On app start, if a Firebase Auth user is detected:
    - The system checks the corresponding `isLogin` status in Firestore.
    - If `isLogin` is `true`, the user is navigated to the appropriate dashboard based on their role (`admin` or `user`).
    - If `isLogin` is `false` or missing, the user is redirected to the login screen.

---


## [0.26.0] - 2025-06-01
> Contributed by [Lutfi Indra Nur Praditya]

> Fetch Value Grid Input Behavior, Enhanced "Other" Option Handling, and Strengthened Validation Logic in Form Interactions.

### 🎉 Added
-   **New State Variables:** Introduced `userOtherAnswers` and `repeatableGroupOtherAnswers` to manage text inputs for "Other" option selections.
-   **Firestore Initialization:** Implemented logic to detect and initialize "Other" option answers from Firestore into the new state variables.

### 🛠️ Changed
-   **Answer Update Logic:**
  - Adjusted answer update mechanism to reflect changes when switching to/from the "Other" option.
  - Ensures that the associated text input is cleared or restored as needed.
-   **Validation Enhancements:**
  - Added conditional validation to ensure "Other" text fields are filled if the option is marked as required.
-   **Submission Logic:**
  - Modified submission behavior to convert `_kOtherOptionValue` back to its original input text before storing to Firestore.
-   **Grid Field Behavior:**
  - **Grid Numerik (1 Baris):** Fixed issue where values were not displayed during edit mode.
  - Adjusted data loading strategy in the UI to ensure values are correctly shown for numeric grid rows.
-   **UI Layout Adjustments:**
  - Removed `mainAxisSize: MainAxisSize.min` from "Other Option" `Row` to allow it to expand fully according to its parent container.
  - Set `mainAxisAlignment: MainAxisAlignment.end` in the same `Row` to right-align the switch, allowing the label text to fill remaining space.
  - improved UI `LandingPage.dart`  

### 🐛 Fixed
-   **ART Field Validation:**
  - Resolved validation error related to the number of household members (ART) by correcting data fetching logic for ART validation.
-   **Controller Method Errors:**
  - Addressed missing method errors (`triggerDependentQuestionUpdates`, `getGridMap`) by:
    - Commenting out one unused method call.
    - Inlining the logic of the other method directly in the UI to maintain functionality and avoid controller dependencies.

---

## [0.25.0] - 2025-06-01
> Contributed by [Febri Bagus Triwibowo]

> Migration of Population Export Feature into Form-Based Export, Improved Export Structure and User Feedback

### 🎉 Added
- **New Form-Specific Export Functions in `SubmissionsFormController`:**
  - Introduced `exportSubmissionsAsJson()`, `exportSubmissionsAsCsv()`, and `exportSubmissionsAsXlsx()` methods to allow exporting submissions only for the currently selected form.
  - Added helper method `_exportToFile()` to unify the export logic and handle permission checks, file writing, and error feedback.
  - Introduced `isExporting` reactive boolean state to prevent duplicate export actions while an export is ongoing.

- **Flexible Header Builder for Exported Data:**
  - Export headers are now primarily built using `formStructure.value.questions[].questionText`, ensuring a stable and predictable column order.
  - Fallback mechanism added to derive headers from actual submissions if form structure is not available.

- **Enhanced `_convertValueForExport()` Function:**
  - Supports multiple data types (`Timestamp`, `DateTime`, `GeoPoint`, `List`, `Map`) to ensure better formatted and human-readable export output.
  - Accepts `forJson` parameter for context-aware formatting (e.g., date strings vs. raw timestamps).

### 🛠️ Changed
- **Migration of Population Export Feature:**
  - Removed the population-level export option from `admin_screen.dart`.
  - Export functionality has now been delegated to each form under `submissions_form`, enforcing a more modular data management structure.

- **Export Output Improvements:**
  - Excel (XLSX) export now uses proper cell types (`TextCellValue`, `DateTimeCellValue`, etc.) based on Dart types.
  - Improved header cell styling using the updated `excel` package API (e.g., using `ExcelColor.yellow.colorHex`).
  - Ensured worksheet names are sanitized to comply with Excel sheet name constraints.

- **Improved Export Flow and UX:**
  - Added snackbar feedback during export (loading, success, error, or cancel).
  - Integrated permission request logic using `_checkAndRequestFilePermissions()` for Android/iOS compatibility.
  - Added more robust `try-catch` with `debugPrint()` for better troubleshooting during export failures.

- **Better State Handling on Data Return:**
  - After navigating to submission edit or add screen, the list is now refreshed using `.then((_) => refreshData())`.

### 🐛 Fixed
- **AppBar Export Button Behavior in `SubmissionsFormScreen`:**
  - Export button now correctly shows a loading spinner (`CircularProgressIndicator`) when export is ongoing.
  - Ensures export menu is disabled while structure/submission data is still loading.

- **Refresh Button Fix:**
  - `IconButton` for refresh now checks both `isLoadingStructure` and `isLoadingSubmissions` to avoid unintended reloads during transitions.

- **Improved Empty State Feedback:**
  - Message now differentiates between “No submissions found” vs. “No results for your search” for clearer user understanding.

---
## [0.24.0] - 2025-05-31
> Contributed by [Lutfi Indra Nur Praditya]

> Pengembangan Fitur Admin, Peningkatan UI/UX dan Integrasi Tampilan Data Lengkap Pengguna untuk Admin

### 🎉 Added
- **Fitur Baru Admin: Halaman Manajemen Submisi**
  - Penambahan direktori `submissions_form` untuk mengelola data submisi dari sisi admin.
  - Dibuat `submissions_form_controller.dart` untuk mengambil semua data submisi pengguna, tidak terbatas pada ID tertentu.
  - Dibuat tampilan `submissions_form_screen.dart` yang menyajikan seluruh data submisi yang telah diisi oleh pengguna.
  - Penambahan route baru untuk `submissions_form_screen` dan controllernya pada `routes.dart`.

### 🛠️ Changed
- **Peningkatan Tampilan UI:**
  - Dialog konfirmasi penghapusan di `admin_form_controller.dart` diperhalus agar tidak terlihat terlalu sederhana.
  - Pada `admin_screen.dart`:
    - Judul dashboard dipersingkat agar lebih ringkas dan jelas.
    - Perubahan warna pada komponen form serta penambahan animasi klik untuk meningkatkan interaktivitas.

- **Peningkatan UX Submisi Pengguna:**
  - Pada `user_screen.dart`, tampilan daftar submisi per formulir diubah menjadi slider yang interaktif dan modern, mengikuti tema visual aplikasi.

### 🐛 Fixed
- **Sinkronisasi Profil Pengguna:**
  - Sinkronisasi antara `user_screen` dan `user_controller` agar data pengguna selalu diperbarui ketika nama diubah melalui halaman profil.

---

## [0.23.0] - 2025-05-31
> Contributed by: [Febri Bagus Triwibowo]  

> Penyempurnaan fitur Riwayat Pendataan dengan peningkatan logika model, controller, dan tampilan kartu untuk pengalaman pengguna yang lebih informatif dan akurat.

### 🎉 Added
- **Model Field:** Field `namaKepalaRumahTangga` (nullable `String`) ditambahkan ke dalam model `FormSubmission`.
- **Field Extraction Logic:** Di `fromFirestore`, nilai `namaKepalaRumahTangga` secara otomatis diekstrak dari jawaban berdasarkan `questionCode` (contoh: `"106"`).
- **Display Logic:** Tambahan pada `DisplayableSubmission` untuk menyimpan `namaKepalaKeluarga` dan `nikKepalaKeluarga` (versi NIK yang bersih/valid).
- **Sorting Option:** Opsi urutan baru di daftar: "Nama KRT A-Z".
- **InfoRow UI:** Komponen UI tambahan untuk menampilkan baris informasi "Nama KRT" dan "NIK KRT" pada kartu submission.

### 🛠️ Changed
- **NIK Filtering:** Logika `displayNikKRT` diubah agar mengosongkan NIK jika bernilai string `"1"`, sehingga tidak ditampilkan.
- **Submission Filtering:** Kartu submission yang memiliki `namaKRT` dan `displayNikKRT` kosong kini tidak ditampilkan untuk menjaga fokus data.
- **Judul Kartu:** `displayTitle` kini memprioritaskan nama dan NIK KRT sebelum fallback ke identifier umum atau judul form.
- **Pencarian:** Pencarian (`searchQuery`) kini mempertimbangkan `namaKRT` dan `displayNikKRT`, meningkatkan hasil pencarian yang relevan.
- **Data Refresh:** Method `editSubmission()` dan `goToAddSubmission()` kini memanggil `refreshData()` setelah navigasi untuk memastikan daftar selalu terkini.

### 🐛 Fixed
- **Model Sync:** Field `updatedAt` (nullable `Timestamp`) dipastikan tersedia dan disinkronkan dengan benar di `fromFirestore` dan `toFirestore`.
- **Display Accuracy:** Penyesuaian tampilan agar data nama dan NIK tidak redundan atau ambigu.
- **No Data Message:** Pesan "Data Tidak Ditemukan" kini membedakan kondisi antara tidak ada data sama sekali dan hasil pencarian kosong.

---
## [0.22.1] - 2025-05-31
> Contributed by: [Febri Bagus Triwibowo]

> Improved user profile update logic for consistency, and overhauled form UI with section-based inputs and a redesigned AppBar.

### 🎉 Added
- **Form UI:** Section-based input form using expandable cards. Only one section expands at a time for better focus.
- **AppBar:** New gradient background, dynamic button (“KIRIM” vs “SIMPAN”), and modern visual style with rounded corners.
- **Header Card:** Redesigned top info card with icon and user guidance tips for better clarity.

### 🛠️ Changed
- **Firestore Update:** `saveUsername()` now correctly updates the `username` field only, avoiding duplication like `displayName`.
- **State Sync:** UI immediately reflects username changes via `userProfile.refresh()` without needing to reload from Firestore.
- **Form Expansion Logic:** Managed via `expandedSectionId`, with helper methods to check if section has answers.

### 🐛 Fixed
- **Data Consistency:** Ensured `_loadUserProfile()` and `saveUsername()` read/write the same field in Firestore.
- **Profile Updates:** Fixed mismatch issues in Firestore updates and UI state after editing username.

---
## [0.22.0] - 2025-05-31
> Contributed by: [Bayu Ardiyansyah]

> Enhanced data export functionality with custom save locations via system file picker and resolved critical Android storage permission issues, improving export reliability across devices.

### 🎉 Added
-   **Admin Panel:** Implemented functionality for admins to select custom save locations (using system file picker) when exporting population data in JSON, CSV, and XLSX formats. Users now have full control over the export file's save directory.

### 🛠️ Changed
-   **Admin Panel:** Significantly refactored data export functions (`exportDataAsJson`, `exportDataAsXlsx`, `exportDataAsCsv`) in `AdminController`:
  -   Replaced  automatic saving to the path from `getExternalStorageDirectory()` with the use of the `file_picker` plugin for user-chosen save locations.
  -   The file saving flow now involves a system "Save As" dialog, allowing users to manually specify the filename and destination.
  -   File content (JSON string, CSV string, Excel bytes) is now converted to `List<int>` (bytes) and passed directly to `FilePicker.platform.saveFile(bytes: ...)` for more modern and Android Scoped Storage compatible file handling.
-   **Admin Panel:** Updated user messages and feedback during the data export process to reflect the new custom save location flow.

### 🐛 Fixed
-   **Admin Panel - Android Storage Permissions:**
  -   Addressed an issue where the storage permission dialog (`Permission.storage`) would sometimes not appear on certain physical devices (especially those with custom OS layers like MIUI), despite appearing correctly on emulators.
  -   Resolved a problem where the "Storage" or "Files and media" permission option was not visible in the app's system permission settings on Android in some scenarios. This fix involved thorough verification of `AndroidManifest.xml` declarations (including the final merged manifest), careful consideration of `targetSdkVersion` implications, and adjustments to the permission request strategy for better robustness across different Android versions and OEM customizations.
  -   Improved overall reliability of storage permission handling for all data export features, including more robust handling of `isPermanentlyDenied` cases by guiding users to the app settings page.
-   **Admin Panel:** Ensured that the export functions correctly use the filtered data (`_getDcPendudukSubmissions`) for generating export files. (Note: Full implementation for CSV/XLSX data flattening and content generation remains a TODO in the code, but the file saving mechanism and permission handling for these exports have been updated to use the new custom save location flow).

---
## [0.21.0] - 2025-05-30
> Created by : [lutfi Indra]

> Improved user screen data fetching and refined form UI for better display efficiency and routing behavior.

### 🎉 Added
_(No new features added in this release.)_

### 🛠️ Changed
-   **`UserScreenController`:**
  - Updated logic to fetch `username` instead of `displayName` for better clarity and consistency in user identification.
-   **`UserScreen`:**
  - Refactored to call the updated controller method to fetch and display `username`.
-   **`ListSubmissionFormScreen`:**
  - UI adjustment: Removed descriptive text elements to focus solely on the form content, improving visual clarity and reducing distraction.

### 🐛 Fixed
-   **`InputUserController`:**
  - Fixed an issue where navigating back after submission could trigger a redundant `Get.back()` call to the same route twice.
-   **`InputUserScreen`:**
  - Resolved a problem where, after editing a submission, the screen would not navigate correctly back to the submission confirmation screen via `Get.back()`.

---
## [0.20.0] - 2025-05-31
> Contributed by: [Bayu Ardiyansyah]

> Major updates to Admin Dashboard for enhanced monitoring of household data. This version re-focuses dashboard metrics on household data collection progress and refines chart displays.

### 🛠️ Changed
- **Admin Dashboard Metrics Refocus:**
  - **"Total Isian" Renamed:** Changed to "**Jumlah Rumah Tangga yang Sudah Didata**". This metric now specifically counts submissions from forms titled `DC-Penduduk`.
  - **"Tren Submission Harian" Renamed:** Changed to "**Progress Rumah Tangga yang Sudah Didata Harian**". The line chart now displays the daily count of submissions specifically for forms titled `DC-Penduduk`.
- **Dashboard UI Streamlining:**
  - **"Pengguna Aktif" Metric Removed:** The "Pengguna Aktif" (Total Active Users) metric card and its associated display section on the dashboard have been removed to simplify the view.
  - **Chart Messages Updated:** Dummy chart labels and no-data messages are updated to reflect the new terminology (e.g., "Belum ada data progres rumah tangga yang sudah didata secara keseluruhan").
- **Backend Data Fetching (`AdminController`):**
  - **Household-Specific Counting:** Modified `_fetchAllSubmissionsAndGroupThem()` to specifically count submissions from `DC-Penduduk` forms for the daily trend chart (`_fullSubmissionTrend`).
  - **`_applyDashboardFilter()` Adjustment:** Updated logic to ensure `totalSubmissions` (now "Jumlah Rumah Tangga yang Sudah Didata") accurately reflects counts only from `DC-Penduduk` forms, both with and without date filters applied.
  - **Removed User Count Fetching:** The `_fetchTotalActiveUsers()` method was removed from `AdminController`.

### 🐛 Fixed
- **Unconditional Jump Target Not Saving (`FormQuestion`):**
  - Resolved an issue where the `unconditionalJumpTarget` field was not being saved to Firestore. The `toMap()` method in the `FormQuestion` model has been updated to include this field when generating data for Firestore.
- **Chart Empty State Logic:** Improved conditions for displaying dummy chart messages to better reflect scenarios where filtered data might be empty but overall data exists, or vice-versa.
- **Grid Numeric Answer Format (`input_user_controller.dart`):**
  - Fixed an issue where grid numeric questions with empty row labels (`gridRowLabels: []`) would cause an `Invalid data. Document fields must not be empty` error during submission. The `_prepareAnswerForFirestore` method now uses a default key (`"GridData"`) for grid numeric answers when the original row label is empty, ensuring valid Firestore document field names.

---
## [0.19.1] - 2025-05-30
> Contributed by: [Bayu Ardiyansyah]

> Major Refactor of User Input Form Controller for Edit Mode, Jump Logic, and Submission Feedback. This version includes extensive fixes for initial data display in edit mode and save button responsiveness.

### 🎉 Added
- **Edit Mode Data Loading (`InputUserController`):**
  - Implemented logic to fetch existing `FormSubmission` data when `submissionId` is provided as an argument, enabling an "edit mode".
  - Introduced `loadedSubmission` (Rx<FormSubmission?>) to store fetched submission data.
  - New method `_populateAnswersFromSubmission()` to map saved answers from `loadedSubmission` to internal state variables (`userAnswers`, `repeatableGroupCounts`, `repeatableGroupAnswers`).
- **Type-Safe Answer Mapping (`InputUserController`):**
  - Added `_mapAnswerToCorrectType()` helper to ensure answers from Firestore are correctly typed (e.g., `Timestamp` to `String` for dates, `List<String>` for checkboxes, `num` for numeric grid cells) before populating UI-bound states.
- **Initial Visibility Evaluation for Jumps (`InputUserController`):**
  - New method `_evaluateAllQuestionVisibilitiesInitialPass()` designed to iterate through all questions after data (either new or from submission) is loaded. It evaluates unconditional and conditional jumps based on current answers to set the initial `questionVisibility` state correctly, ensuring only relevant questions are displayed when a form is first opened in new or edit mode.
- **Refined Jump Logic Helpers (`InputUserController`):**
  - Introduced `_getJumpTarget()` to determine the composite jump target string without side effects.
  - Introduced `_determineNextVisibleIdAfterJump()` to resolve a composite jump target to a specific next question ID.
  - Modified `_updateVisibilityBasedOnJump()` (called by initial pass) and `_performJumpAndUpdateVisibility()` (called by dynamic answer changes) for clearer visibility state management and answer clearing for skipped questions.
- **Firestore Data Preparation (`InputUserController`):**
  - Added `_prepareAnswerForFirestore()` to convert UI/state answers to appropriate Firestore types (e.g., `String` date to `Timestamp`, `String` number to `num`) before submission.

### 🛠️ Changed
- **Argument Handling in `onInit` (`InputUserController`):**
  - Refined argument parsing to correctly extract `formId` and `submissionId` when arguments are passed as a `Map`.
  - Improved error messages for invalid or missing arguments.
- **Data Fetching Orchestration (`InputUserController`):**
  - Consolidated data fetching into `fetchFormAndPotentialSubmissionData()` which now handles loading both form structure and existing submission data sequentially if in edit mode.
- **State Initialization (`InputUserController`):**
  - `_initializeStatesBasedOnMode()` now correctly branches logic for new forms versus populating from `loadedSubmission` in edit mode before evaluating initial question visibility.
  - Ensures default answer structures are created before attempting to populate them from a submission, especially for repeatable groups.
- **Jump Evaluation Flow (`InputUserController`):**
  - `evaluateAndExecuteJumps()` (for dynamic answer changes) now correctly makes the next sequential question visible if no jump occurs and then recursively calls itself for the newly visible question to handle chained logic.
  - Added `_isCurrentlyEvaluatingJumps` flag to prevent re-entrant calls during jump evaluations.
- **Submission Logic (`InputUserController`):**
  - `submitForm()` now differentiates between adding a new submission and updating an existing one (using `submissionId.value`) by calling `.add()` or `.set(..., SetOptions(merge: true))` on the Firestore collection.
  - Added an `updatedAt` timestamp when updating an existing submission.
  - Improved `isLoading` state management during submission.
  - Added a slight delay before navigation/reset after Snackbar display to ensure users see the feedback.
- **Answer Clearing (`InputUserController`):**
  - `_clearAnswersForSkippedQuestions()` now resets answers to their type-specific defaults rather than just removing keys, ensuring consistent state.
  - `_resetDependentChildrenAnswers()` made more robust.

### 🐛 Fixed
- **Method Name Typos (`InputUserController`):**
  - Exhaustively corrected all previously reported method name typos (e.g., `findQuestionById`, `_getFirstQuestionIdOfSection`, `_getSectionIdForQuestion`, `_clearAnswersForSkippedQuestions`, `_resetDependentChildrenAnswers`, `getAnswerByQuestionId`, `findQuestionByCode`) throughout the controller to resolve "method isn't defined" errors.
- **Initial Form State in Edit Mode (`InputUserController`):**
  - Addressed the issue where edit mode would display all questions instead of applying jump logic based on loaded answers by implementing `_evaluateAllQuestionVisibilitiesInitialPass()`.
- **Save Button Feedback (`InputUserController`):**
  - Ensured `isLoading` is set correctly before and after Firestore operations in `submitForm()`.
  - Ensured `Get.snackbar` for success/error is called reliably after the Firestore operation and before UI state changes that might obscure it.
- **Snackbar Display Timing**: While a delay was added, very fast operations or specific UI rebuild sequences might occasionally affect Snackbar visibility consistency.
- **Complex Initial Jump Logic in Edit Mode**: While `_evaluateAllQuestionVisibilitiesInitialPass()` aims to set initial visibility correctly, forms with very complex, deeply nested, or backward jumps based on pre-filled data might still require further fine-tuning and extensive testing to ensure perfect initial display.
- **Grid Question Jumps**: The current jump logic is primarily triggered by `onChanged` of standard input fields. Jumps *from* a grid question (e.g., an unconditional jump after the grid is "completed") are not explicitly handled by cell changes. This might require a dedicated "next" button for grids or a different trigger mechanism if post-grid jumps are needed.

### ⚠️ Known Issues / Areas for Further Testing
- **Routes back in Management Mode (`ListSubmissionFormScreen`):** After I save the edit form, it still returns to the management page but when I press the back icon, it returns to the edit page!!!
---
## [0.19.0] - 2025-05-30
> Contributed by: [Bayu Ardiyansyah]

> Enhanced Admin Form Builder with Collapsible Sections/Questions, Question Descriptions, and Improved User Input Display.

### 🎉 Added
- **Question Description Feature (`FormQuestion`, `AdminFormBuilderPage`, `InputUserScreen`):**
  - Introduced a new `description` field to the `FormQuestion` model to store detailed explanations for each question.
  - **Admin Form Builder:** Admins can now add and edit a multi-line description for every question via a dedicated `_PersistentTextField` in `_buildQuestionCard`. This allows for clearer instructions or context.
  - **User Input Form:** The question description (if provided) is now displayed directly below the main question text in `InputUserScreen` (`_buildQuestionLabel`), improving clarity for users filling out the form.
- **Collapsible Sections in Admin Form Builder (`AdminFormBuilderPage`):**
  - Implemented a "Tutup Bagian Ini" (Collapse This Section) button at the bottom of each expanded section's content. This allows admins to easily minimize long sections without needing to scroll back to the section header.
  - Utilizes `ExpansionTileController` instances managed within `AdminFormBuilderController` for programmatic control of section expansion state.
- **Collapsible Questions in Admin Form Builder (`AdminFormBuilderPage`):**
  - Each question card in `_buildQuestionCard` is now an `ExpansionTile`, allowing individual questions to be collapsed or expanded.
  - The question header (displaying number, type, code, and delete button) serves as the `ExpansionTile` title.
  - All question settings (code, text, description fields, options, validation rules, conditional logic, etc.) are now neatly contained within the expandable/collapsible content of the question's `ExpansionTile`.
  - Questions default to a collapsed state (or new ones expanded based on content) to enhance initial UI compactness for complex forms.
- **Navigation for Future Edit Submission (`ListSubmissionFormController`):**
  - The `editSubmission` method in `ListSubmissionFormController` now navigates to `InputFormUserScreen`, correctly passing both `formId` and the specific `submission.id` as arguments. This prepares the groundwork for implementing form submission editing functionality.

### 🛠️ Changed
- **Default Expansion Behavior for Sections (`AdminFormBuilderPage`):**
  - Modified the `initiallyExpanded` logic for sections in `_buildSectionCard`:
    - When creating a new form, only the first section is expanded by default.
    - When editing an existing form, all sections are collapsed by default, providing a more manageable initial view for potentially long forms.
- **Question Card UI Refactor (`AdminFormBuilderPage`):**
  - The `_buildQuestionCard` method was significantly refactored to implement the `ExpansionTile` structure for each question, encapsulating all its editable details and configuration settings.
- **`ExpansionTileController` Management for Sections (`AdminFormBuilderController`):**
  - Implemented robust creation, storage (in a `Map`), and removal of `ExpansionTileController` instances associated with each form section.
  - Corrected lifecycle management by ensuring controllers are properly associated and cleared when sections are added, removed, or when the form is loaded/re-initialized.

### 🐛 Fixed
- **Scope Resolution for Section `tileController` (`AdminFormBuilderPage`):**
  - Ensured the `ExpansionTileController` instance (`tileController`) for each section is correctly defined and accessible within its intended scope in `_buildSectionCard`, particularly for the "Collapse This Section" button's `onPressed` callback, resolving "Undefined name 'tileController'" errors.
- **`ExpansionTileController` Usage (`AdminFormBuilderController`):**
  - Corrected the handling of `ExpansionTileController` by removing erroneous calls to a non-existent `dispose()` method. These controllers do not require manual disposal; clearing references from the management `Map` is sufficient.

---

## [0.18.1] - 2025-05-29
> Created by [Febri Bagus Triwibowo]

> Redesigned User Profile UI and Added Username Edit Dialog with Consistent Admin Styling

### 🎉 Added
- **Confirmation Dialog on Logout (`UserProfileController`):**
  - Added a pop-up confirmation dialog that appears when the logout button is pressed, prompting the user to confirm before proceeding.
- **Username Edit Dialog (`UserProfileController.promptEditUsernameDialog()`):**
  - Introduced a new method to show an `AlertDialog` for editing username, consistent with `AdminProfileController`.
  - Dialog uses `usernameController` for text input and includes "Simpan" and "Batal" actions.
  - On valid input and save, it calls `saveUsername()` and refreshes user data using `_loadUserProfile()`.

- **Admin-Style Info Card Widget (`UserProfileScreen._buildInfoCard_AdminStyle()`):**
  - Added a reusable card widget visually aligned with admin profile screen.
  - Supports optional edit icon via `onEdit` callback.
  - Displays items such as Username, Role, and (optionally) Program ID.
- **New Color Constants for Styling:**
  - Defined constants like `dialogBackgroundColor`, `buttonSaveColor`, `pageBackgroundColor`, `headerBackgroundColorForCard`, `iconColorForCard`, `primaryTextColor`, `secondaryTextColor`, `labelTextColor`, `editIconColor` to maintain design consistency with admin profile.

### 🛠️ Changed
- **`saveUsername()` in `UserProfileController`:**
  - Refactored to be invoked from `promptEditUsernameDialog()` after validation.
  - After Firestore update, it calls `_loadUserProfile()` to sync state with the server.

- **`_loadUserProfile()` Enhancement:**
  - Now sets the initial value of `usernameController.text` during profile load and also refreshes it just before displaying the edit dialog.

- **User Profile Display (`UserProfileScreen`):**
  - Switched from inline username editing via `_buildEditableInfoCard` to a dialog-based approach.
  - Updated username and role UI elements to use `_buildInfoCard_AdminStyle()` for consistent styling.
  - Displayed additional info ("ID Program Terkait") if available.

- **Page Layout and Loading State:**
  - Scaffold's `backgroundColor` updated to use `pageBackgroundColor`.
  - Wrapped main content with `Obx` to globally show `CircularProgressIndicator` based on `controller.isLoading` and `controller.userProfile`, ensuring a consistent loading experience similar to `AdminProfilePage`.

### 🐛 Fixed
- **Inconsistent Username Display:** Ensured `usernameController.text` is always synced with the actual stored username.
- **Loading State Glitch on Profile Screen:** Unified loading behavior across user and admin profile screens to avoid flickering or partial renders.
- **Removed Legacy Code:** Deleted `_buildEditableInfoCard` as it was replaced by dialog-based editing for better UX.

---

## [0.18.0] - 2025-05-28
> Created by [Bayu Ardiyansyah]

> Implemented Cascading Dropdowns and Enhanced Validation for User Form Input Screen

### 🎉 Added
-   **Cascading Dropdown Functionality (`InputUserScreen`, `InputUserController`):**
  -   Implemented logic in `InputUserScreen` for `QuestionType.dropdown` to dynamically filter and display options based on the selected value of a designated parent question, according to `dependentOptions` mapping defined in the form structure.
  -   Added `_resetDependentChildrenAnswers` method in `InputUserController` to clear/reset child dropdown answers when the parent question's selection changes, ensuring data integrity.
-   **Client-Side Validation Feedback (`InputUserScreen`):**
  -   Integrated `validator` functions with `TextFormField` (for text, paragraph, number, date), `DropdownButtonFormField`, and `FormField<List<String>>` (for checkboxes) to provide immediate input validation feedback to the user.
  -   Utilized `autovalidateMode.onUserInteraction` for a responsive validation experience.
  -   Wrapped form content in `InputUserScreen` with a `Form` widget and associated it with `controller.formKey`.

### 🛠️ Changed
-   **`InputUserController._initializeStates()`:**
  -   Improved state initialization to ensure all answer slots for various question types (including `checkboxes`, `dropdown`, `gridNumeric`) and for new instances in repeatable groups are consistently set with appropriate default values (e.g., `''`, `null`, `[]`, `{}`), preventing potential null errors and `setState called during build` issues in the UI.
-   **`InputUserController.updateUserAnswer()`:**
  -   Refined logic to call `_resetDependentChildrenAnswers` only when a parent question's value actually changes, to correctly update dependent child dropdowns.
  -   Adjusted how numeric answers from `isRepeatableGroupController` questions are stored back into `userAnswers` (as String) for consistency with `TextFormField`.
-   **`InputUserController.submitForm()`:**
  -   Now triggers `formKey.currentState!.validate()` first for built-in `TextFormField` validations.
  -   Enhanced the `_performLocalValidation` helper method (now a class method) to more robustly handle `ValidationRule?` (nullable rule object from `FormQuestion.validation`) and safely access its properties (`rule?.minLength`, etc.).
  -   Clarified NIK validation within `_performLocalValidation` to be triggered by `rule.predefinedRule == 'nik'` on a text field.
  -   Maintained example placeholder for hardcoded cross-question validation (e.g., "Q203 <= Q112") as the model `ValidationRule` does not yet support defining this dynamically.
-   **`InputUserScreen._buildQuestionInput()`:**
  -   Significantly refactored `case QuestionType.dropdown:` to implement the cascading logic, dynamically building `items` based on parent selection and `dependentOptions`.
  -   Removed direct default value assignments for Rx variables from within the build method; now relies entirely on controller's initialization logic in `_initializeStates` and `_adjustRepeatableGroupAnswers`.
  -   Ensured `ValueKey`s are consistently applied for input field widgets for better state management.
-   **`InputUserScreen._buildQuestionsForSection()`:**
  -   Maintained `Obx` wrapper for individual questions for reactive visibility and rendering of repeatable groups.
  -   Improved keying for elements within `List.generate` for repeatable groups.

### 🐛 Fixed
-   **Cascading Dropdown Not Filtering Options:** Resolved the primary issue where child dropdowns in `InputUserScreen` displayed all master options instead of contextually filtered options based on the parent question's selection.
-   **Potential `setState called during build` errors in `InputUserScreen`:** Addressed by centralizing answer slot initialization in `InputUserController` and ensuring `_buildQuestionInput` is primarily for reading and rendering state.
-   **Null Safety Issues in `InputUserController._performLocalValidation`:** Correctly handled nullable `ValidationRule` object and its properties.
-   **`DropdownButtonFormField` errors:** Addressed `items` and `onChanged` requirements and ensured `value` is valid within the current set of displayable items for dropdowns, especially dependent ones.

---

## [0.17.6] - 2025-05-28
> Created by [Febri Bagus Triwibowo]  
> Improved login feedback handling and enhanced visual consistency on splash screen.

### 🎉 Added
- *(No new features added in this release)*

### 🛠️ Changed
- **Splash Screen (`splash_screen.dart`):**
  - Updated background color to better align with the app's branding and visual identity.

### 🐛 Fixed
- **Login Controller (`login_controller.dart`):**
  - Refined `Snackbar` feedback logic to handle multiple login conditions more accurately, providing clearer messages for failed logins, empty fields, and invalid credentials.

---

## [0.17.5] - 2025-05-28
> Created by [Lutfi Indra]
> Improved UI clarity for admin account management, enhanced user data synchronization, and fixed user display name retrieval.

### 🎉 Added
- *(No new features added in this release)*

### 🛠️ Changed
- **Admin Account Page (`admin_account_page.dart`):**
  - Optimized UI layout to visually distinguish this page as the top-level authority form, making it stand out from other forms.
- **User Screen (`user_screen.dart`):**
  - Implemented auto-refresh behavior to ensure real-time updates when user profile information changes.
- **User Profile Model & Controller (`user_profile_model.dart`, `user_profile_controller.dart`):**
  - Updated user role field to use a static assignment for consistency and simplicity in account management logic.

### 🐛 Fixed
- **User Screen (`user_screen.dart`):**
  - Corrected the fetch logic for displaying the user's display name; it now retrieves and displays the correct data reliably.

---

## [0.17.0] - 2025-05-28
> Created by [Bayu Ardiyansyah]
> Improved Admin Dashboard Date Range Picker with Custom Pop-up Calendar and Resolved Related Issues

### 🎉 Added
-   **Custom Pop-up Date Range Picker (`AdminScreen`):** Implemented a new custom dialog utilizing `TableCalendar` for selecting date ranges on the Admin Dashboard. This provides a more compact, pop-up style picker instead of the default full-screen behavior on mobile devices.
-   **State Management for Custom Calendar Dialog (`AdminController`):** Added new Rx variables (`focusedCalendarDay`, `calendarRangeStart`, `calendarRangeEnd`, `calendarRangeSelectionMode`) to manage the state of the `TableCalendar` within the custom dialog.
-   **New Method for Custom Dialog (`AdminController`):** Introduced `openCustomDateRangePicker` method to launch the new `TableCalendar`-based pop-up dialog for date selection.

### 🛠️ Changed
-   **Admin Dashboard Date Filter UI (`AdminScreen`):** Modified the `_buildDateFilterSection` to trigger the new `openCustomDateRangePicker` method, replacing the direct call to `showDateRangePicker` or an embedded `TableCalendar` for a consistent pop-up experience.
-   **Date Selection Logic Synchronization (`AdminController`):** Ensured that date selections from the new custom dialog correctly update the primary `selectedStartDate` and `selectedEndDate` observables, which in turn trigger the dashboard data filters via existing `ever` listeners. The original `pickDateRangeWithDefaultDialog` (using `showDateRangePicker`) was also updated to sync with `TableCalendar` state variables if used.

### 🐛 Fixed
-   **`isSameDay` Undefined Error (`AdminScreen`):** Ensured the `table_calendar` package is correctly imported in `AdminScreen.dart` so that utility functions like `isSameDay` are properly resolved and functional.
-   **Full-Screen Date Picker Behavior on Mobile:** Addressed user feedback regarding the default `showDateRangePicker` appearing full-screen on mobile by providing the custom pop-up `TableCalendar` dialog as the primary date range selection mechanism.
-   **Controller Method Naming for Clarity:** Renamed the controller method for the default date picker dialog to `pickDateRangeWithDefaultDialog` and ensured UI calls the appropriate method for the desired picker type (default or custom pop-up). *(Catatan: Pada interaksi terakhir, kita kembali ke `pickDateRange` untuk default dialog dan membuat `openCustomDateRangePicker` untuk yang baru. Pastikan nama metode konsisten dengan implementasi Anda).*
-   **Error `_CustomDateRangePickerDialog` Undefined:** Resolved by defining the `_CustomDateRangePickerDialog` widget within `AdminScreen.dart` (atau memastikan impor yang benar jika di file terpisah) so it can be instantiated by `AdminController`'s `openCustomDateRangePicker` method via `Get.dialog()`.

---

## [0.16.0] - 2025-05-28
> Created by [Bayu Ardiyansyah]

> Added Dynamic Grid Numeric Question Type to Admin Form Builder and Fixed Critical Text Input Issues.

### 🎉 Added
-   **Admin Form Builder: New "Grid Numeric" Question Type:**
  -   Introduced a new `gridNumeric` question type, enabling administrators to create complex matrix or grid-style questions (e.g., for daily waste volume tracking across multiple categories like "Wet/Dry" and "Small/Medium/Large").
  -   Admins can dynamically define labels for rows (optional), main columns (e.g., days of the week), and sub-columns (e.g., sizes) for each grid question.
-   **Admin Form Builder: Configuration UI for Grid Numeric Questions:**
  -   Implemented a dedicated settings section (`_buildGridNumericSettings`) within the question card for the "Grid Numeric" type.
  -   Administrators can input comma-separated values for row, column, and sub-column labels via text fields.

### 🛠️ Changed
-   **`admin_form_model.dart` (`FormQuestion`):**
  -   Extended the `FormQuestion` model to include `gridRowLabels`, `gridColumnLabels`, and `gridSubColumnLabels` (all `List<String>`) to store the structure of the new grid question type.
  -   Updated the constructor, `fromMap`, `toMap`, and `copyWith` methods to correctly initialize, serialize, deserialize, and manage these new grid-related properties.
-   **`AdminFormBuilderController.dart`:**
  -   Enhanced to support the creation and dynamic updating of "Grid Numeric" questions.
  -   Added new methods (`updateGridRowLabelsFromString`, `updateGridColumnLabelsFromString`, `updateGridSubColumnLabelsFromString`) to parse comma-separated label inputs from the UI and update the `FormQuestion` model.
  -   When a new "Grid Numeric" question is added, it's now initialized with default labels (e.g., "Senin-Minggu" for columns, "Kecil,Sedang,Besar" for sub-columns) to guide the admin.
-   **`AdminFormBuilderPage.dart`:**
  -   The "Add Question" bottom sheet now includes "Grid Numerik" as a selectable question type.
  -   The question card UI (`_buildQuestionCard`) now conditionally renders the new `_buildGridNumericSettings` widget for configuring grid labels if the question type is `gridNumeric`.

### 🐛 Fixed
-   **Admin Form Builder: Text Input Fields Losing Focus:**
  -   Resolved a critical usability issue where typing into various `TextField`s (e.g., for section titles/descriptions, question codes/texts, option texts, grid labels, and validation rule inputs) was interrupted after each character, requiring users to re-click.
  -   This was fixed by implementing and utilizing a `_PersistentTextField` stateful helper widget that correctly manages `TextEditingController` lifecycle and state across rebuilds.
-   **Admin Form Builder: Form Saving Error "Null is not a subtype of type List<String>":**
  -   Improved the robustness of `FormQuestion.toMap()` and `FormQuestion.copyWith()` methods by adding defensive fallbacks (`?? []`) for all `List<String>` properties (like `options`, `gridRowLabels`, etc.). This prevents errors during form saving if any of these list properties inadvertently become `null` at runtime.

---

## [0.15.0] - 2025-05-27
> Created by [Bayu Ardiyansyah]

> Introduced List Submissions Screen with Enhanced Data Display, Search, Sort, and Delete Capabilities; Refined User Input Form Workflow.

### 🎉 Added
-   **New Feature: List Submissions Screen (`ListSubmissionFormScreen`, `ListSubmissionFormController`, `ListSubmissionFormBinding`):**
  -   Users are now directed to this screen after selecting a form type from the main user screen.
  -   Displays a list of previously submitted entries for the selected form, specific to the logged-in user.
  -   Includes a prominent "Create New Entry" button that navigates to the `InputUserScreen`.
-   **Submission Identifier Display:** Submissions in the list now display key identifiers (e.g., Name, NIK/KK) extracted from the actual submitted form data, rather than just the submitter's username. Prioritized codes for extraction include "NAMA_LENGKAP", "NAMA_KEPALA_KELUARGA", "NIK", "NO_KK".
-   **Search Functionality for Submissions:** Added a search bar on the `ListSubmissionFormScreen` to filter submissions based on the extracted display identifier (case-insensitive).
-   **Sorting Functionality for Submissions:** Implemented options to sort submissions by "Latest", "Oldest", "Identifier A-Z", and "Identifier Z-A".
-   **Delete Functionality for Submissions:** Added a "Delete" button for each submission item, including a confirmation dialog, allowing users to remove their own entries.
-   **Refresh Capability:** Added pull-to-refresh functionality on the `ListSubmissionFormScreen` to reload form structure and submission list.

### 🛠️ Changed
-   **Navigation Flow:** Tapping a form card on the `UserScreen` now navigates to the new `ListSubmissionFormScreen` (showing existing submissions for that form) instead of directly to the `InputUserScreen` (for new entry).
-   **`ListSubmissionFormController`:**
  -   Refactored to fetch and manage both the selected form's structure (`FormItem`) and its associated submissions (`FormSubmission`).
  -   Introduced a `DisplayableSubmission` helper class to hold the original submission and its extracted/formatted display identifiers for easier UI rendering, searching, and sorting.
  -   Search and sort logic now operates on these extracted, case-insensitive identifiers.
-   **`ListSubmissionFormScreen` UI:**
  -   Significantly redesigned to closely match the provided UI mock-up (`gambar.png`).
  -   Features a new header section with an integrated search bar and a gradient background.
  -   Includes a "Riwayat Pendataan" (Submission History) title and a sort order dropdown.
  -   Submission items are displayed as cards with primary identifier text, submission date, and "Edit" (placeholder) / "Delete" buttons.
  -   A full-width "Buat Pendataan Baru" (Create New Entry) button is fixed at the bottom of the screen.
-   **`InputUserController` & `InputUserScreen`:**
  -   Resolved an error related to `DropdownButtonFormField` value assignment.
  -   Improved null-safety for accessing `question.validation` properties within `InputUserController`.
  -   Refined form state initialization (`_initializeStates` in `InputUserController`) for better reset behavior, especially for checkboxes and dropdowns, to support multiple submissions within the same session.
  -   Snackbar notification for successful form submission is now consistently displayed, and the form is reset for a new entry instead of navigating back.
-   **Date Formatting:** Consistently used `intl` package for date formatting (`dd MMM yy, HH:mm` with 'id_ID' locale) on the `ListSubmissionFormScreen`.

### 🐛 Fixed
-   **(Underlying) Potential for `DropdownButtonFormField` value type error in `InputUserScreen`:** Corrected logic for setting the `value` property to ensure it's a valid `String?` from the available options.
-   **(Underlying) Potential for null access when handling `question.validation` in `InputUserController`:** Improved safe access patterns.

---

## [0.14.1] - 2025-05-27
> Created by [Bayu Ardiyansyah]
> 
> Improved Admin Form Builder Usability and Controller Optimizations.

### 🎉 Added
-   **Admin Form Builder:** Added a modern and elegant confirmation dialog ('Yes/No') before saving a form to prevent accidental saves.

### 🛠️ Changed
-   **Admin Form Builder:** Form sections (`ExpansionTile`) on the builder page are now initially collapsed by default for a cleaner and tidier initial view.
-   **Admin Form Builder:** Optimized the `getAvailableControlledGroupTags` method in `AdminFormBuilderController` for improved efficiency in fetching available group tags.

---
## [0.14.0] - 2025-05-27
> Created by [Bayu Ardiyansyah]

> Enhanced Form Authorization, User Display Logic, and Fixed Landing Page UI

### 🎉 Added
-   **Dynamic Form Authorization via `managedAccounts`:** `UserController` now actively checks Firestore `adminForms/{formId}/managedAccounts/{userId}` to determine form access for users without global `hasAuthority`, enabling granular form permissions.
-   **Firebase Auth Integration in `UserController`:** `UserController` now directly utilizes `FirebaseAuth.instance` to get current user details (UID for `managedAccounts` check, `displayName`/`email` for default user naming).
-   **Enhanced Debugging Logs in `UserController`:** Incorporated detailed logging for argument processing in `onInit` and throughout the `WorkspaceFormData` lifecycle to significantly improve troubleshooting capabilities.

### 🛠️ Changed
-   **Refactored `UserController.fetchFormData()` Logic:**
  -   Supports two main authorization paths: global admins (argument `hasAuthority: true`) fetching all forms defined in `adminForms`, and regular users fetching forms based on their specific permissions in `managedAccounts`.
  -   Form data for authorized users is now directly sourced from `adminForms/{formId}` documents.
-   **Adapted `FormDataModel.fromMap()`:** Modified the factory constructor to correctly parse data fields from `adminForms` documents (e.g., mapping Firestore `title` field to `nama` in model) and to use the Firestore document ID as `idForm`.
-   **Improved `UserScreen` Display Logic:**
  -   Refined conditional rendering in `Obx` widget to prioritize displaying the list of forms if `sortedFormDataList` is populated (either via global admin access or `managedAccounts` authorization).
  -   Updated conditions for showing `_buildNoDataMessage()` versus `_buildNoAuthorityMessage()` to more accurately reflect data availability and user login status.
-   **Robust Argument Handling in `UserController.onInit()`:** Enhanced `onInit` to gracefully manage scenarios where `Get.arguments` might be `null` or not a `Map`, defaulting `userHasAuthority` to `false` which then correctly triggers the `managedAccounts` authorization check.
-   **Landing Page `BottomArcClipper` Logic:** Adjusted the `BottomArcClipper` and internal padding/spacing within the top clipped section of the Landing Page for a more refined curve and content placement.

### 🐛 Fixed
-   **User Form List Not Displaying for Specifically Authorized Users:** Resolved the critical issue where users with specific form permissions (via `managedAccounts`) could not see their assigned forms. This was addressed by implementing the new `managedAccounts` authorization logic in `UserController` and correcting UI display conditions in `UserScreen`.
-   **Misleading "Akses Terbatas" Message:** Corrected the scenario where "Akses Terbatas" was shown even if forms were successfully fetched (e.g., via `managedAccounts` but `hasAuthority` argument was `false` or not received), by adjusting the UI rendering priorities in `UserScreen`.
-   **Landing Page Bottom Overflow:** Addressed and resolved the "Bottom Overflowed" issue on the `LandingPageScreen` by adjusting vertical paddings, `SizedBox` heights, image scaling within the top section, and refining the layout (including `Spacer` usage and `MainAxisAlignment`) of elements in the lower section containing the "START" button.
-   **(Underlying) Argument Reception Issue in `UserController`:** While the root cause of arguments not being passed via `Get.toNamed` still requires user investigation on the calling side, `UserController` now more gracefully defaults to a state that triggers `managedAccounts` checks, making it more resilient to missing arguments.
---

## [0.13.1] - 2025-05-27
> Created by [Lutfi Indra]

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
> Created by [Bayu Ardiyansyah]

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
> Created by [Bayu Ardiyansyah]

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
> Created by [Bayu Ardiyansyah]

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
> Created by [Bayu Ardiyansyah]

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
> Created by [Bayu Ardiyansyah]

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
> Created by [Bayu Ardiyansyah]

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
> Created by [Bayu Ardiyansyah]

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
> Created by [Bayu Ardiyansyah]

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
> Created by [Bayu Ardiyansyah]

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
> Created by [Bayu Ardiyansyah]

### 🛠️ Changed
- **LoginScreen UI/UX Enhancements:**
  - Modified `pageBackgroundColor` to a pure light blue shade (`0xFFF2FAFF`) by removing opacity, providing a cleaner, almost white background.
  - Adjusted `AppBar` leading icon (back arrow) color from `primaryTextColor` (white) to `Colors.black54` for improved visibility and contrast against the new light background.
  - Updated primary text color for the title (`Silakan isi Username dan Password Terlebih Dahulu`) from `primaryTextColor` (white) to `Colors.black87` to ensure clear readability on the light background.

---

## [0.3.0] - 2025-05-21
> Created by [Bayu Ardiyansyah]

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
> Created by [Bayu Ardiyansyah]

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
> Created by [Bayu Ardiyansyah]

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