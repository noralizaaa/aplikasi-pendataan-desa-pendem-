// lib/presentation/admin/admin_controller.dart

import 'package:get/get.dart';
import 'package:aplikasi_pendataan_desa/presentation/login/login_controller.dart';
import 'package:aplikasi_pendataan_desa/infrastructure/navigation/routes.dart';
import 'package:aplikasi_pendataan_desa/presentation/admin/admin_model.dart';
import 'package:flutter/material.dart';
import 'package:aplikasi_pendataan_desa/domain/auth/models/auth_user.dart'; // Ini penting untuk AuthUser

class AdminController extends GetxController {
  final LoginController _loginController = Get.find<LoginController>();

  // =====================================================================
  // DIAGNOSTIC CODE START: Ini akan menyebabkan error yang JELAS jika salah
  // =====================================================================
  AdminController() {
    try {
      // Akses properti loggedInAuthUser di sini
      var test = _loginController.loggedInAuthUser; // <-- ERROR UTAMA YANG INGIN KITA JELASKAN
      print("AdminController: _loginController.loggedInAuthUser found: ${test != null}");
    } catch (e) {
      print("AdminController: ERROR - _loginController.loggedInAuthUser NOT found during init: $e");
      // Jika Anda ingin menghentikan kompilasi lebih awal, aktifkan ini:
      // throw Exception("Critical: LoginController does not expose loggedInAuthUser");
    }
  }
  // =====================================================================
  // DIAGNOSTIC CODE END
  // =====================================================================

  String? get userEmail => _loginController.loggedInAuthUser.value?.email;
  String get adminName => _loginController.loggedInAuthUser.value?.displayName ?? 'Admin';
  String get adminRole => _loginController.loggedInAuthUser.value?.roleFromFirestore ?? 'Role Tidak Diketahui';
  String? get adminProgramId => _loginController.loggedInAuthUser.value?.programId;

  final RxList<DashboardItem> dashboardItems = <DashboardItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxInt selectedPageIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _loadDashboardItems();
  }

  void _loadDashboardItems() {
    isLoading.value = true;
    dashboardItems.assignAll([
      DashboardItem(title: 'Dashboard Pendataan Penduduk', category: 'Pendataan Penduduk', location: 'Desa Tulung Rejo', programId: '001'),
      DashboardItem(title: 'Dashboard Pendataan TPS3R', category: 'Pendataan TPS3R', location: 'Desa Tulung Rejo', programId: '002'),
      DashboardItem(title: 'Dashboard Pendataan Bank Sampah', category: 'Pendataan TPS3R', location: 'Desa Tulung Rejo', programId: '003'),
      DashboardItem(title: 'Dashboard Pendataan Desa', category: 'Pendataan TPS3R', location: 'Desa Tulung Rejo', programId: '004'),
    ]);
    isLoading.value = false;
  }

  void onPageChanged(int index) {
    selectedPageIndex.value = index;
  }

  void logout() {
    _loginController.logout();
  }
}