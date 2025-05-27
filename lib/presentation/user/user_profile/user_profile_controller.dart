// Path: lib/presentation/user_profile/user_profile_controller.dart

import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aplikasi_pendataan_desa/infrastructure/navigation/routes.dart';
import 'package:aplikasi_pendataan_desa/presentation/user/user_profile/user_profile_model.dart'; // Pastikan path ini benar
import 'package:flutter/material.dart'; // For TextEditingController, SnackBar

class UserProfileController extends GetxController {
  final Rx<UserProfile?> userProfile = Rx<UserProfile?>(null);
  final TextEditingController usernameController = TextEditingController();

  // Jadikan _pendataCounter sebagai instance variable, bukan static
  // Ini akan membuat setiap instance controller memiliki counternya sendiri,
  // sehingga jika _generateDefaultUsername dipanggil lagi tanpa argumen,
  // ia akan memulai dari "Pendata 1" untuk instance tersebut,
  // bukan melanjutkan dari counter global.
  int _pendataCounter = 0; // DIUBAH: dihapus static

  @override
  void onInit() {
    super.onInit();
    print("[UserProfileController] onInit called. Arguments: ${Get.arguments}");
    _loadUserProfile();
  }

  @override
  void onClose() {
    print("[UserProfileController] onClose called.");
    usernameController.dispose();
    super.onClose();
  }

  Future<void> _loadUserProfile() async {
    String initialUsername = 'Pengguna';
    String initialRole = 'Peran Tidak Diketahui';
    String? initialProgramId;

    // Coba dapatkan username yang mungkin sudah ada jika controller pernah dimuat sebelumnya
    // Ini adalah strategi jika Get.arguments tidak selalu ada saat navigasi ulang.
    // Namun, karena controller dibuat ulang, cara ini tidak akan efektif tanpa
    // penyimpanan state yang lebih persisten (misalnya di GetxService atau local storage).
    // Untuk sekarang, kita akan fokus pada masalah counter.
    // String? existingUsername = userProfile.value?.username;

    if (Get.arguments != null && Get.arguments is Map && Get.arguments['username'] != null) {
      initialUsername = Get.arguments['username'];
      initialRole = Get.arguments['role'] ?? 'Peran Tidak Diketahui';
      initialProgramId = Get.arguments['programId'] as String?;
      print("[UserProfileController] Loaded from Get.arguments: Username: $initialUsername, Role: $initialRole, ProgramId: $initialProgramId");
    } else {
      // Jika tidak ada argumen username, baru generate default atau coba cara lain
      // Untuk menghentikan looping "Pendata2, Pendata3", perubahan _pendataCounter menjadi non-static akan berpengaruh di sini.
      initialUsername = _generateDefaultUsername();
      // Untuk role dan programId, jika tidak ada di argumen, perlu strategi fallback
      // Mungkin perlu mengambil dari user yang sedang login jika ada state global.
      // Untuk contoh ini, kita biarkan default jika tidak ada di argumen.
      print("[UserProfileController] Get.arguments for username is null or missing. Generated default username: $initialUsername");
    }

    if (initialProgramId != null && initialProgramId.isNotEmpty && initialProgramId != '000') {
      try {
        DocumentSnapshot formDoc = await FirebaseFirestore.instance.collection('forms').doc(initialProgramId).get();
        if (formDoc.exists) {
          final formData = formDoc.data() as Map<String, dynamic>;
          initialRole = formData['nama'] ?? 'Program ID: $initialProgramId';
        } else {
          initialRole = 'Program ID: $initialProgramId (Not Found)';
          final defaultRole = await _fetchDefaultAuthorityRole();
          if (defaultRole != null) initialRole = defaultRole;
          initialProgramId = '000';
        }
      } catch (e) {
        print("Error fetching form for role: $e");
        initialRole = 'Error loading role';
        final defaultRole = await _fetchDefaultAuthorityRole();
        if (defaultRole != null) initialRole = defaultRole;
        initialProgramId = '000';
      }
    } else {
      final defaultRole = await _fetchDefaultAuthorityRole();
      if (defaultRole != null) {
        initialRole = defaultRole;
      }
      initialProgramId = '000';
    }

    userProfile.value = UserProfile(
      username: initialUsername,
      role: initialRole,
      programId: initialProgramId,
    );

    if (userProfile.value != null) {
      usernameController.text = userProfile.value!.username;
    }
    print("[UserProfileController] UserProfile loaded: ${userProfile.value?.username}, Role: ${userProfile.value?.role}");
  }

  String _generateDefaultUsername() {
    _pendataCounter++; // Sekarang ini adalah instance variable
    return 'Pendata $_pendataCounter';
  }

  Future<String?> _fetchDefaultAuthorityRole() async {
    try {
      DocumentSnapshot defaultRoleDoc = await FirebaseFirestore.instance.collection('forms').doc('000').get();
      if (defaultRoleDoc.exists) {
        final data = defaultRoleDoc.data() as Map<String, dynamic>;
        return data['nama'] ?? 'Tidak ada otoritas (Default)';
      } else {
        print("PENTING: Dokumen '000' di collection 'forms' tidak ditemukan. Mohon buat dokumen tersebut di Firestore dengan field 'nama' untuk peran default.");
        return 'Tidak ada otoritas';
      }
    } catch (e) {
      print("Error fetching default authority role from Firestore: $e");
      return 'Tidak ada otoritas (Error)';
    }
  }

  void saveUsername() {
    final newUsername = usernameController.text.trim();
    if (newUsername.isNotEmpty && userProfile.value != null) {
      userProfile.value!.username = newUsername;
      userProfile.refresh();
      Get.snackbar(
        'Sukses',
        'Username berhasil diperbarui!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      // TODO: Simpan newUsername ke backend (misal Firestore)
      // FirebaseFirestore.instance.collection('users').doc(USER_ID_ANDA).update({'username': newUsername});
    } else {
      Get.snackbar(
        'Error',
        'Username tidak boleh kosong!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  void logout() {
    print('User logged out');
    // Pertimbangkan untuk mereset state user global di sini jika ada
    Get.offAllNamed(AppRoutes.login);
  }
}