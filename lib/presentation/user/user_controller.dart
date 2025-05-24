// lib/presentation/user/user_controller.dart

import 'package:get/get.dart';
import 'package:aplikasi_pendataan_desa/presentation/login/login_controller.dart'; // Sesuaikan path

class UserController extends GetxController {
  final LoginController _loginController = Get.find<LoginController>();

  String? get userEmail => _loginController.loggedInUser.value?.email;
  String? get userRole => _loginController.loggedInUser.value?.role;

  void logout() {
    _loginController.logout();
  }
}
