# Implementation Plan - Add `admindesa` Role

This plan outlines the steps to add a new role called `admindesa` to the application. This role will have restricted permissions, allowing it to manage (create, view, edit, download) data ONLY for their own village (desa).

## Proposed Changes

### Domain Layer (Models)

#### [auth_user.dart](file:///C:/Users/ADMIN/Downloads/aplikasi_pendataan_desa%20(3)/aplikasi_pendataan_desa/lib/domain/auth/models/auth_user.dart)
- Add `villageId` and `villageName` fields to the `AuthUser` class.
- Update `copyWith` method.

#### [input_user_model.dart](file:///C:/Users/ADMIN/Downloads/aplikasi_pendataan_desa%20(3)/aplikasi_pendataan_desa/lib/presentation/user/InputFormUser/input_user_model.dart)
- Add `villageId` and `villageName` fields to the `FormSubmission` class.
- Update `toFirestore()` to include these new fields.
- Update `fromFirestore()` to parse these fields from Firestore.

---

### Infrastructure Layer (Auth & Navigation)

#### [login_controller.dart](file:///C:/Users/ADMIN/Downloads/aplikasi_pendataan_desa%20(3)/aplikasi_pendataan_desa/lib/presentation/login/login_controller.dart)
- Update `_loadAndSetAuthUser` to fetch `villageId` and `villageName` from the Firestore user document and store them in `AuthUser`.
- Update `_navigateToAppropriatePage` to allow users with the `admindesa` role to navigate to `AppRoutes.adminPage`.

#### [splash_controller.dart](file:///C:/Users/ADMIN/Downloads/aplikasi_pendataan_desa%20(3)/aplikasi_pendataan_desa/lib/presentation/splash/splash_controller.dart)
- Update `_checkLoginStatus` to allow users with the `admindesa` role to navigate to `AppRoutes.adminPage`.

---

### Presentation Layer (Admin Features)

#### [input_user_controller.dart](file:///C:/Users/ADMIN/Downloads/aplikasi_pendataan_desa%20(3)/aplikasi_pendataan_desa/lib/presentation/user/InputFormUser/input_user_controller.dart)
- Update `submitForm()` to fetch the current user's `villageId` and `villageName` from Firestore (or a session state) and include them in the `FormSubmission` being saved.

#### [admin_controller.dart](file:///C:/Users/ADMIN/Downloads/aplikasi_pendataan_desa%20(3)/aplikasi_pendataan_desa/lib/presentation/admin/admin_controller.dart)
- Update `onInit` to fetch the current user's role and `villageId`.
- Update `_fetchAllSubmissionsAndGroupThem` to filter submissions by `villageId` if the user's role is `admindesa`.

#### [submissions_form_controller.dart](file:///C:/Users/ADMIN/Downloads/aplikasi_pendataan_desa%20(3)/aplikasi_pendataan_desa/lib/presentation/admin/submissions_form/submissions_form_controller.dart)
- Fetch the current user's role and `villageId`.
- Update `_fetchSubmissions` to filter by `villageId` in the Firestore query if the user's role is `admindesa`.

#### [all_account_controller.dart](file:///C:/Users/ADMIN/Downloads/aplikasi_pendataan_desa%20(3)/aplikasi_pendataan_desa/lib/presentation/admin/Admin_Profile/all_account_controller.dart)
- Fetch the current user's role and `villageId`.
- Update `_listenToAllUsers` to filter the user list by `villageId` if the role is `admindesa`.
- Update `_createSystemUser` to automatically assign the current user's `villageId` and `villageName` to the new user if the creator is an `admindesa`.

#### [admin_account_model.dart](file:///C:/Users/ADMIN/Downloads/aplikasi_pendataan_desa%20(3)/aplikasi_pendataan_desa/lib/presentation/admin/Admin_Profile/admin_account_model.dart)
- Add `villageId` and `villageName` to `AdminAccountModel`.

## Verification Plan

### Automated Tests
- No automated tests currently exist for this specific logic, but I will perform manual verification.

### Manual Verification
1.  **Test Login as `adminGlobal`**: Verify that all data and all accounts are still visible.
2.  **Test Login as `admindesa`**:
    - Assign the `admindesa` role and a `villageId` (e.g., 'village_123') to a test user in Firestore.
    - Log in and verify navigation to `adminPage`.
    - Verify that the Dashboard only shows statistics for 'village_123'.
    - Verify that the Submissions list only shows data from 'village_123'.
    - Verify that "Daftar Semua Akun" only shows users belonging to 'village_123'.
    - Create a new user as `admindesa` and verify they are automatically assigned to 'village_123'.
3.  **Test Submission**:
    - Submit a form as a regular user belonging to 'village_123'.
    - Verify that the `FormSubmission` document in Firestore now contains the correct `villageId`.
