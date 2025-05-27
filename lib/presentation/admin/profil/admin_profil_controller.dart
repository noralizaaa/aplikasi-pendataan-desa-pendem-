// lib/presentation/admin/profil/admin_profil_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_profil_model.dart';
import '../../../infrastructure/navigation/routes.dart';

class AdminProfilController extends GetxController {
  final Rx<AdminProfilModel?> adminProfile = Rx<AdminProfilModel?>(null);
  final RxBool isLoading = true.obs;
  final RxString currentUserId = ''.obs;

  final RxString displayUsername = 'Admin'.obs;
  final RxString displayRole = 'Admin'.obs;
  final RxString displayPhotoUrl = ''.obs;

  late FirebaseFirestore _db;
  late FirebaseAuth _auth;

  // Controller untuk TextField di dialog edit username
  late TextEditingController usernameEditController;

  @override
  void onInit() {
    super.onInit();
    usernameEditController = TextEditingController();
    _initializeAndFetchProfile();
  }

  @override
  void onClose() {
    usernameEditController.dispose(); // Jangan lupa dispose controller
    super.onClose();
  }

  Future<void> _initializeAndFetchProfile() async {
    isLoading.value = true;
    try {
      _db = FirebaseFirestore.instance;
      _auth = FirebaseAuth.instance;
      User? currentUser = _auth.currentUser;

      if (currentUser != null) {
        currentUserId.value = currentUser.uid;
        await _fetchAdminProfileData(currentUser.uid);
      } else {
        Get.snackbar('Autentikasi Gagal', 'User tidak ditemukan. Silakan login ulang.',
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
        isLoading.value = false;
        return;
      }
    } catch (e) {
      Get.snackbar('Error Inisialisasi', 'Terjadi kesalahan: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      isLoading.value = false;
    }
  }

  Future<void> _fetchAdminProfileData(String userId) async {
    isLoading.value = true;
    try {
      final DocumentSnapshot<Map<String, dynamic>> profileDoc =
      await _db.collection('users').doc(userId).get();

      if (profileDoc.exists && profileDoc.data() != null) {
        adminProfile.value = AdminProfilModel.fromMap(userId, profileDoc.data()!);
        displayUsername.value = adminProfile.value?.username ?? 'Nama Tidak Ada';
        usernameEditController.text = displayUsername.value; // Set nilai awal untuk TextField
        displayRole.value = adminProfile.value?.role ?? 'Peran Tidak Ada';
        displayPhotoUrl.value = adminProfile.value?.photoURL ?? '';
      } else {
        displayUsername.value = 'Admin (Data Kosong)';
        usernameEditController.text = displayUsername.value;
        displayRole.value = 'Admin (Data Kosong)';
        Get.snackbar('Info', 'Data profil tidak ditemukan di database.',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('Error Memuat Profil', 'Terjadi kesalahan: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      displayUsername.value = 'Admin (Error)';
      usernameEditController.text = displayUsername.value;
      displayRole.value = 'Admin (Error)';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshProfile() async {
    if (currentUserId.value.isNotEmpty) {
      // Tidak perlu set isLoading true di sini karena _fetchAdminProfileData sudah melakukannya
      await _fetchAdminProfileData(currentUserId.value);
    } else {
      await _initializeAndFetchProfile();
    }
  }

  //// Menampilkan dialog untuk edit username dengan tampilan modern
  void promptEditUsername() {
    usernameEditController.text = displayUsername.value;

    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFFFFF3E0), // Warna pastel oranye
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          "Edit Username",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: TextField(
          controller: usernameEditController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: "Username Baru",
            hintText: "Masukkan username baru",
            prefixIcon: const Icon(Icons.person_outline),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        actionsPadding: const EdgeInsets.all(12),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              final newUsername = usernameEditController.text.trim();
              if (newUsername.isNotEmpty && newUsername != displayUsername.value) {
                Get.back();
                updateUsername(newUsername);
              } else if (newUsername.isEmpty) {
                Get.snackbar(
                  "Input Error",
                  "Username tidak boleh kosong.",
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.orange.shade700,
                  colorText: Colors.white,
                );
              } else {
                Get.back(); // Tidak ada perubahan
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrangeAccent, // Warna tombol simpan
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }


  /// Mengupdate username di Firestore
  Future<void> updateUsername(String newUsername) async {
    if (currentUserId.value.isEmpty) {
      Get.snackbar("Error", "User tidak teridentifikasi.",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);
      return;
    }

    isLoading.value = true; // Menunjukkan proses update
    try {
      await _db.collection('users').doc(currentUserId.value).update({
        'username': newUsername,
        'displayName': newUsername, // Jika Anda juga menggunakan displayName di AuthUser atau tempat lain
      });
      // Update nilai lokal dan panggil fetch lagi untuk sinkronisasi penuh
      displayUsername.value = newUsername;
      // adminProfile.value = adminProfile.value?.copyWith(username: newUsername); // Jika model punya copyWith
      await _fetchAdminProfileData(currentUserId.value); // Untuk memastikan semua data sinkron
      Get.snackbar("Berhasil", "Username berhasil diperbarui.",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error Update", "Gagal memperbarui username: ${e.toString()}",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.logout, size: 48, color: Color(0xFFF57C00)),
              const SizedBox(height: 16),
              const Text(
                "Konfirmasi Logout",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Apakah Anda yakin ingin keluar dari akun ini?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Tombol Batal
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: Colors.black54,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Colors.grey, width: 1),
                        ),
                      ),
                      child: const Text("Batal"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Tombol Logout
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Get.back();
                        isLoading.value = true;
                        try {
                          await _auth.signOut();
                          adminProfile.value = null;
                          currentUserId.value = '';
                          displayUsername.value = 'Admin'.obs.value;
                          displayRole.value = 'Admin'.obs.value;
                          displayPhotoUrl.value = ''.obs.value;
                          Get.offAllNamed(AppRoutes.login);
                        } catch (e) {
                          Get.snackbar(
                            'Error Logout',
                            'Gagal untuk logout: ${e.toString()}',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                        } finally {
                          isLoading.value = false;
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF57C00),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text("Logout"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

}