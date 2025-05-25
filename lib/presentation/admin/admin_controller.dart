// lib/presentation/admin/admin_controller.dart

import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Untuk Firestore
import 'package:aplikasi_pendataan_desa/presentation/login/login_controller.dart';
// Import FormItem model dari lokasi yang benar
import 'package:aplikasi_pendataan_desa/presentation/admin/formpage/admin_form_model.dart'; // <-- PASTIKAN INI ADA
// Import AuthUser model (sudah ada)
import 'package:aplikasi_pendataan_desa/domain/auth/models/auth_user.dart';
// HAPUS import 'package:aplikasi_pendataan_desa/presentation/admin/admin_model.dart'; // Tidak lagi menggunakan DashboardItem

class AdminController extends GetxController {
  late final LoginController _loginController;

  final RxString adminName = 'Admin'.obs;

  // Menggunakan FormItem untuk dashboard
  final RxList<FormItem> dashboardForms = <FormItem>[].obs; // <-- TIPE DAN NAMA DIUBAH
  // isLoading akan digunakan untuk status loading daftar form di dashboard
  final RxBool isLoading = true.obs; // Default true agar loading tampil saat pertama kali
  final RxInt selectedPageIndex = 0.obs;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Path koleksi tempat form disimpan (HARUS SAMA dengan di AdminFormBuilderController)
  static const String _formsCollectionPath = 'adminForms'; // <-- PASTIKAN INI NAMA KOLEKSI FORM ANDA

  @override
  void onInit() {
    super.onInit();
    _loginController = Get.find<LoginController>();

    ever(_loginController.loggedInAuthUser, (AuthUser? authUser) {
      adminName.value = authUser?.displayName ?? 'Admin';
      // Jika diperlukan, panggil fetchFormsForDashboard() di sini jika dashboard bergantung pada role
      // fetchFormsForDashboard();
    });
    adminName.value = _loginController.loggedInAuthUser.value?.displayName ?? 'Admin';

    fetchFormsForDashboard(); // Memuat daftar form untuk dashboard
  }

  Future<void> fetchFormsForDashboard() async {
    isLoading.value = true;
    try {
      print("DEBUG AdminController: Fetching forms from '$_formsCollectionPath'...");
      final snapshot = await _firestore
          .collection(_formsCollectionPath) // Menggunakan path koleksi form yang benar
          .orderBy('createdAt', descending: true) // Urutkan berdasarkan tanggal terbaru
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Mapping dokumen Firestore ke objek FormItem
        dashboardForms.assignAll(
            snapshot.docs.map((doc) => FormItem.fromFirestore(doc)).toList());
      } else {
        dashboardForms.clear(); // Kosongkan jika tidak ada data
      }
      print("DEBUG AdminController: Fetched ${dashboardForms.length} forms for dashboard.");
    } catch (e) {
      print("Error loading forms for dashboard: $e");
      // Tampilkan Snackbar error di sini jika GetX sudah siap
      // Get.snackbar("Error Dashboard", "Gagal memuat daftar form: ${e.toString()}");
      dashboardForms.clear();
    } finally {
      // Pastikan controller belum di-dispose sebelum mengubah isLoading
      if(!isClosed) {
        isLoading.value = false;
      }
    }
  }

  void onPageChanged(int index) {
    selectedPageIndex.value = index;
  }

  String? get userEmail => _loginController.loggedInAuthUser.value?.email;
  String get adminRole => _loginController.loggedInAuthUser.value?.roleFromFirestore ?? 'Role Tidak Diketahui';
  String? get adminProgramId => _loginController.loggedInAuthUser.value?.programId;

  void logout() {
    _loginController.logout();
  }
}