// lib/presentation/admin/admin_controller.dart

import 'package:get/get.dart';
import 'package:aplikasi_pendataan_desa/presentation/login/login_controller.dart';

class AdminController extends GetxController {
  // Akses LoginController untuk fungsi logout dan data user jika perlu
  final LoginController _loginController = Get.find<LoginController>();

  String? get userEmail => _loginController.loggedInUser.value?.email;
  String? get userRole => _loginController.loggedInUser.value?.role;

  void logout() {
    _loginController.logout();
  }
}
