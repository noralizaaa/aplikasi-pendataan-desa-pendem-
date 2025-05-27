// lib/routes/app_routes.dart

import 'package:aplikasi_pendataan_desa/presentation/LandingPage/LandingPage_controller.dart';
import 'package:aplikasi_pendataan_desa/presentation/LandingPage/LandingPage.dart';
import 'package:aplikasi_pendataan_desa/presentation/login/login_screen.dart';
import 'package:aplikasi_pendataan_desa/presentation/login/login_controller.dart';
import 'package:aplikasi_pendataan_desa/presentation/splash/splash_screen.dart';
import 'package:aplikasi_pendataan_desa/presentation/user/InputFormUser/Input_User_Screen.dart';
import 'package:aplikasi_pendataan_desa/presentation/user/InputFormUser/input_user_controller.dart';
import 'package:aplikasi_pendataan_desa/presentation/user/ListSubmissionForm/list_submission_form_controller.dart';
import 'package:aplikasi_pendataan_desa/presentation/user/ListSubmissionForm/list_submission_form_screen.dart';
import 'package:aplikasi_pendataan_desa/presentation/user/user_controller.dart';
import 'package:aplikasi_pendataan_desa/presentation/user/user_screen.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/admin_screen.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/admin_controller.dart';
import 'package:aplikasi_pendataan_desa/presentation/user/user_profile/user_profile_screen.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Import untuk Controller
import '../../presentation/admin/Admin_Profile/admin_account_controller.dart';
import '../../presentation/admin/Admin_Profile/form_account_management_controller.dart';
import '../../presentation/admin/formpage/admin_form_controller.dart';
import '../../presentation/admin/formpage/form_builder/admin_form_builder_controller.dart';
import '../../presentation/admin/profil/admin_profil_controller.dart';
import '../../presentation/splash/splash_controller.dart';
// --- NEW IMPORT: AllAccountController ---
import '../../presentation/admin/Admin_Profile/all_account_controller.dart';

// Import untuk Page
import '../../presentation/admin/Admin_Profile/admin_account_page.dart';
import '../../presentation/admin/Admin_Profile/form_account_management_page.dart';
import '../../presentation/admin/formpage/form_builder/admin_form_builder_page.dart';
import '../../presentation/admin/profil/admin_profil_page.dart';
// --- NEW IMPORT: AllAccountPage ---
import '../../presentation/admin/Admin_Profile/all_account_page.dart';


// Definisikan LoginBinding
class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<LoginController>(LoginController(), permanent: true);
  }
}

// Definisikan LandingPageBinding
class LandingPageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LandingPageController>(() => LandingPageController());
  }
}

// Definisikan SplashBinding
class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SplashController>(() => SplashController());
  }
}

// Definisikan AdminBinding
class AdminBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminController>(() => AdminController());
    Get.lazyPut<AdminAccountController>(() => AdminAccountController()); // Untuk tab Account di AdminScreen
    Get.lazyPut<AdminFormController>(() => AdminFormController());    // Untuk tab Form di AdminScreen
  }
}

// Definisikan AdminAccountBinding (untuk route '/admin-account' jika diakses terpisah)
class AdminAccountBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminAccountController>(() => AdminAccountController());
  }
}

class AdminFormBuilderBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminFormBuilderController>(() => AdminFormBuilderController());
  }
}

// Definisikan AdminProfilBinding untuk halaman profil admin yang diakses dari header
class AdminProfilBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminProfilController>(() => AdminProfilController());
  }
}

// Definisikan UserBinding
class UserBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UserController>(() => UserController());
  }
}

// Definisikan UserProfileBinding
class UserProfileBinding extends Bindings {
  @override
  void dependencies() {
    // Jika UserProfileScreen membutuhkan controller, daftarkan di sini.
    // Contoh: Get.lazyPut<UserProfileController>(() => UserProfileController());
  }
}

// Definisikan FormAccountManagementBinding
class FormAccountManagementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FormAccountManagementController>(
          () => FormAccountManagementController(),
    );
  }
}

// --- NEW BINDING: AllAccountBinding ---
class AllAccountBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AllAccountController>(
          () => AllAccountController(),
    );
  }
}

class InputUserBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InputUserController>(
          () => InputUserController(),
    );
  }
}

class ListSubmissionFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ListSubmissionFormController>(
          () => ListSubmissionFormController(),
    );
  }
}

// --- END NEW BINDING ---

// Enum untuk lingkungan (opsional, tapi baik untuk konfigurasi)
enum Environments { DEVELOPMENT, QAS, PRODUCTION }

class ConfigEnvironments {
  static Map<String, String> getEnvironments() {
    return {'env': Environments.DEVELOPMENT.name};
  }
}

// Widget badge untuk lingkungan (opsional)
class EnvironmentsBadge extends StatelessWidget {
  final Widget child;
  const EnvironmentsBadge({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    var env = ConfigEnvironments.getEnvironments()['env'];
    if (env == null || env == Environments.PRODUCTION.name) {
      return SizedBox(child: child);
    }
    return Banner(
      location: BannerLocation.topStart,
      message: env,
      color: env == Environments.QAS.name ? Colors.blue : Colors.purple,
      child: child,
    );
  }
}

// Definisi nama rute dan halaman
class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String landingPage = '/landing-page';
  static const String adminPage = '/admin-page'; // AdminScreen (dengan tabs)
  static const String userPage = '/user-page';
  static const String userProfile = '/user-profile';
  static const String adminProfil = '/admin-profil'; // Halaman profil admin (dari header)
  static const String adminFormBuilder = '/admin-form-builder';
  // static const String adminProfile = '/admin_profile'; // Removed: Redundant with adminAccount
  static const String userList = '/user_list';
  static const String userDataInput = '/user_data_input';
  static const String userDataDetail = '/user_data_detail';

  // New Routes
  static const String adminAccount = '/admin-account'; // Standalone Admin Account Page / Kategori Manajemen Akun
  static const String formAccountManagement = '/form-account-management'; // Page for managing accounts of a specific form
  static const String allAccountManagement = '/all_account_management'; // --- NEW ROUTE ---
  static const INPUT_FORM_USER = '/input-form-user';
  static const LIST_SUBMISSION_FORM = '/list-submission-form';
  static String initialRoute = splash;

  static List<GetPage> routes = [
    GetPage(
      name: splash,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: login,
      page: () => const LoginScreen(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: landingPage,
      page: () => const LandingPageScreen(),
      binding: LandingPageBinding(),
    ),
    GetPage(
      name: adminPage, // Rute untuk AdminScreen yang berisi tab-tab (Dashboard, Form, Account)
      page: () => const AdminScreen(),
      binding: AdminBinding(), // AdminBinding mendaftarkan AdminController, AdminFormController, dan AdminAccountController
    ),
    GetPage(
      name: userPage,
      page: () => const UserScreen(),
      binding: UserBinding(),
    ),
    GetPage(
      name: userProfile,
      page: () => const UserProfileScreen(),
      binding: UserProfileBinding(),
    ),
    GetPage(
      name: adminProfil, // Rute untuk halaman profil admin yang diakses dari header
      page: () => const AdminProfilPage(),
      binding: AdminProfilBinding(),
    ),
    GetPage(
      name: adminFormBuilder,
      page: () => const AdminFormBuilderPage(),
      binding: AdminFormBuilderBinding(),
    ),
    GetPage(
      name: AppRoutes.adminAccount, // Route for the "Kategori Manajemen Akun" page (AdminAccountPage)
      page: () => const AdminAccountPage(),
      binding: AdminAccountBinding(), // Binding for AdminAccountController if accessed directly
    ),
    GetPage(
      name: AppRoutes.formAccountManagement, // Route for managing accounts for a specific form
      page: () => const FormAccountManagementPage(),
      binding: FormAccountManagementBinding(),
    ),
    // --- NEW GETPAGE ENTRY: AllAccountManagement ---
    GetPage(
      name: AppRoutes.allAccountManagement,
      page: () => const AllAccountPage(),
      binding: AllAccountBinding(),
    ),
    GetPage(
      name: AppRoutes.INPUT_FORM_USER,
      page: () => const InputUserScreen(),
      binding: InputUserBinding(),
    ),
    GetPage( // <-- TAMBAHKAN BLOK INI
    name: AppRoutes.LIST_SUBMISSION_FORM,
    page: () => const ListSubmissionFormScreen(),
    binding: ListSubmissionFormBinding(),
    )
    // --- END NEW GETPAGE ENTRY ---
  ];
}