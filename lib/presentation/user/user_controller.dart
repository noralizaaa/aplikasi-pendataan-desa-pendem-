// Path: lib/presentation/user/user_controller.dart

import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // For Get.snackbar
import 'package:aplikasi_pendataan_desa/presentation/user/user_model.dart'; // Sesuaikan path ini
import 'package:aplikasi_pendataan_desa/infrastructure/navigation/routes.dart'; // Import AppRoutes

class UserController extends GetxController {
  // Observable untuk menyimpan daftar form data
  final RxList<FormDataModel> formDataList = <FormDataModel>[].obs;
  // Observable untuk loading state saat fetching data
  final RxBool isLoading = true.obs;
  // Observable untuk menyimpan status otoritas pengguna saat ini (dari LoginController)
  final RxBool userHasAuthority = false.obs; // Default false
  // Observable untuk menyimpan nama pengguna
  final RxString userName = ''.obs;
  // Observable untuk menyimpan ID program/otoritas pengguna
  final RxString userProgramId = ''.obs; // NEW: Added userProgramId

  @override
  void onInit() {
    super.onInit();
    // Inisialisasi status otoritas pengguna, nama pengguna, dan program ID
    if (Get.arguments != null && Get.arguments is Map) {
      if (Get.arguments.containsKey('hasAuthority')) {
        userHasAuthority.value = Get.arguments['hasAuthority'];
      }
      userName.value = Get.arguments['userName']?.toString() ?? 'Pengguna';
      userProgramId.value = Get.arguments['programId']?.toString() ?? ''; // Get the programId
    } else {
      // Fallback jika tidak ada argumen (misal, navigasi langsung atau deep link)
      userName.value = 'Pengguna';
      userHasAuthority.value = false;
      userProgramId.value = ''; // Default to empty if no programId is passed
    }

    // Hanya fetch data jika punya otoritas atau jika ingin menampilkan form publik
    if (userHasAuthority.value || userProgramId.value == '000') { // Fetch if has authority or is default '000'
      fetchFormData();
    } else {
      isLoading.value = false; // Hentikan loading jika tidak punya otoritas dan bukan '000'
    }
  }

  // Fungsi untuk mengambil data form dari Firebase Firestore
  Future<void> fetchFormData() async {
    isLoading.value = true;
    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('forms').get();
      final List<FormDataModel> fetchedForms = querySnapshot.docs
          .map((doc) => FormDataModel.fromMap(doc.data()))
          .toList();

      if (userHasAuthority.value) {
        // Jika user punya otoritas penuh, tampilkan semua form
        formDataList.value = fetchedForms;
      } else if (userProgramId.value == '000') {
        // Jika user hanya punya otoritas '000' (tidak ada otoritas khusus),
        // tampilkan form yang TIDAK memerlukan otoritas khusus
        formDataList.value = fetchedForms.where((form) => !form.requiresAuthority).toList();
      } else {
        // Jika user punya ID program tertentu (misal '001', '002'),
        // tampilkan form yang TIDAK memerlukan otoritas khusus ATAU yang cocok dengan ID programnya.
        // Anda mungkin perlu menyesuaikan logika ini berdasarkan bagaimana 'programId'
        // di mapping ke form mana yang bisa diakses.
        formDataList.value = fetchedForms.where((form) {
          // Default: tampilkan form yang tidak memerlukan otoritas khusus
          if (!form.requiresAuthority) return true;
          // Custom logic: if form requires authority, check if its ID matches user's program ID
          return form.idForm == userProgramId.value;
        }).toList();
      }

    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal mengambil data form: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      print('Error fetching form data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Contoh logout (kembali ke LoginScreen)
  void logout() {
    Get.offAllNamed(AppRoutes.login); // Kembali ke LoginScreen dan hapus semua rute sebelumnya
  }
}