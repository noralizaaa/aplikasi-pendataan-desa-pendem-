// lib/routes/app_routes.dart (atau path yang sesuai di proyek Anda)

import 'package:aplikasi_pendataan_desa/presentation/LandingPage/LandingPage_controller.dart';
import 'package:aplikasi_pendataan_desa/presentation/LandingPage/LandingPage.dart'; // Pastikan ini LandingPageScreen/View
import 'package:aplikasi_pendataan_desa/presentation/login/login_screen.dart'; // Impor LoginScreen/View
import 'package:aplikasi_pendataan_desa/presentation/login/login_controller.dart'; // Impor LoginController
import 'package:aplikasi_pendataan_desa/presentation/splash/splash_screen.dart';
import 'package:aplikasi_pendataan_desa/presentation/user/user_controller.dart';
import 'package:aplikasi_pendataan_desa/presentation/user/user_screen.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/admin_screen.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/admin_controller.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../presentation/splash/splash_controller.dart';

// Jika Anda memiliki splash_binding.dart dan controllers_bindings.dart, pastikan path-nya benar
// import 'bindings/splash_binding.dart'; // Contoh path, sesuaikan
// import 'bindings/controllers/controllers_bindings.dart'; // Contoh path, sesuaikan

// Definisikan LoginBinding jika belum ada
class LoginBinding extends Bindings {
  @override
  void dependencies() {
    // PASTIKAN INI ADA DAN permanent: true
    Get.put<LoginController>(LoginController(), permanent: true);
  }
}

// Definisikan LandingPageBinding jika belum ada (alternatif dari BindingsBuilder)
class LandingPageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LandingPageController>(() => LandingPageController());
  }
}

// Definisikan SplashBinding jika belum ada
class SplashBinding extends Bindings {
  @override
  void dependencies() {
    // Jika Splash Screen memiliki controller, daftarkan di sini
    Get.lazyPut<SplashController>(() => SplashController());
    // Jika tidak ada controller khusus untuk splash, bisa dibiarkan kosong atau tidak perlu binding khusus.
    // Namun, jika ada logika inisialisasi yang terjadi di splash, controller mungkin berguna.
  }
}

// Definisikan AdminBinding << BARU DITAMBAHKAN
class AdminBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminController>(() => AdminController());
    // LoginController sudah di-put secara permanen oleh LoginBinding,
    // jadi AdminController bisa menggunakan Get.find<LoginController>() jika perlu.
  }
}

// Definisikan UserBinding << BARU DITAMBAHKAN
class UserBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UserController>(() => UserController());
    // LoginController sudah di-put secara permanen oleh LoginBinding,
    // jadi UserController bisa menggunakan Get.find<LoginController>() jika perlu.
  }
}


enum Environments { DEVELOPMENT, QAS, PRODUCTION }

class ConfigEnvironments {
  static Map<String, String> getEnvironments() {
    // Sesuaikan dengan config.dart Anda atau cara Anda mengatur environment
    // Untuk contoh ini, kita hardcode ke DEVELOPMENT
    return {'env': Environments.DEVELOPMENT.name};
  }
}

class EnvironmentsBadge extends StatelessWidget {
  final Widget child;
  const EnvironmentsBadge({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    var env = ConfigEnvironments.getEnvironments()['env'];
    // Pastikan env tidak null sebelum digunakan
    if (env == null) {
      return SizedBox(child: child); // Atau tampilkan error/default behavior
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

  // Anda mungkin ingin mengatur initialRoute di GetMaterialApp
  static String initialRoute = splash; // Atau login jika tidak ada splash yang kompleks

  static List<GetPage> routes = [
    GetPage(
      name: splash,
      page: () => const SplashScreen(),
      binding: SplashBinding(), // Gunakan SplashBinding jika ada
    ),
    GetPage(
      name: login, // Gunakan konstanta
      page: () => const LoginScreen(),
      binding: LoginBinding(), // Buat LoginBinding
    ),
    GetPage(
      name: landingPage, // Gunakan konstanta
      page: () => const LandingPageScreen(), // Pastikan nama class view-nya benar
      binding: LandingPageBinding(), // Gunakan LandingPageBinding
      // Alternatif menggunakan BindingsBuilder:
      // binding: BindingsBuilder(() {
      //   Get.lazyPut<LandingPageController>(() => LandingPageController());
      // }),
    ),
    GetPage(
      name: adminPage, // Rute baru
      page: () => const AdminScreen(),
      binding: AdminBinding(), // Binding baru
    ),
    GetPage(
      name: userPage,   // Rute baru
      page: () => const UserScreen(),
      binding: UserBinding(),   // Binding baru
    ),
  ];
}