// lib/routes/app_routes.dart

import 'package:aplikasi_pendataan_desa/presentation/LandingPage/LandingPage_controller.dart';
import 'package:aplikasi_pendataan_desa/presentation/LandingPage/LandingPage.dart';
import 'package:aplikasi_pendataan_desa/presentation/login/login_screen.dart';
import 'package:aplikasi_pendataan_desa/presentation/login/login_controller.dart';
import 'package:aplikasi_pendataan_desa/presentation/splash/splash_screen.dart';
import 'package:aplikasi_pendataan_desa/presentation/user/user_controller.dart';
import 'package:aplikasi_pendataan_desa/presentation/user/user_screen.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/admin_screen.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/admin_controller.dart';
import 'package:aplikasi_pendataan_desa/presentation/user/user_profile/user_profile_screen.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../presentation/splash/splash_controller.dart';

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
  }
}

// Definisikan UserBinding
class UserBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UserController>(() => UserController());
  }
}

// Definisikan UserProfileBinding (optional, but good practice if UserProfileScreen gets a controller later)
class UserProfileBinding extends Bindings { // <-- NEW: UserProfileBinding
  @override
  void dependencies() {
    // If UserProfileScreen needs a controller, register it here
    // Get.lazyPut<UserProfileController>(() => UserProfileController());
  }
}


enum Environments { DEVELOPMENT, QAS, PRODUCTION }

class ConfigEnvironments {
  static Map<String, String> getEnvironments() {
    return {'env': Environments.DEVELOPMENT.name};
  }
}

class EnvironmentsBadge extends StatelessWidget {
  final Widget child;
  const EnvironmentsBadge({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    var env = ConfigEnvironments.getEnvironments()['env'];
    if (env == null) {
      return SizedBox(child: child);
    }
    return env != Environments.PRODUCTION.name
        ? Banner(
      location: BannerLocation.topStart,
      message: env,
      color: env == Environments.QAS.name ? Colors.blue : Colors.purple,
      child: child,
    )
        : SizedBox(child: child);
  }
}

class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String landingPage = '/landing-page';
  static const String adminPage = '/admin-page';
  static const String userPage = '/user-page';
  static const String userProfile = '/user-profile'; // <-- NEW: User Profile Route

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
      name: adminPage,
      page: () => const AdminScreen(),
      binding: AdminBinding(),
    ),
    GetPage(
      name: userPage,
      page: () => const UserScreen(),
      binding: UserBinding(),
    ),
    GetPage( // <-- NEW: User Profile GetPage
      name: userProfile,
      page: () => const UserProfileScreen(),
      binding: UserProfileBinding(), // Optional: add a binding if UserProfileScreen has a controller
    ),
  ];
}